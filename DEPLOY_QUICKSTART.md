# 🚀 Quick Deployment Guide - Dhara to www.bheri.in/dhara

## ⚡ TL;DR - Deploy in 5 Minutes

### **Step 1: Build Flutter App**
```bash
flutter build web --release --base-href /dhara/
```

### **Step 2: Deploy to Vercel**
```bash
cd build/web
vercel --prod
```
**Save the deployment URL** (e.g., `https://dhara-flutter-app.vercel.app`)

### **Step 3: Update React App's vercel.json**

In your **React project**, update `vercel.json`:

```json
{
  "rewrites": [
    {
      "source": "/dhara",
      "destination": "https://your-flutter-url.vercel.app"
    },
    {
      "source": "/dhara/:path*",
      "destination": "https://your-flutter-url.vercel.app/:path*"
    }
  ]
}
```

Replace `https://your-flutter-url.vercel.app` with your URL from Step 2.

### **Step 4: Redeploy React App**
```bash
# In React project directory
vercel --prod
```

### **Step 5: Test**
Visit: https://www.bheri.in/dhara

---

## 🎯 Even Faster: Use the Deploy Script!

### **Windows**:
```cmd
deploy.bat
```

### **Mac/Linux**:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 📋 Pre-Deployment Checklist

Before deploying, make sure:

- [ ] All fixes are working locally:
  - [ ] Tab switching works
  - [ ] Content is centered
  - [ ] Google Sign-In works
  - [ ] Navigation works

- [ ] Vercel CLI installed:
```bash
npm install -g vercel
```

- [ ] Logged into Vercel:
```bash
vercel login
```

---

## 🔧 First-Time Setup

### **1. Install Vercel CLI**
```bash
npm install -g vercel
```

### **2. Login to Vercel**
```bash
vercel login
```

### **3. Test Build Locally**
```bash
flutter build web --release --base-href /dhara/
```

Check `build/web/` folder is created.

---

## 🌐 URLs After Deployment

| URL | What It Is |
|-----|------------|
| `https://www.bheri.in` | Your React app (unchanged) |
| `https://www.bheri.in/dhara` | Your Flutter app (new!) |
| `https://dhara-flutter-app.vercel.app` | Direct Flutter deployment (backup) |

---

## 🔍 Verify Deployment

After deployment, test:

1. **Visit main URL**: https://www.bheri.in/dhara
   - [ ] Page loads
   - [ ] No 404 errors

2. **Test Google Sign-In**:
   - [ ] Click "Sign in with Google"
   - [ ] Login succeeds
   - [ ] Redirects correctly

3. **Test Navigation**:
   - [ ] Click Shodh (शोध) tab
   - [ ] Click Prashna (प्रश्न) tab
   - [ ] Both tabs switch properly

4. **Test Search**:
   - [ ] Enter a search query
   - [ ] Results appear

5. **Test Direct URLs**:
   - [ ] Visit https://www.bheri.in/dhara/prashna
   - [ ] Should load Prashna tab directly

---

## 🛠️ Troubleshooting

### **Issue: 404 when visiting www.bheri.in/dhara**

**Solution**: Check React app's `vercel.json` has correct rewrites.

### **Issue: Assets not loading**

**Solution**: Rebuild with `--base-href /dhara/` flag.

### **Issue: Google Sign-In fails**

**Solution**: Add to Google OAuth Authorized redirect URIs:
- `https://www.bheri.in/dhara`
- `https://www.bheri.in/dhara/`

### **Issue: Tab switching not working**

**Solution**: We already fixed this! Make sure you're deploying the latest code.

---

## 📝 Files You Need

All files are created in your project root:

| File | Purpose |
|------|---------|
| `vercel.json` | Vercel config for Flutter app |
| `REACT_APP_vercel.json` | Example config for React app |
| `deploy.sh` | Auto-deploy script (Mac/Linux) |
| `deploy.bat` | Auto-deploy script (Windows) |
| `DEPLOYMENT_VERCEL_SETUP.md` | Detailed deployment guide |

---

## 🎯 Deployment Flow

```
1. Build Flutter
   ↓
2. Deploy to Vercel (get URL)
   ↓
3. Update React vercel.json with Flutter URL
   ↓
4. Redeploy React app
   ↓
5. ✅ Live at www.bheri.in/dhara!
```

---

## 💡 Tips

### **Tip 1: Keep Flutter URL**
Save your Flutter deployment URL somewhere safe. You'll need it for the React config.

### **Tip 2: Test Separately First**
Test the Flutter deployment URL directly before configuring React.

### **Tip 3: Cache Issues**
If changes don't appear, hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)

### **Tip 4: Environment Variables**
If you have API keys, add them in Vercel Dashboard → Project → Settings → Environment Variables

---

## 🔄 Updating Your App

To deploy updates later:

### **Method 1: Use Deploy Script**
```bash
deploy.bat  # Windows
# or
./deploy.sh  # Mac/Linux
```

### **Method 2: Manual**
```bash
flutter build web --release --base-href /dhara/
cd build/web
vercel --prod
```

---

## 📞 Need Help?

1. **Check logs**: Vercel Dashboard → Your Project → Deployments → Logs
2. **Browser console**: F12 → Console tab
3. **Detailed guide**: See `DEPLOYMENT_VERCEL_SETUP.md`

---

## ✅ Success Checklist

After deployment:

- [ ] www.bheri.in loads (React app)
- [ ] www.bheri.in/dhara loads (Flutter app)
- [ ] Login works
- [ ] Tab switching works
- [ ] Search works
- [ ] Content is centered
- [ ] Works on mobile
- [ ] No console errors

---

## 🎉 Ready to Deploy?

**Run this now:**

### **Windows**:
```cmd
deploy.bat
```

### **Mac/Linux**:
```bash
chmod +x deploy.sh
./deploy.sh
```

Or follow **Step 1-5** at the top of this guide!

---

**Good luck! 🚀**

