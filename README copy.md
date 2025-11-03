# dharak_flutter


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


Here’s a clean and developer-friendly `README.md` for your Flutter project setup, architecture, and instructions:

---

# 🚀 Flutter App

This project is built using a scalable and modular architecture using **Flutter Modular**, **Bloc/Cubit**, and **RxDart** for reactive data handling.

---

## 📐 Architecture Overview

```
 UI <=> Domain (Bloc Cubits + RxDart Repositories) <=> Data ( LOCAL, API)
```

### 🔧 Modular Routing & Dependency
- Uses [`flutter_modular`](https://pub.dev/packages/flutter_modular) for route management and dependency injection.
- Keeps features modular, scalable, and independently testable.

### 🧠 State Management
- Follows **Bloc/Cubit** architecture for predictable state management.
- Separates UI, business logic, and data handling cleanly.

### 🔁 RxDart-based Repository Pattern
- Uses `RxDart` for reactive streams.
- Clean architecture: 
  - **Domain Layer**: Interfaces and entities
  - **Data Layer**: Remote/local data source implementations
  - **Repository Layer**: Bridges domain and data layers

---

## ⚙️ For Development Setup

### 1️⃣ Install Dependencies

```bash
flutter pub get
```

### 2️⃣ Install Slidy (Project Scaffolding Tool)

```bash
flutter pub global activate slidy
```

### 3️⃣ Watch for Code Changes (auto-generate files)

```bash
slidy run watch
```

### 4️⃣ Change Environment

Set the environment to production by updating main.dart:

```dart
F.appFlavor = Flavor.DEVELOPMENT_N;
```

---

## 🚀 Release Build

### 1️⃣ Set Environment

Set the environment to production by updating main.dart:

```dart
F.appFlavor = Flavor.FINALE_RELEASE;
```


### 2️⃣ Build APK / AppBundle

- use android studio menu to build app or bundle


---

## 📁 Folder Structure

```
lib/
├── app/                # Main Modular App
│   ├── core/           # App-wide utilities, constants
│   ├── data/           # Data layer (LOCAL, API, repositories)
│   ├── domain/         # Domain layer (use cases, entities)
│   ├── providers/      # 3rd Party Providers (google signin)
│   ├── ui/             # Pages, sections (modals, sub sections), widgets, models
│   └── types/          # Entity
├── core_module.dart    # import modules (modular + bloc)
├── config/             # Environment configs
├── res/                # Styling and theming 
├── main.dart           # App entry point
```

---

## 📄 Notes

* Code follows **Clean Architecture** principles.
* Prefer reactive patterns with `RxDart` over traditional callbacks.

---

## 🧠 Useful Commands

| Command                        | Purpose                    |
| ------------------------------ | -------------------------- |
| `slidy run watch`              | Auto-generate files        |

---


---

## Some other refrencees

### google sign in
- https://medium.com/codebrew/flutter-google-sign-in-without-firebase-3680713966fb

- https://medium.com/@druhin.bala/google-signin-without-firebase-for-android-on-flutter-e3ee834f696e


### google signin issue 

- https://github.com/flutter/flutter/issues/36673

#### server side

- http://developers.google.com/identity/gsi/web/guides/verify-google-id-token#python

#### web setup

- https://levelup.gitconnected.com/comprehensive-guide-to-integrating-google-sign-in-in-flutter-web-android-and-ios-3dcbf02df8b0


### google service

- https://developers.google.com/android/guides/google-services-plugin#adding_the_json_file



### xml
- https://medium.com/flutter-community/working-with-retrofit-and-xml-on-flutter-62faf9edfa3c


### google play guidelines

- https://support.google.com/googleplay/android-developer/answer/13393723?hl=en#:~:text=Your%20app%20title%20must%20be,mistakenly%20download%20the%20wrong%20app.


### api stream

#### dio
- https://github.com/cfug/dio/issues/1279



purusharthas