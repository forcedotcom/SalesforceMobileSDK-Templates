plugins { `kotlin-dsl` }

repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
}

dependencies {
    implementation("com.android.tools.build:gradle:8.2.0")
    implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}
