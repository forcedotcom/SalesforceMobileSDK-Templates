rootProject.name = "SalesforceMobileSDK-Templates"

includeBuild(File(settingsDir, "AndroidIDPTemplate"))
includeBuild(File(settingsDir, "AndroidNativeKotlinTemplate"))
includeBuild(File(settingsDir, "AndroidNativeTemplate"))
includeBuild(File(settingsDir, "MobileSyncExplorerKotlinTemplate"))
//includeBuild(File(settingsDir, "MobileSyncExplorerReactNative/android"))
//includeBuild(File(settingsDir, "ReactNativeDeferredTemplate/android"))
//includeBuild(File(settingsDir, "ReactNativeTemplate/android"))
includeBuild(File(settingsDir, "ReactNativeTypeScriptTemplate/android"))

/*
 * This path may be locally modified to specify SalesforceMobileSDK-Android
 * sources to build and override dependencies from.
 */
val workspaceSalesforceMobileSdkRoot = File("../SalesforceMobileSDK-Android")
if (workspaceSalesforceMobileSdkRoot.exists()) {
    includeBuild(workspaceSalesforceMobileSdkRoot)
}
