@file:Suppress("UnstableApiUsage")

plugins {
    android
    `kotlin-android`
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:12.0.0")
}

android {
    namespace = "com.salesforce.androidnativekotlintemplate"

    compileSdk = 34

    defaultConfig {
        minSdk = 24
        targetSdk = 34
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
    }
}

repositories {
    google()
    mavenCentral()
}

kotlin {
    jvmToolchain(17)
}
