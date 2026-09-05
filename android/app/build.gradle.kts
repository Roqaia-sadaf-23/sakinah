import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.isFile) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val uploadKeystore = keystoreProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }

android {
    namespace = "com.roqaiaapps.sakinah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.roqaiaapps.sakinah"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = uploadKeystore
            storePassword = keystoreProperties.getProperty("storePassword")
            storeType = "PKCS12"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Debug builds remain available without secrets. Release must never fall back
// to a debug key or silently produce an unsigned artifact.
val validateUploadSigning = tasks.register("validateUploadSigning") {
    doLast {
        check(keystorePropertiesFile.isFile) {
            "Release signing requires local android/key.properties."
        }
        listOf("storeFile", "storePassword", "keyAlias", "keyPassword").forEach {
            check(!keystoreProperties.getProperty(it).isNullOrBlank()) {
                "Missing release signing property: $it"
            }
        }
        check(uploadKeystore?.isFile == true) {
            "Release upload keystore is missing. Restore the local signing files."
        }
    }
}
tasks.matching {
    it.name == "preReleaseBuild" || it.name == "validateSigningRelease"
}.configureEach {
    dependsOn(validateUploadSigning)
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
