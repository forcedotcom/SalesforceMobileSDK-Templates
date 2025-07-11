plugins {
    android
    `kotlin-android`
    alias(libs.plugins.compose.compiler)
}

dependencies {
    // Required AAR files
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))

    implementation("com.salesforce.mobilesdk:MobileSync:13.0.1")

    // Required dependencies for AAR compilation
    implementation("androidx.constraintlayout:constraintlayout:2.1.3")
    implementation("androidx.fragment:fragment:1.4.1")
    implementation("androidx.fragment:fragment-ktx:1.4.1")
    implementation("androidx.appcompat:appcompat:1.3.1")
    implementation("com.launchdarkly:okhttp-eventsource:4.1.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.1.5")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
    implementation("com.google.android.material:material:1.3.0")

    // Compose
    api("androidx.compose.runtime:runtime-livedata:1.7.6")
    api("androidx.compose.ui:ui:1.7.6")
    api("androidx.compose.ui:ui-tooling:1.7.6")
    api("androidx.compose.material:material:1.7.6")
    api("androidx.compose.material3:material3:1.3.1")
    api("androidx.lifecycle:lifecycle-viewmodel-compose:2.3.1")
    api("androidx.navigation:navigation-compose:2.5.3")

    // Markdown and Image Loading
    api("io.noties.markwon:core:4.6.2")
    api("io.noties.markwon:ext-strikethrough:4.6.2")
    api("io.noties.markwon:html:4.6.2")
    api("io.noties.markwon:linkify:4.6.2")
    api("io.noties.markwon:image-coil:4.6.2")
    api("io.noties.markwon:ext-tables:4.6.2")
    api("io.noties.markwon:ext-tasklist:4.6.2")
    api("io.coil-kt:coil-compose:2.2.2")
}

android {
    namespace = "com.salesforce.androidnativeagentforcetemplate"

    defaultConfig {
        minSdk = libs.versions.minSdkVersion.get().toInt()
        compileSdk = libs.versions.compileSdkVersion.get().toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.toVersion(libs.versions.javaVersion.get())
        targetCompatibility = JavaVersion.toVersion(libs.versions.javaVersion.get())
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = libs.versions.javaVersion.get()
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

    testOptions {
        animationsDisabled = true
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
        }
    }

    buildFeatures {
        compose = true
        viewBinding = true
        dataBinding = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = libs.versions.composeCompilerVersion.get()
    }
}
