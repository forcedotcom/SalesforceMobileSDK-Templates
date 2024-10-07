@file:Suppress("UnstableApiUsage")

plugins {
    android
    `kotlin-android`
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:12.2.0")
    // Comment when disabling log in via Salesforce UI Bridge API generated QR codes
    implementation("com.google.zxing:core:3.4.1")
    // Comment when disabling log in via Salesforce UI Bridge API generated QR codes
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")
}

android {
    namespace = "com.salesforce.androidnativekotlintemplate"

    compileSdk = 35

    defaultConfig {
        targetSdk = 35
        minSdk = 26
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
    }
}

repositories {
    google()
    mavenCentral()
}

kotlin {
    jvmToolchain(17)
}
