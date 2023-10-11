rootProject.name = "AndroidNativeKotlinTemplate"

include(":app")

def salesforceMobileSdkRoot = new File('mobile_sdk/SalesforceMobileSDK-Android');
if (salesforceMobileSdkRoot.exists()) {
    includeBuild(salesforceMobileSdkRoot)
}
