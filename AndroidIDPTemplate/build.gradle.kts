buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // TODO: AGP 9.2.0 causes libs:MobileSync:lintAnalyzeDebug to hang.  Review with future versions. ECJ20260423
        classpath("com.android.tools.build:gradle:9.1.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
