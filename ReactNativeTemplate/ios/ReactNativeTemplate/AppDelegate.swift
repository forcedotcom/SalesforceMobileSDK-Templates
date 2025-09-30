import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider
import SalesforceReact
import SalesforceSDKCore
import UserNotifications
import UserNotificationsUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  var window: UIWindow?
  
  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?
  
  override init() {
    super.init()
    
    // Need to use SalesforceReactSDKManager in Salesforce Mobile SDK apps using React Native
    SalesforceReactSDKManager.initializeSDK()
  }
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    self.launchOptions = launchOptions
    
    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()
    
    reactNativeDelegate = delegate
    reactNativeFactory = factory
    
    window = UIWindow(frame: UIScreen.main.bounds)
    
    // If you wish to register for push notifications uncomment the line
    // below.  Note that if you want to receive push notifications from
    // Salesforce you will also need to implement the
    // application:didRegisterForRemoteNotificationsWithDeviceToken:
    // method below.
    registerForRemotePushNotifications()
    
    // Uncomment the code below to see how you can customize the color,
    // text color, font and font size of the navigation bar.
    customizeLoginView()
    
    AuthHelper.loginIfRequired() {
      factory.startReactNative(
        withModuleName: "ReactNativeTemplate",
        in: self.window,
        launchOptions: launchOptions
      )
    }
    
    return true
  }
  
  private func registerForRemotePushNotifications() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
      if (granted) {
        DispatchQueue.main.async {
          PushNotificationManager.shared.registerForRemoteNotifications()
        }
      }
      
      if (error != nil) {
        SalesforceLogger.e(AppDelegate.self, message: "Push notification authorization error: \(String(describing: error))")
      }
    }
  }
  
  private func customizeLoginView() {
    let loginViewConfig = SalesforceLoginViewControllerConfig()
    
    // Set `showsSettingsIcon` to false if you want to hide the settings icon on the nav bar
    loginViewConfig.showsSettingsIcon = true
    
    // Set `showsNavigationBar` to false if you want to hide the top bar
    loginViewConfig.showsNavigationBar = true
    
    loginViewConfig.navigationBarColor = UIColor.init(red: 0.051, green:0.765, blue:0.733, alpha:1.0)
    loginViewConfig.navigationTitleColor = UIColor.white
    loginViewConfig.navigationBarFont = UIFont.init(name: "Helvetica", size:16.0)
    
    UserAccountManager.shared.loginViewControllerConfig = loginViewConfig
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Uncomment the code below to register your device token with the push notification manager
    didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
  }
  
  private func didRegisterForRemoteNotifications(withDeviceToken deviceToken:Data) {
    
    PushNotificationManager.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    
    if UserAccountManager.shared.currentUserAccount?.credentials.accessToken != nil {
      PushNotificationManager.shared.registerSalesforceNotifications(completionBlock: nil, failBlock: nil)
    }
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
    // Respond to any push notification registration errors here
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }
  
  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
