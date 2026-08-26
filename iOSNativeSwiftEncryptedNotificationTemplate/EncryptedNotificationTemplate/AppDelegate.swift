/*
 Copyright (c) 2019-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import UIKit
import MobileSync

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    override init() {
        super.init()
        // Set the delegate here in init() rather than later in registerForRemotePushNotifications()
        // to avoid a race condition where a notification could arrive before the delegate is assigned.
        UNUserNotificationCenter.current().delegate = self
        MobileSyncSDKManager.initializeSDK()

        AuthHelper.registerBlock(forCurrentUserChangeNotifications: {
            self.resetViewState {
                self.setupRootViewController()
            }
        })
    }
    
    // MARK: - App delegate lifecycle

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.initializeAppViewState()
        
        registerForRemotePushNotifications()

        AuthHelper.loginIfRequired {
            self.setupRootViewController()
        }
        
        return true
    }
    
    func registerForRemotePushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    PushNotificationManager.sharedInstance().registerForRemoteNotifications()
                }
            } else {
                SalesforceLogger.d(AppDelegate.self, message: "Push notification authorization denied")
            }

            if let error = error {
                SalesforceLogger.e(AppDelegate.self, message: "Push notification authorization error: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        if let _ = UserAccountManager.shared.currentUserAccount?.credentials.accessToken {
            PushNotificationManager.sharedInstance().registerForSalesforceNotifications { result in
                switch (result) {
                    case .success:
                        SalesforceLogger.e(AppDelegate.self, message: "Registration for Salesforce notifications succeeded")
                        Task {
                            do {
                                // Fetch notification type definitions from the server and register
                                // them as UNNotificationCategory objects with iOS. This is what
                                // enables action buttons to appear on notifications — iOS must know
                                // the category and its actions before a notification arrives.
                                try await PushNotificationManager.sharedInstance().fetchAndStoreNotificationTypes()
                            } catch {
                                SalesforceLogger.e(AppDelegate.self, message: "Failed to fetch notification types: \(error)")
                            }
                        }
                    case .failure(let error):
                        SalesforceLogger.e(AppDelegate.self, message: "Registration for Salesforce notifications failed with error: \(error as Error)")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error ) {
         SalesforceLogger.e(AppDelegate.self, message: "Failed to register for remote notifications with error: \(error as NSError)")
    }
    
    // MARK: - Private methods
    func initializeAppViewState() {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window?.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window?.makeKeyAndVisible()
    }
    
    func setupRootViewController() {
        let rootVC = RootViewController(nibName: nil, bundle: nil)
        let navVC = UINavigationController(rootViewController: rootVC)
        self.window?.rootViewController = navVC
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ()) {
        if let rootViewController = self.window?.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        postResetBlock()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    // Show notifications as banners even when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle action button taps
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        // Skip default tap (opens app) and dismiss — only handle custom action buttons.
        // nid is nested inside the "sfdc" dictionary in the payload, not at the top level.
        let sfdc = userInfo["sfdc"] as? [String: Any]
        guard actionIdentifier != UNNotificationDefaultActionIdentifier,
              actionIdentifier != UNNotificationDismissActionIdentifier,
              let nid = sfdc?["nid"] as? String else {
            completionHandler()
            return
        }

        Task {
            do {
                _ = try await PushNotificationManager.sharedInstance().invokeServerNotificationAction(
                    notificationId: nid,
                    actionIdentifier: actionIdentifier
                )
            } catch {
                SalesforceLogger.e(AppDelegate.self, message: "Failed to invoke notification action: \(error)")
            }
            completionHandler()
        }
    }
}
