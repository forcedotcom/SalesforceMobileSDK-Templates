rootProject.name = "AndroidNativeTemplate"

include(":app")

val salesforceMobileSdkRoot = File("mobile_sdk/SalesforceMobileSDK-Android")
if (salesforceMobileSdkRoot.exists()) {
    includeBuild(salesforceMobileSdkRoot)
}
