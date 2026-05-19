plugins {
    android
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:14.0.0")
}

android {
    namespace = "com.salesforce.samples.salesforceandroididptemplateapp"

    compileSdk = 37

    defaultConfig {
        targetSdk = 37
        minSdk = 28
    }

    buildTypes {
        debug {
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    packaging {
        resources {
            excludes += setOf("META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/DEPENDENCIES", "META-INF/NOTICE")
        }
    }
    buildFeatures {
        buildConfig = true
    }
}
