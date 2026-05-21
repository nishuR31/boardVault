import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadEnvFiles(): Map<String, String> {
    val candidates = listOf(
        rootProject.file("../.env"),
        rootProject.file(".env"),
    )

    val envFile = candidates.firstOrNull { it.exists() } ?: return emptyMap()
    return envFile.readLines()
        .mapNotNull { line ->
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                return@mapNotNull null
            }

            val separatorIndex = trimmed.indexOf('=')
            if (separatorIndex <= 0) {
                return@mapNotNull null
            }

            val key = trimmed.substring(0, separatorIndex).trim()
            val value = trimmed.substring(separatorIndex + 1).trim().removeSurrounding("\"")
            key to value
        }
        .toMap()
}

val signingEnv = loadEnvFiles()

// Load optional key.properties (created by Android tooling or manually)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.boardvault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.boardvault"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // debuggable = false
            // Prefer properties from android/key.properties when present,
            // otherwise fall back to environment-style keys read from .env
            val keystoreFileName = keystoreProperties.getProperty("storeFile")
                ?: signingEnv["KEYSTORE_FILE"]
            val keystorePassword = keystoreProperties.getProperty("storePassword")
                ?: signingEnv["KEYSTORE_PASSWORD"]
            val keyAlias = keystoreProperties.getProperty("keyAlias") ?: signingEnv["KEY_ALIAS"]
            val keyPassword = keystoreProperties.getProperty("keyPassword")
                ?: signingEnv["KEY_PASSWORD"]

            if (
                keystoreFileName != null &&
                keystorePassword != null &&
                keyAlias != null &&
                keyPassword != null
            ) {
                signingConfig = signingConfigs.create("release") {
                    val keystorePath = File(
                        rootProject.file("..").canonicalFile,
                        keystoreFileName,
                    )

                    storeFile = keystorePath
                    storePassword = keystorePassword
                    this.keyAlias = keyAlias
                    this.keyPassword = keyPassword
                }
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
