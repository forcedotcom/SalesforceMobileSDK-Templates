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
import SwiftUI

class AppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    override init() {
        super.init()
        MobileSyncSDKManager.initializeSDK()
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - App delegate lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // If you wish to register for push notifications, uncomment the line below.  Note that,
        // if you want to receive push notifications from Salesforce, you will also need to
        // implement the application(application, didRegisterForRemoteNotificationsWithDeviceToken) method (below).
//        self.registerForRemotePushNotifications()
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
        // Uncomment the code below to register your device token with the push notification manager
//        didRegisterForRemoteNotifications(deviceToken)
    }
    
    func didRegisterForRemoteNotifications(_ deviceToken: Data) {
        PushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        if let _ = UserAccountManager.shared.currentUserAccount?.credentials.accessToken {
            PushNotificationManager.sharedInstance().registerForSalesforceNotifications { (result) in
                switch (result) {
                    case  .success(let successFlag):
                        SalesforceLogger.d(AppDelegate.self, message: "Registration for Salesforce notifications status:  \(successFlag)")
                    case .failure(let error):
                        SalesforceLogger.e(AppDelegate.self, message: "Registration for Salesforce notifications failed \(error)")
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error ) {
        // Respond to any push notification registration errors here.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Uncomment following block to enable IDP Login flow
//        return self.enableIDPLoginFlowForURL(url, options: options)
        return false;
    }
    
    func enableIDPLoginFlowForURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return  UserAccountManager.shared.handleIdentityProviderResponse(from: url, with: options)
    }
}
