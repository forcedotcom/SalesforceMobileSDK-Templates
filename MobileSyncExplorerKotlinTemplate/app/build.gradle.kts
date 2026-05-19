plugins {
    android
    kotlin("plugin.compose") version "2.3.20"
}

dependencies {
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.compose.material:material:1.11.1")
    implementation("androidx.compose.material:material-icons-core:1.7.8")
    implementation("androidx.compose.runtime:runtime:1.11.1")
    implementation("androidx.compose.ui:ui:1.11.1")
    implementation("androidx.compose.ui:ui-tooling-preview:1.11.1")
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.10.0")
    implementation("androidx.window:window:1.5.1")

    implementation("com.salesforce.mobilesdk:MobileSync:14.0.0")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4:1.11.1")
    debugImplementation("androidx.compose.ui:ui-tooling:1.11.1")
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.11.1")
}

android {
    namespace = "com.salesforce.mobilesyncexplorerkotlintemplate"

    compileSdk = 37

    defaultConfig {
        applicationId = "com.salesforce.mobilesyncexplorerkotlintemplate"
        targetSdk = 37
        minSdk = 28
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += setOf("/META-INF/{AL2.0,LGPL2.1}", "META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/DEPENDENCIES", "META-INF/NOTICE")
        }
    }

    sourceSets {
        getByName("main") {
            manifest.srcFile("AndroidManifest.xml")
            java.directories.add("src/main/java")
            resources.directories.add("src/main/java")
            res.directories.add("src/main/res")
            assets.directories.add("src/main/assets")
        }
    }
}
