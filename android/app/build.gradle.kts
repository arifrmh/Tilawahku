plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tilawahku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tilawahku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    val isSplitPerAbi = project.findProperty("split-per-abi")?.toString() == "true"

    buildTypes {
        debug {
            // x86_64 disertakan di debug agar dapat berjalan pada emulator x86_64.
            if (!isSplitPerAbi) {
                ndk {
                    abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
                }
            }
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // sherpa_onnx mengirim paket ffiPlugin per ABI (total 109,1 MB .so), jadi
            // tanpa filter semua library ASR masuk APK. Saat --split-per-abi dipakai,
            // AGP melarang ndk.abiFilters bersamaan dengan splits.abi.
            if (!isSplitPerAbi) {
                ndk {
                    abiFilters += listOf("arm64-v8a", "armeabi-v7a")
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Desugaring dibutuhkan flutter_local_notifications untuk menjadwalkan
// pengingat waktu salat pada Android lama (lihat README plugin v22).
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
