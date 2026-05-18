plugins {
    android
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:14.0.0")
    implementation("androidx.compose.runtime:runtime-android:1.11.1")
    // Comment when disabling log in via Salesforce UI Bridge API generated QR codes
    implementation("com.google.zxing:core:3.5.4")
    // Comment when disabling log in via Salesforce UI Bridge API generated QR codes
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")
}

android {
    namespace = "com.salesforce.androidnativekotlintemplate"

    compileSdk = 37

    defaultConfig {
        targetSdk = 37
        minSdk = 28
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/DEPENDENCIES",
                "META-INF/NOTICE"
            )
        }
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
