rootProject.name = "AndroidNativeKotlinTemplate"

include(":app")

includeBuild(File(settingsDir, "mobile_sdk/SalesforceMobileSDK-Android"))
