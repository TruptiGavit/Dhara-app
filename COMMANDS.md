# 📝 Command Reference - Dhara Web

Quick reference for common commands.

---

## 🚀 Development

### Start Development Server
```bash
# Windows
run_web_dev.bat

# Mac/Linux
./run_web_dev.sh

# Manual
flutter run -d chrome --web-port=5000
```

### Hot Reload/Restart
```
r  - Hot reload (instant)
R  - Hot restart (full restart)
q  - Quit
p  - Performance overlay
```

---

## 🏗️ Building

### Production Build
```bash
# Windows
build_for_deployment.bat

# Mac/Linux
./build_for_deployment.sh

# Manual
flutter build web --release --base-href /dhara/
```

### Other Build Options
```bash
# Root domain (for testing)
flutter build web --release

# Different renderer
flutter build web --release --web-renderer canvaskit  # Better quality, larger size
flutter build web --release --web-renderer html       # Smaller size, basic quality

# Debug build (for testing)
flutter build web --debug
```

---

## 🧹 Maintenance

### Clean Build
```bash
flutter clean
flutter pub get
```

### Update Dependencies
```bash
flutter pub upgrade
```

### Check for Issues
```bash
flutter doctor
flutter doctor -v
```

---

## 🌐 Local Testing

### Serve Built Files
```bash
# Python
cd build/web
python -m http.server 5000

# Node.js
cd build/web
npx http-server . -p 5000

# PHP
cd build/web
php -S localhost:5000
```

Then open: `http://localhost:5000`

---

## 🚀 Deployment

### Deploy to Vercel
```bash
# From build/web directory
cd build/web
vercel --prod

# Or with Vercel CLI options
vercel --prod --name dhara-flutter
```

### Deploy to Netlify
```bash
# From project root
netlify deploy --prod --dir=build/web
```

### Deploy to Firebase
```bash
firebase deploy --only hosting
```

---

## 🧪 Testing

### Run on Different Browsers
```bash
# Chrome (default)
flutter run -d chrome

# Edge
flutter run -d edge

# Web server (any browser)
flutter run -d web-server --web-port=5000
```

### List Available Devices
```bash
flutter devices
```

### Enable Web Support
```bash
flutter config --enable-web
```

---

## 🐛 Debugging

### Verbose Output
```bash
flutter run -d chrome --verbose
```

### Profile Mode
```bash
flutter run -d chrome --profile
```

### DevTools
```bash
# Install
flutter pub global activate devtools

# Run
flutter pub global run devtools
```

---

## 📦 Dependencies

### Add Dependency
```bash
flutter pub add package_name
```

### Remove Dependency
```bash
flutter pub remove package_name
```

### Get Dependencies
```bash
flutter pub get
```

### Show Outdated
```bash
flutter pub outdated
```

---

## 🔧 Configuration

### Check Web Config
```bash
flutter config
```

### Enable/Disable Web
```bash
flutter config --enable-web
flutter config --no-enable-web
```

---

## 📊 Analysis

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
flutter format .
```

### Run Tests
```bash
flutter test
```

---

## 🎯 Quick Workflows

### Fresh Start
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### Build and Test Locally
```bash
flutter build web --release
cd build/web
python -m http.server 5000
```

### Deploy Workflow
```bash
flutter clean
flutter pub get
flutter build web --release --base-href /dhara/
cd build/web
vercel --prod
```

---

## 🔑 Environment Variables (Optional)

### Build with Variables
```bash
flutter build web --release --dart-define=API_URL=https://api.example.com
```

### Multiple Variables
```bash
flutter build web --release \
  --dart-define=API_URL=https://api.example.com \
  --dart-define=ENV=production
```

---

## 📱 Mobile Commands (Bonus)

### Android
```bash
flutter run -d android
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter run -d ios
flutter build ios --release
```

---

## 💡 Pro Tips

### Clear Cache
```bash
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
```

### Check Performance
```bash
# While app is running, press 'p' in terminal
# Or add to code:
import 'package:flutter/rendering.dart';
debugPaintSizeEnabled = true;
```

### Hot Reload Not Working?
```bash
# Press 'R' for full restart
# Or restart the dev server
```

---

## 🆘 When Things Go Wrong

### "No devices found"
```bash
flutter config --enable-web
flutter doctor
```

### "Failed to build"
```bash
flutter clean
flutter pub get
flutter run -d chrome --verbose
```

### "Port already in use"
```bash
# Use different port
flutter run -d chrome --web-port=5001

# Or kill process using port 5000
# Windows:
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Mac/Linux:
lsof -ti:5000 | xargs kill -9
```

---

## Summary

**Most Used Commands:**

```bash
# Development
flutter run -d chrome --web-port=5000

# Production Build
flutter build web --release --base-href /dhara/

# Deploy
cd build/web && vercel --prod

# Clean & Rebuild
flutter clean && flutter pub get && flutter run -d chrome
```

**That's all you need! 🎯**





