# Dhara Flutter Web Deployment Guide

## Overview
This guide covers deploying the Dhara Flutter app on web alongside your existing React app at bheri.in.

---

## 🎯 Architecture: React + Flutter on Same Domain

### Strategy
```
bheri.in           → React app (existing)
bheri.in/dhara     → Flutter web app (new)
```

### Why This Works
✅ Both apps can coexist on the same domain  
✅ No need to rebuild React app in Flutter  
✅ Each technology serves its purpose  
✅ Shared backend API  
✅ Easier maintenance  

---

## 📋 Prerequisites

### 1. Google OAuth Configuration
You need a **Web Client ID** from Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one)
3. Navigate to **APIs & Services** → **Credentials**
4. Create **OAuth 2.0 Client ID** for **Web application**
5. Add authorized JavaScript origins:
   ```
   http://localhost:5000
   https://bheri.in
   ```
6. Add authorized redirect URIs:
   ```
   http://localhost:5000
   https://bheri.in
   https://bheri.in/dhara
   ```
7. Copy the **Client ID** (format: `xxxxx.apps.googleusercontent.com`)

### 2. Update Flutter Code with Web Client ID

**File:** `lib/app/providers/google/google_auth.dart` (Line 28)

Replace:
```dart
clientId: kIsWeb 
  ? "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"  // Replace with your web client ID
  : null,
```

With your actual Client ID:
```dart
clientId: kIsWeb 
  ? "123456789-abcdefg.apps.googleusercontent.com"  // Your actual web client ID
  : null,
```

---

## 🚀 Deployment Options

### **Option 1: Separate Vercel Projects (Recommended)**

#### Step 1: Build Flutter Web
```bash
flutter build web --release --base-href /dhara/
```

#### Step 2: Deploy Flutter App to Vercel
```bash
cd build/web
vercel --prod
```
This will give you a URL like: `https://dhara-flutter.vercel.app`

#### Step 3: Configure React Project Routing
In your React project root, create/update `vercel.json`:

```json
{
  "rewrites": [
    {
      "source": "/dhara/:path*",
      "destination": "https://dhara-flutter.vercel.app/:path*"
    },
    {
      "source": "/:path*",
      "destination": "/:path*"
    }
  ],
  "headers": [
    {
      "source": "/dhara/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=0, must-revalidate"
        }
      ]
    }
  ]
}
```

#### Step 4: Redeploy React Project
```bash
vercel --prod
```

### **Option 2: Monorepo with Multiple Apps**

Structure:
```
bheri-monorepo/
├── react-app/       # Your existing React site
├── flutter-app/     # Dhara Flutter web build
└── vercel.json      # Routing configuration
```

`vercel.json`:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "react-app/package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "react-app/build"
      }
    },
    {
      "src": "flutter-app/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/dhara/(.*)",
      "dest": "/flutter-app/$1"
    },
    {
      "src": "/(.*)",
      "dest": "/react-app/$1"
    }
  ]
}
```

### **Option 3: Nginx Reverse Proxy (Self-hosted)**

If you're self-hosting:

```nginx
server {
    listen 80;
    server_name bheri.in;

    # React app
    location / {
        root /var/www/bheri-react/build;
        try_files $uri $uri/ /index.html;
    }

    # Flutter app
    location /dhara {
        alias /var/www/dhara-flutter/build/web;
        try_files $uri $uri/ /dhara/index.html;
    }
}
```

---

## 🛠️ Development Workflow

### Running Locally with Backend

Your backend is already deployed at `https://project.iith.ac.in/bheri/api/`, so you can develop locally:

#### Option A: Chrome (with debugging)
```bash
flutter run -d chrome --web-port=5000
```

#### Option B: Web Server (production-like)
```bash
flutter run -d web-server --web-port=5000
```

#### Option C: Build and Serve
```bash
# Build
flutter build web --release

# Serve (using Python)
cd build/web
python -m http.server 5000

# Or using Node.js
npx http-server . -p 5000
```

### Testing Google Sign-In Locally

1. **Add localhost to Google OAuth**:
   - Authorized JavaScript origins: `http://localhost:5000`
   - Authorized redirect URIs: `http://localhost:5000`

2. **Run the app**:
   ```bash
   flutter run -d chrome --web-port=5000
   ```

3. **Test login** - it will call your live backend API

---

