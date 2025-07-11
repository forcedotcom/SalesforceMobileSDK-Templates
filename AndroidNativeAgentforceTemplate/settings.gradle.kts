rootProject.name = "AndroidNativeAgentforceTemplate"

include(":app")

pluginManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// settings.gradle.kts
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

// If you want to use a local copy of AgentforceSDK, clone it at the root of this repo.
// When you are done, `rm -rf` it.
if (file("AgentforceSDK").exists()) {
    logger.lifecycle("AgentforceSDK. Building from source instead of AAR")
    includeBuild("AgentforceSDK")
}
