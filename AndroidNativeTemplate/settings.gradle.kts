rootProject.name = "AndroidNativeTemplate"

include(":app")

def salesforceMobileSdkRoot = new File('mobile_sdk/SalesforceMobileSDK-Android');
if (salesforceMobileSdkRoot.exists()) {
    includeBuild(salesforceMobileSdkRoot)
}
