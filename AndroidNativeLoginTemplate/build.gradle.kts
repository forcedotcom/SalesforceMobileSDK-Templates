buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // TODO: AGP 9.2.0 causes libs:MobileSync:lintAnalyzeDebug to hang.  Review with future versions. ECJ20260423
        classpath("com.android.tools.build:gradle:9.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
