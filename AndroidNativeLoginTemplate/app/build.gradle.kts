plugins {
    android
    `kotlin-android`
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21"
}

dependencies {
    val composeVersion = "1.8.2"

    implementation("com.salesforce.mobilesdk:MobileSync:13.1.0")
    implementation("com.google.android.material:material:1.12.0")

    implementation("androidx.activity:activity-ktx:1.10.1")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("com.google.android.recaptcha:recaptcha:18.7.1")

    // Note: Compose dependencies are synchronized with the content in the Compose set up guide for easier migration to new versions.
    val composeBom = platform("androidx.compose:compose-bom:2025.05.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.compose.material3:material3:1.3.2")

    implementation("androidx.compose.ui:ui-tooling-preview:$composeVersion")
    debugImplementation("androidx.compose.ui:ui-tooling:$composeVersion")

    androidTestImplementation("androidx.compose.ui:ui-test-junit4:$composeVersion")
    debugImplementation("androidx.compose.ui:ui-test-manifest:$composeVersion")

    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.1")
    implementation("androidx.compose.runtime:runtime-livedata:$composeVersion")
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
}

repositories {
    google()
    mavenCentral()
}

kotlin {
    jvmToolchain(17)
}
