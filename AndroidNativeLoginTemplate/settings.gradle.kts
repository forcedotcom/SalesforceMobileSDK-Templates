rootProject.name = "AndroidNativeLoginTemplate"

include(":app")

val salesforceMobileSdkRoot = File("../../SalesforceMobileSDK-Android")
if (salesforceMobileSdkRoot.exists()) {
    includeBuild(salesforceMobileSdkRoot)
}
