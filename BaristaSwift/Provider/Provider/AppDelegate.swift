//
//  AppDelegate.swift
//  Provider
//
//  Created by Nicholas McDonald on 3/6/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import SalesforceSDKCore
import SalesforceSwiftSDK
import SmartSync
import Fabric
import Crashlytics
import Common

// Primary
// SFDCOAuthLoginHost - app-data-4945-dev-ed.cs62.my.salesforce.com
let RemoteAccessConsumerKey = "3MVG9er.T8KbeePTyjpxAuJmo2z4W_0qU75YSBGndHmK_XGtNql0S3MMSOyGY.Apu1xKLOuGQpT0occX1dgOQ"
let OAuthRedirectURI        = "com.salesforce.barista.Provider://oauth2/success";

// Backup
// SFDCOAuthLoginHost - innovation-saas-8421-dev-ed.cs54.my.salesforce.com
//let RemoteAccessConsumerKey = "3MVG9XmM8CUVepGaQs_Zw_6A0W73CMRjybtIuqOlXJ6m7yb9FSRjbrLnj388H9rOXzRJG6hbPY0KyXKi_orlr"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    override init() {
        super.init()
        
        SalesforceSwiftSDKManager.initSDK()
            .Builder.configure { (appconfig: SFSDKAppConfig) -> Void in
                appconfig.oauthScopes = ["web", "api"]
                appconfig.remoteAccessConsumerKey = RemoteAccessConsumerKey
                appconfig.oauthRedirectURI = OAuthRedirectURI
            }.postInit {
                //Uncomment the following line inorder to enable/force the use of advanced authentication flow.
                // SFUserAccountManager.sharedInstance().advancedAuthConfiguration = SFOAuthAdvancedAuthConfiguration.require;
                // OR
                // To  retrieve advanced auth configuration from the org, to determine whether to initiate advanced authentication.
                // SFUserAccountManager.sharedInstance().advancedAuthConfiguration = SFOAuthAdvancedAuthConfiguration.allow;
                
                // NOTE: If advanced authentication is configured or forced,  it will launch Safari to handle authentication
                // instead of a webview. You must implement application:openURL:options  to handle the callback.
            }
            .postLaunch {  [unowned self] (launchActionList: SFSDKLaunchAction) in
                let launchActionString = SalesforceSDKManager.launchActionsStringRepresentation(launchActionList)
                SalesforceSwiftLogger.log(type(of:self), level:.info, message:"Post-launch: launch actions taken: \(launchActionString)")
                if let currentUserId = SFUserAccountManager.sharedInstance().currentUserIdentity?.userId {
                    AccountStore.instance.syncDown(completion: { (syncState) in
                        if let complete = syncState?.isDone(), complete == true {
                            if let _ = AccountStore.instance.account(currentUserId) {
                                DispatchQueue.main.async {
                                    self.beginSyncDown {
                                        self.setupRootViewController()
                                    }
                                }
                            } else {
                                guard let user = SFUserAccountManager.sharedInstance().currentUser else {return}
                                let newAccount = Account()
                                newAccount.accountNumber = user.accountIdentity.userId
                                newAccount.name = user.userName
                                newAccount.ownerId = user.accountIdentity.userId
                                AccountStore.instance.create(newAccount, completion: { (syncState) in
                                    if let complete = syncState?.isDone(), complete == true {
                                        DispatchQueue.main.async {
                                            self.beginSyncDown {
                                                self.setupRootViewController()
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    })
                    
                } else {
                    SFUserAccountManager.sharedInstance().logout()
                }
                
                SalesforceSwiftLogger.setLogLevel(.error)
                SFSDKLogger.setLogLevel(.error)
            }.postLogout {  [unowned self] in
                self.handleSdkManagerLogout()
            }.switchUser{ [unowned self] (fromUser: SFUserAccount?, toUser: SFUserAccount?) -> () in
                self.handleUserSwitch(fromUser, toUser: toUser)
            }.launchError {  [unowned self] (error: Error, launchActionList: SFSDKLaunchAction) in
                SFSDKLogger.log(type(of:self), level:.error, message:"Error during SDK launch: \(error.localizedDescription)")
                self.initializeAppViewState()
                SalesforceSDKManager.shared().launch()
            }
            .done()
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.initializeAppViewState();
        
        let navAppearance = UINavigationBar.appearance()
        navAppearance.barTintColor = Theme.appNavBarTintColor
        navAppearance.titleTextAttributes = [NSAttributedStringKey.foregroundColor: Theme.appNavBarTextColor, NSAttributedStringKey.font: Theme.appMediumFont(14.0)!]
        
        // If you wish to register for push notifications, uncomment the line below.  Note that,
        // if you want to receive push notifications from Salesforce, you will also need to
        // implement the application:didRegisterForRemoteNotificationsWithDeviceToken: method (below).
        //
        // SFPushNotificationManager.sharedInstance().registerForRemoteNotifications()
        
        //Uncomment the code below to see how you can customize the color, textcolor, font and fontsize of the navigation bar
        //var loginViewConfig = SFSDKLoginViewControllerConfig()
        //Set showSettingsIcon to NO if you want to hide the settings icon on the nav bar
        //loginViewConfig.showSettingsIcon = false
        //Set showNavBar to NO if you want to hide the top bar
        //loginViewConfig.showNavbar = true
        //loginViewConfig.navBarColor = UIColor(red: 0.051, green: 0.765, blue: 0.733, alpha: 1.0)
        //loginViewConfig.navBarTextColor = UIColor.white
        //loginViewConfig.navBarFont = UIFont(name: "Helvetica", size: 16.0)
        //SFUserAccountManager.sharedInstance().loginViewControllerConfig = loginViewConfig
        
        SalesforceSwiftSDKManager.shared().launch()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Private methods
    func initializeAppViewState() {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window!.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window!.makeKeyAndVisible()
    }
    
    func setupRootViewController() {
        self.window?.rootViewController = ViewController(nibName: nil, bundle: nil)
    }
    
    func beginSyncDown(completion:@escaping () -> Void) {
        LocalOrderStore.instance.fullSyncDown(completion: completion)
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ()) {
        if let rootViewController = self.window!.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        
        postResetBlock()
    }
    
    func handleSdkManagerLogout() {
        SFSDKLogger.log(type(of:self), level:.debug, message: "SFUserAccountManager logged out.  Resetting app.")
        self.resetViewState { () -> () in
            self.initializeAppViewState()
            
            // Multi-user pattern:
            // - If there are two or more existing accounts after logout, let the user choose the account
            //   to switch to.
            // - If there is one existing account, automatically switch to that account.
            // - If there are no further authenticated accounts, present the login screen.
            //
            // Alternatively, you could just go straight to re-initializing your app state, if you know
            // your app does not support multiple accounts.  The logic below will work either way.
            
            var numberOfAccounts : Int;
            let allAccounts = SFUserAccountManager.sharedInstance().allUserAccounts()
            numberOfAccounts = (allAccounts!.count);
            
            if numberOfAccounts > 1 {
                let userSwitchVc = SFDefaultUserManagementViewController(completionBlock: {
                    action in
                    self.window!.rootViewController!.dismiss(animated:true, completion: nil)
                })
                if let actualRootViewController = self.window!.rootViewController {
                    actualRootViewController.present(userSwitchVc, animated: true, completion: nil)
                }
            } else {
                if (numberOfAccounts == 1) {
                    SFUserAccountManager.sharedInstance().currentUser = allAccounts![0]
                }
                SalesforceSDKManager.shared().launch()
            }
        }
    }
    
    func handleUserSwitch(_ fromUser: SFUserAccount?, toUser: SFUserAccount?) {
        let fromUserName = (fromUser != nil) ? fromUser?.userName : "<none>"
        let toUserName = (toUser != nil) ? toUser?.userName : "<none>"
        SFSDKLogger.log(type(of:self), level:.debug, message:"SFUserAccountManager changed from user \(String(describing: fromUserName)) to \(String(describing: toUserName)).  Resetting app.")
        self.resetViewState { () -> () in
            self.initializeAppViewState()
            SalesforceSDKManager.shared().launch()
        }
    }
}

