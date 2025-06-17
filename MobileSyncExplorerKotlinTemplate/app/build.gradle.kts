plugins {
    android
    `kotlin-android`
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21"
}

dependencies {
    val composeVersion = "1.8.2"

    implementation("androidx.core:core-ktx:1.16.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.9.1")
    implementation("androidx.window:window:1.4.0")

    implementation("com.salesforce.mobilesdk:MobileSync:13.1.0")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    implementation("androidx.core:core-ktx:1.16.0")

    // Note: Compose dependencies are synchronized with the content in the Compose set up guide for easier migration to new versions.
    val composeBom = platform("androidx.compose:compose-bom:2025.05.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.compose.material:material:$composeVersion")

    implementation("androidx.compose.ui:ui-tooling-preview:$composeVersion")
    debugImplementation("androidx.compose.ui:ui-tooling:$composeVersion")

    androidTestImplementation("androidx.compose.ui:ui-test-junit4:$composeVersion")
    debugImplementation("androidx.compose.ui:ui-test-manifest:$composeVersion")

    implementation("androidx.compose.material:material-icons-core")

    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.1")
    implementation("androidx.compose.runtime:runtime-livedata:$composeVersion")
}

android {
    namespace = "com.salesforce.mobilesyncexplorerkotlintemplate"

    compileSdk = 35

    defaultConfig {
        applicationId = "com.salesforce.mobilesyncexplorerkotlintemplate"
        targetSdk = 35
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

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        aidl = true
        renderScript = true
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
            java.srcDir("src/main/java")
            resources.srcDir("src/main/java")
            aidl.srcDirs(arrayOf("src/main"))
            renderscript.srcDirs(arrayOf("src/main"))
            res.srcDirs(arrayOf("src/main/res"))
            assets.srcDirs(arrayOf("src/main/assets"))
        }
    }
}

repositories {
    google()
    mavenCentral()
}
