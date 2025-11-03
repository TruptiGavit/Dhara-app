# 🚀 Quick Start Guide - Dhara Web Development

## TL;DR - Start Coding NOW

```bash
# Run locally with backend
flutter run -d chrome --web-port=5000

# Or use web server mode
flutter run -d web-server --web-port=5000
```

That's it! Your app will connect to the live backend at `https://project.iith.ac.in/bheri/api/`

---

## ✅ What's Already Fixed

1. ✅ **Google Sign-In on Web** - Now sends access tokens (not ID tokens)
2. ✅ **Web Client ID** - Already configured in code
3. ✅ **Backend Integration** - Points to live API
4. ✅ **Loading Screen** - Added professional loading indicator
5. ✅ **OpenID Scope Added** - Requesting ID tokens when possible

## ⚠️ **IMPORTANT: Backend Update Required**

**Issue**: Backend currently returns `{"error": "Invalid token"}`

**Why**: The backend needs to validate Google OAuth access tokens by calling Google's API.

**Solution**: Share **[BACKEND_INTEGRATION_GUIDE.md](BACKEND_INTEGRATION_GUIDE.md)** with your backend team.

They need to add this validation:
```python
response = requests.get(
    'https://www.googleapis.com/oauth2/v3/tokeninfo',
    params={'access_token': access_token}
)
```

**Status**: Frontend is ready ✅ | Backend needs update ⚠️

---

## 🎯 Development Workflow

### Start Development
```bash
# Option 1: Chrome with DevTools (Recommended for debugging)
flutter run -d chrome --web-port=5000

# Option 2: Web server (Better performance, less debugging)
flutter run -d web-server --web-port=5000

# Option 3: Build and test production version
flutter build web --release
cd build/web
python -m http.server 5000
```

### Test Google Login
1. Click Google Sign-In button
2. Select your Google account
3. App gets access token from Google
4. Sends access token to backend
5. Backend validates and returns JWT tokens
6. ✅ You're logged in!

**Note**: Your local app talks to the LIVE backend - no local backend setup needed!

---

## 📦 Building for Deployment

### For bheri.in/dhara deployment
```bash
flutter build web --release --base-href /dhara/
```

### For testing on root domain (localhost)
```bash
flutter build web --release
```

### For other subdirectories
```bash
flutter build web --release --base-href /your-path/
```

---

## 🔧 Common Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release

# Run with specific device
flutter run -d chrome
flutter run -d edge
flutter run -d web-server

# Check available devices
flutter devices

# Hot reload (in debug mode)
# Just save your Dart files - hot reload happens automatically!
```

---

## 🐛 Troubleshooting

### Issue: "No devices available"
```bash
flutter config --enable-web
flutter doctor
```

### Issue: Google Sign-In popup blocked
- Allow popups in browser settings
- Or use the account picker flow (already implemented)

### Issue: "CORS error" in console
- Check that `https://project.iith.ac.in` CORS allows your localhost
- Contact backend team to add `http://localhost:5000` to CORS origins

### Issue: "Invalid token" error
✅ **Already fixed!** The code now properly sends access tokens on web.

### Issue: Page loads but shows blank screen
1. Open browser DevTools (F12)
2. Check Console for errors
3. Check Network tab for failed requests
4. Verify base href in `web/index.html`

---

## 🌐 Testing on Different Browsers

```bash
# Chrome (default)
flutter run -d chrome

# Edge (on Windows)
flutter run -d edge

# Web server (works in any browser)
flutter run -d web-server --web-port=5000
# Then open http://localhost:5000 in any browser
```

---

## 📱 Responsive Testing

Open DevTools in browser (F12) and toggle device toolbar to test:
- Mobile (320px - 480px)
- Tablet (768px - 1024px)
- Desktop (1200px+)

---

## 🚀 Deploying to Production

### Option 1: Vercel (Easiest)

```bash
# Build for production
flutter build web --release --base-href /dhara/

# Deploy (from build/web directory)
cd build/web
vercel --prod
```

You'll get a URL like: `https://dhara-flutter.vercel.app`

### Option 2: Connect to bheri.in

After deploying to Vercel, update your React project's `vercel.json`:

```json
{
  "rewrites": [
    {
      "source": "/dhara/:path*",
      "destination": "https://dhara-flutter.vercel.app/:path*"
    }
  ]
}
```

Redeploy React project, and your Flutter app will be available at `bheri.in/dhara`!

---

## 📊 Performance Tips

### 1. Use release mode for testing performance
```bash
flutter run -d chrome --release
```

### 2. Optimize build
```bash
# Use CanvasKit for better rendering (slightly larger bundle)
flutter build web --release --web-renderer canvaskit

# Or use HTML renderer for smaller bundle
flutter build web --release --web-renderer html

# Auto mode (Flutter decides based on device)
flutter build web --release --web-renderer auto
```

### 3. Profile app performance
```bash
flutter run -d chrome --profile
# Then open DevTools for profiling
```

---

## 🔑 Environment Variables (Future)

If you need different backends for dev/staging/prod:

1. Create environment config:
   ```dart
   // lib/config/environment.dart
   class Environment {
     static const String apiBaseUrl = String.fromEnvironment(
       'API_URL',
       defaultValue: 'https://project.iith.ac.in/bheri/api/',
     );
   }
   ```

2. Build with environment:
   ```bash
   flutter build web --release --dart-define=API_URL=https://staging.api.com
   ```

---

## 📋 Pre-Deployment Checklist

Before deploying to production:

- [ ] Test Google login flow
- [ ] Test on Chrome, Firefox, Safari, Edge
- [ ] Test on mobile browser
- [ ] Check all API calls work
- [ ] Verify loading states
- [ ] Test error handling
- [ ] Check browser console for errors
- [ ] Test with slow network (DevTools Network throttling)
- [ ] Verify all fonts load correctly
- [ ] Check responsive design on different screen sizes

---

## 🎨 Customization

### Update App Title
Edit `web/index.html` line 32:
```html
<title>Dhara - Sanskrit Learning Platform</title>
```

### Update App Icon
Replace files in `web/icons/` directory

### Update Manifest
Edit `web/manifest.json` for PWA configuration

---

## 🆘 Getting Help

1. **Browser Console** (F12) - First place to check for errors
2. **Flutter DevTools** - `flutter pub global activate devtools && flutter pub global run devtools`
3. **Backend Logs** - Check with your backend team
4. **Network Tab** - Inspect API requests/responses

---

## 🎯 Your Next Steps

1. ✅ Everything is already configured!
2. Run: `flutter run -d chrome --web-port=5000`
3. Click Google Sign-In
4. Start developing!

When ready to deploy:
1. Build: `flutter build web --release --base-href /dhara/`
2. Deploy: `cd build/web && vercel --prod`
3. Configure routing in React app
4. 🎉 Done!

---

## 💡 Pro Tips

1. **Hot Reload**: Just save your Dart files - changes appear instantly in debug mode
2. **DevTools**: Press `p` in terminal to see performance overlay
3. **Restart**: Press `r` in terminal to hot restart app
4. **Quit**: Press `q` in terminal to quit
5. **Clear Cache**: Press `shift + reload` in browser to clear cache

---

## Summary

**To start working RIGHT NOW:**
```bash
flutter run -d chrome --web-port=5000
```

**To deploy when ready:**
```bash
flutter build web --release --base-href /dhara/
cd build/web
vercel --prod
```

**Current status:**
- ✅ Google OAuth configured
- ✅ Backend integration ready  
- ✅ Access token fix applied
- ✅ Loading screen added
- ✅ Ready for development!

Happy coding! 🚀

