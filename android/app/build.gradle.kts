import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadPropertiesFile = rootProject.file("key.properties")
val uploadProperties = Properties()
if (uploadPropertiesFile.isFile) {
    uploadPropertiesFile.inputStream().use { uploadProperties.load(it) }
}

// Fail before producing a release with missing/placeholder upload credentials.
// Debug builds retain Android's normal debug signing; release never falls back.
if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }) {
    if (!uploadPropertiesFile.isFile) {
        throw GradleException("TORICO release signing: android/key.properties is missing. Follow docs/android-release-build.md; never commit credentials.")
    }
    for (key in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
        val value = uploadProperties.getProperty(key)
        if (value.isNullOrBlank() || value.startsWith("<")) {
            throw GradleException("TORICO release signing: missing or placeholder property '$key'.")
        }
    }
    if (!rootProject.file(uploadProperties.getProperty("storeFile")).isFile) {
        throw GradleException("TORICO release signing: upload keystore file not found.")
    }
}

android {
    namespace = "br.com.meutorico.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.meutorico.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = uploadProperties.getProperty("keyAlias")
            keyPassword = uploadProperties.getProperty("keyPassword")
            storeFile = uploadProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = uploadProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
