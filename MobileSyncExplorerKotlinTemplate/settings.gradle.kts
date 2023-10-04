rootProject.name = "MobileSyncExplorerKotlinTemplate"

include(":app")

includeBuild(File(settingsDir, "mobile_sdk/SalesforceMobileSDK-Android"))
