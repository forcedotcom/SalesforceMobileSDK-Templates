buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.10.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
