import java.util.Properties
import java.io.File

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val file = File(rootProject.projectDir.parent, "local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

// Read the properties from local.properties
val ndkVersion = localProperties.getProperty("flutter.ndkVersion") ?: flutter.ndkVersion

val keystoreProperties=Properties().apply{
    val file=File(rootProject.projectDir,"key.properties")
    if(file.exists()){
        file.inputStream().use{load(it)}
    }
}


android {
    namespace = "in.bheri.dhara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "in.bheri.dhara"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 25
        versionName = "2.0.0"
        
        // versionCode = flutter.versionCode
        // versionName = flutter.versionName
        
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so flutter run --release works.

            //signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
            
            // APK size optimizations - temporarily disabled until proper rules are configured
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}