## ⚙️ Flutter Web Build Configuration

### Update `web/index.html`

Ensure base href is set correctly:

```html
<!DOCTYPE html>
<html>
<head>
  <base href="/dhara/">
  <!-- Rest of your head content -->
</head>
<body>
  <!-- Body content -->
</body>
</html>
```

### Update `pubspec.yaml`

Verify dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_sign_in: ^6.2.1
  google_sign_in_web: ^0.12.3+3
  # ... other dependencies
```

---

## 🔒 Backend Configuration

### CORS Settings
Ensure your Django backend allows:
```python
CORS_ALLOWED_ORIGINS = [
    "https://bheri.in",
    "https://www.bheri.in",
    "http://localhost:5000",  # For development
]

CSRF_TRUSTED_ORIGINS = [
    "https://bheri.in",
    "https://www.bheri.in",
]
```

### Google OAuth Backend
Your backend endpoint `/bheri/api/google_login/` expects:
```json
{
  "access_token": "ya29.a0AfH6SMD..."
}
```

✅ **Fixed in code**: The Flutter app now properly sends the access token (not ID token) on web.

---

## 🐛 Troubleshooting

### Issue: "Invalid token" error

**Cause**: Google Sign-In on web returns access tokens, not ID tokens.

**Solution**: ✅ Already fixed in `google_auth.dart` - the code now sends access tokens on web.

### Issue: Blank page after deployment

**Check**:
1. Base href is set correctly: `/dhara/`
2. All assets have correct paths
3. Browser console for errors

**Fix**:
```bash
flutter build web --release --base-href /dhara/
```

### Issue: Google Sign-In not working

**Check**:
1. Web Client ID is correctly set in code
2. Domain is whitelisted in Google Cloud Console
3. Authorized origins include your deployment URL

### Issue: API calls failing (CORS)

**Check**:
1. Backend CORS settings include your frontend domain
2. CSRF token settings if using Django

---

## 📊 Performance Optimization

### 1. Enable CanvasKit for better rendering
```bash
flutter build web --release --web-renderer canvaskit --base-href /dhara/
```

### 2. Split and compress assets
Add to `web/index.html`:
```html
<script>
  // Defer loading of deferred parts
  window.addEventListener('flutter-first-frame', function () {
    // App is now interactive
  });
</script>
```

### 3. Add loading indicator
Update `web/index.html`:
```html
<body>
  <div id="loading">
    <style>
      #loading {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }
    </style>
    <div>Loading Dhara...</div>
  </div>
  <script src="flutter.js" defer></script>
  <script>
    window.addEventListener('flutter-first-frame', function () {
      document.getElementById('loading').remove();
    });
  </script>
</body>
```

---

## ✅ Deployment Checklist

- [ ] Google Web Client ID configured in `google_auth.dart`
- [ ] Authorized origins added in Google Cloud Console
- [ ] Backend CORS settings updated
- [ ] Flutter web built with correct base-href
- [ ] Routing configured in Vercel/Nginx
- [ ] Tested login flow on staging
- [ ] Tested on different browsers
- [ ] Performance optimization applied
- [ ] Analytics/monitoring configured

---

## 🔄 Continuous Deployment

### GitHub Actions Example

`.github/workflows/deploy-flutter-web.yml`:
```yaml
name: Deploy Flutter Web

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build web
      run: flutter build web --release --base-href /dhara/
    
    - name: Deploy to Vercel
      uses: amondnet/vercel-action@v25
      with:
        vercel-token: ${{ secrets.VERCEL_TOKEN }}
        vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
        vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
        working-directory: ./build/web
```

---

## 📞 Support

If you encounter issues:
1. Check browser console for errors
2. Verify network tab for API calls
3. Check backend logs for authentication errors
4. Ensure all environment variables are set

---

## Summary

**Recommended Approach:**
1. ✅ Keep React and Flutter separate
2. ✅ Deploy Flutter web to separate Vercel project
3. ✅ Route `/dhara/*` traffic via React project's `vercel.json`
4. ✅ Use deployed backend for local development
5. ✅ Access token (not ID token) is sent to backend on web

**Development:**
- Run `flutter run -d chrome --web-port=5000`
- Backend is already live - no local backend needed
- Google Sign-In works with localhost if configured

**Production:**
- Deploy Flutter app separately
- Configure routing in main React app
- Both apps work together on same domain







