# 🚀 Deploy Flutter App to www.bheri.in/dhara

## 📋 Current Setup
- **React app**: www.bheri.in (already deployed on Vercel)
- **Flutter app**: www.bheri.in/dhara (what we're deploying now)

---

## ✅ **Recommended Approach: Two Separate Vercel Projects**

This keeps React and Flutter builds independent and easier to manage.

---

## 🔧 Step-by-Step Deployment

### **Step 1: Build Flutter for Production**

Run this command in your Flutter project root:

```bash
flutter build web --release --base-href /dhara/
```

**What this does**:
- `--release`: Optimized production build
- `--base-href /dhara/`: Tells Flutter the app will be hosted at /dhara/ path

**Output**: `build/web/` directory with all assets

---

### **Step 2: Deploy Flutter App to Vercel**

#### **Option A: Using Vercel CLI** (Recommended)

1. **Install Vercel CLI** (if not already installed):
```bash
npm install -g vercel
```

2. **Navigate to build directory**:
```bash
cd build/web
```

3. **Deploy to Vercel**:
```bash
vercel --prod
```

4. **Follow prompts**:
   - **Set up and deploy?** → Yes
   - **Which scope?** → Your team/personal account
   - **Link to existing project?** → No (create new)
   - **Project name?** → `dhara-flutter-app` (or any name)
   - **Directory?** → `./` (current directory)
   - **Override settings?** → Yes
   - **Build Command?** → Leave empty (already built)
   - **Output Directory?** → `./` (current directory)
   - **Development Command?** → Leave empty

5. **Note the deployment URL**: 
   - Vercel will give you a URL like: `https://dhara-flutter-app.vercel.app`
   - **Save this URL** - you'll need it for Step 3!

#### **Option B: Using Vercel Web UI**

1. Go to https://vercel.com/dashboard
2. Click **"Add New..."** → **"Project"**
3. **Import Git Repository** or **upload build/web folder**
4. Configure:
   - **Project Name**: `dhara-flutter-app`
   - **Framework Preset**: Other
   - **Root Directory**: `./`
   - **Build Command**: Leave empty
   - **Output Directory**: `./`
5. Click **Deploy**
6. **Note the deployment URL** (e.g., `https://dhara-flutter-app.vercel.app`)

---

### **Step 3: Configure React App to Route /dhara**

Now configure your React app to route all `/dhara/*` requests to your Flutter deployment.

#### **Update React App's `vercel.json`**

In your **React project root**, create or update `vercel.json`:

```json
{
  "rewrites": [
    {
      "source": "/dhara",
      "destination": "https://dhara-flutter-app.vercel.app"
    },
    {
      "source": "/dhara/:path*",
      "destination": "https://dhara-flutter-app.vercel.app/:path*"
    }
  ]
}
```

**Replace `https://dhara-flutter-app.vercel.app`** with your actual Flutter deployment URL from Step 2!

#### **If you have existing rewrites**, merge them:

```json
{
  "rewrites": [
    {
      "source": "/dhara",
      "destination": "https://dhara-flutter-app.vercel.app"
    },
    {
      "source": "/dhara/:path*",
      "destination": "https://dhara-flutter-app.vercel.app/:path*"
    },
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

---

### **Step 4: Redeploy React App**

After updating `vercel.json`, redeploy your React app:

```bash
# In your React project directory
vercel --prod
```

Or use Vercel's Git integration (if connected to GitHub):
- Just push your changes
- Vercel will auto-deploy

---

### **Step 5: Verify Deployment**

1. **Visit**: https://www.bheri.in/dhara
2. **Test**:
   - ✅ Flutter app loads
   - ✅ Login with Google works
   - ✅ Tab switching works
   - ✅ Search works
   - ✅ Routes like `/dhara/prashna` work

---

## 📁 Flutter Project Structure

Your Flutter app should have this in `web/index.html`:

```html
<base href="/dhara/">
```

This is automatically set by the `--base-href` flag during build.

---

## 🔄 **Alternative: Single Vercel Project** (Not Recommended)

If you want both React and Flutter in one project (more complex):

### **Directory Structure**:
```
project/
├── build/web/          # Flutter build output
├── react-app/          # Your React app
├── vercel.json
```

### **vercel.json**:
```json
{
  "routes": [
    {
      "src": "/dhara/(.*)",
      "dest": "/build/web/$1"
    },
    {
      "src": "/(.*)",
      "dest": "/react-app/$1"
    }
  ]
}
```

**Why not recommended**: 
- Harder to manage separate build processes
- Larger deployment size
- More complex CI/CD

---

## 🛠️ Continuous Deployment Setup

### **For Flutter App** (Auto-deploy on Git push):

1. **Create a new Git repository** for just the Flutter app
2. **Connect to Vercel**:
   - Go to Vercel Dashboard
   - Click "Add New" → "Project"
   - Import your Flutter repo
3. **Configure Build Settings**:
   - **Build Command**: `flutter build web --release --base-href /dhara/`
   - **Output Directory**: `build/web`
   - **Install Command**: `flutter pub get`
4. **Environment Variables** (if needed):
   - Add any API keys or config

Now every push to main will auto-deploy!

---

## 📝 Quick Deployment Script

Create `deploy.sh` in your Flutter project:

```bash
#!/bin/bash

echo "🔨 Building Flutter web app..."
flutter build web --release --base-href /dhara/

echo "📦 Deploying to Vercel..."
cd build/web
vercel --prod

echo "✅ Deployment complete!"
echo "🌐 Visit: https://www.bheri.in/dhara"
```

Make it executable:
```bash
chmod +x deploy.sh
```

Run it:
```bash
./deploy.sh
```

---

## 🔧 Troubleshooting

### **Issue 1: 404 on refresh**

**Problem**: Navigating to `/dhara/prashna` directly gives 404

**Solution**: Add to Flutter's `web/index.html` before `</head>`:
```html
<script>
  // Handle 404s by redirecting to root
  (function() {
    var path = window.location.pathname;
    if (path && path !== '/dhara/') {
      sessionStorage.setItem('redirectPath', path);
    }
  })();
</script>
```

And after Flutter loads:
```html
<script>
  window.addEventListener('flutter-first-frame', function() {
    var redirectPath = sessionStorage.getItem('redirectPath');
    if (redirectPath) {
      sessionStorage.removeItem('redirectPath');
      window.history.replaceState(null, '', redirectPath);
    }
  });
</script>
```

### **Issue 2: Assets not loading**

**Problem**: Images, fonts not loading

**Solution**: 
- Verify `--base-href /dhara/` was used in build
- Check browser console for 404s
- Ensure all asset paths are relative (no leading `/`)

### **Issue 3: Google Sign-In redirect issues**

**Problem**: After Google login, redirects to wrong URL

**Solution**: Update Google OAuth Authorized redirect URIs:
- Add: `https://www.bheri.in/dhara`
- Add: `https://www.bheri.in/dhara/`

---

## ✅ Final Checklist

Before going live:

- [ ] Flutter app builds without errors
- [ ] `--base-href /dhara/` used in build
- [ ] Flutter deployed to Vercel (note URL)
- [ ] React app's `vercel.json` updated with Flutter URL
- [ ] React app redeployed
- [ ] Test: https://www.bheri.in/dhara loads
- [ ] Test: Google Sign-In works
- [ ] Test: Navigation works
- [ ] Test: Direct URLs like `/dhara/prashna` work
- [ ] Test: Assets (images, fonts) load
- [ ] Test: On mobile devices
- [ ] Google OAuth redirect URIs updated

---

## 🎯 Summary

**What we're doing**:
1. Build Flutter with `--base-href /dhara/`
2. Deploy Flutter as separate Vercel project
3. Configure React app to rewrite `/dhara/*` to Flutter project
4. Redeploy React app with new config

**Result**: 
- ✅ www.bheri.in → React app
- ✅ www.bheri.in/dhara → Flutter app
- ✅ Both work seamlessly!

---

## 📞 Need Help?

If you encounter issues:
1. Check Vercel deployment logs
2. Check browser console for errors
3. Verify `vercel.json` syntax
4. Test Flutter deployment URL directly first

---

**Ready to deploy? Start with Step 1!** 🚀

