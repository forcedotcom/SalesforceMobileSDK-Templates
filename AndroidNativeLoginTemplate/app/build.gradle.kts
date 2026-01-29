plugins {
    android
    `kotlin-android`
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.1.1")
    implementation("com.google.android.material:material:1.12.0")

    val composeBom = platform("androidx.compose:compose-bom:2024.02.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-ktx:1.10.1")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")

    // Android Studio Preview support
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("com.google.android.recaptcha:recaptcha:18.6.1") // Update requires Kotlin 2.
}

android {
    namespace = "com.salesforce.androidnativelogintemplate"

    compileSdk = 36

    defaultConfig {
        targetSdk = 36
        minSdk = 28
    }

    buildTypes {
        debug {
            enableAndroidTestCoverage = true
        }
    }

    packaging {
        resources {
            excludes += setOf("META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/DEPENDENCIES", "META-INF/NOTICE")
        }
    }

    buildFeatures {
        renderScript = true
        aidl = true
        buildConfig = true
        compose = true
    }

    @Suppress("UnstableApiUsage")
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.9"
    }
}

repositories {
    google()
    mavenCentral()
}

kotlin {
    jvmToolchain(17)
}
