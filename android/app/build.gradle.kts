import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val requiredReleaseSigningProperties =
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword")

gradle.taskGraph.whenReady {
    val releaseTaskRequested = allTasks.any { task ->
        task.project == project && task.name.contains("Release", ignoreCase = true)
    }
    if (releaseTaskRequested) {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "Release signing configuration is missing: android/key.properties",
            )
        }

        val missingProperties = requiredReleaseSigningProperties.filter { propertyName ->
            keystoreProperties.getProperty(propertyName).isNullOrBlank()
        }
        if (missingProperties.isNotEmpty()) {
            throw GradleException(
                "Release signing configuration is incomplete in android/key.properties: " +
                    missingProperties.joinToString(),
            )
        }
    }
}

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
    namespace = "com.edunova.app"
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
        applicationId = "com.edunova.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("production") {
            dimension = "environment"
            applicationId = "com.edunova.app"
        }
        create("staging") {
            dimension = "environment"
            applicationId = "com.intellia237.app.staging"
            versionNameSuffix = "-staging"
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")
                    ?.takeIf { it.isNotBlank() }
                    ?.let { file("../$it") }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
