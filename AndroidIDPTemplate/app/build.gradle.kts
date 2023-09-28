
plugins {
    android
    `kotlin-android`
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync")
}

android {
    namespace = "com.salesforce.samples.salesforceandroididptemplateapp"

    compileSdk = 33

    defaultConfig {
        targetSdk = 33
        minSdk = 24
    }

    buildTypes {
      debug {
         enableAndroidTestCoverage = true
      }
   }

  sourceSets {

        getByName("main") {
      manifest.srcFile("AndroidManifest.xml")
      java.srcDirs(arrayOf("src"))
      resources.srcDirs(arrayOf("src"))
      aidl.srcDirs(arrayOf("src"))
      renderscript.srcDirs(arrayOf("src"))
      res.srcDirs(arrayOf("res"))
      assets.srcDirs(arrayOf("assets"))
    }
  }
  packagingOptions {
      resources {
          excludes += setOf("META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/DEPENDENCIES", "META-INF/NOTICE")
      }
  }
}

repositories {
  google()
  mavenCentral()
}
