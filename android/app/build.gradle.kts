plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.myapp"
    compileSdk = 34 // Defina a versão desejada do SDK

    ndkVersion = "27.0.12077973" // Ou outra versão do NDK compatível

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 23 // Atualize conforme necessário
        targetSdk = 34 // Altere para a versão desejada do SDK
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // TODO: Adicionar configuração de assinatura para a versão de lançamento.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
