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

@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    override init() {
        super.init()
        MobileSyncSDKManager.initializeSDK()
        
        // Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes.
        // self.setupQrCodeLogin()
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
    
    // MARK: - QR Code Login Via Salesforce Identity API UI Bridge Public Implementation
    
    /**
     * When enabling log in via Salesforce UI Bridge API generated QR codes, choose to use the
     * Salesforce Mobile SDK reference format for QR code log in URLs or an entirely custom format.
     *
     * If only one of the two formats is used, which is the most likely implementation for apps using this
     * template, this variable and code related to the unused implementation could be removed.
     */
    let isQrCodeLoginUsingReferenceUrlFormat = true
    
    /**
     * When enabling log in via Salesforce UI Bridge API generated QR codes and using the reference QR
     * code log in URL format, the scheme for the expected QR code log in URL format.
     */
    let qrCodeLoginUrlScheme = "your-qr-code-login-url-scheme"
    
    /**
     * When enabling log in via Salesforce UI Bridge API generated QR codes and using the reference QR
     * code log in URL format, the host for the expected QR code log in URL format.
     */
    let qrCodeLoginUrlHost = "your-qr-code-login-url-host"
    
    
    // MARK: - QR Code Login Via Salesforce Identity API UI Bridge Private Implementation
    
    /**
     * Sets up QR code log in.
     */
    private func setupQrCodeLogin() {
        // Specify a custom Salesforce Mobile SDK log in view controller which is a subclass of the default log in view and enables navigation to the log in QR code scan view.
        UserAccountManager.shared.loginViewControllerConfig.loginViewControllerCreationBlock = {
            return LoginTypeSelectionViewController()
        }
        
        /*
         * When enabling log in via Salesforce UI Bridge API generated QR codes
         * and using the Salesforce Mobile SDK reference format for QR code log
         * in URLs, specify values for the string placeholders in this method to
         * control the parsing of QR code log in URLs. The required UI Bridge
         * API parameters are the frontdoor URL and, for web server flow, the
         * PKCE code verifier.
         *
         * Salesforce Mobile SDK doesn't require a specific format for the QR
         * code log in URL.  The server-side code, such as an APEX class and
         * Visualforce page, must generate a QR code URL that the app is
         * prepared to be opened by and be able to parse the UI Bridge API
         * parameters from.
         *
         * Apps may receive and parse an entirely custom URL format so long as
         * the UI Bridge API parameters are delivered to the
         * `loginWithFrontdoorBridgeUrl` method.
         *
         * As a convenience, Salesforce Mobile SDK accepts a reference QR code
         * log in URL format.  URLs matching that format and using string values
         * provided by the app can be provided to the
         * `loginWithFrontdoorBridgeUrlFromQrCode` method and Salesforce Mobile
         * SDK will retrieve the required UI Bridge API parameters
         * automatically.
         *
         * The reference QR code log in URL format uses this structure where the
         * PKCE code verifier must be URL-Safe Base64 encoded and the overall
         * JSON content must be URL encoded:
         * [scheme]://[host]/[path]?[json-parameter-name]={[frontdoor-bridge-url-key]=<>,[pkce-code-verifier-key]=<>}
         *
         * Any URL link scheme supported by the native platform may be used.
         * This includes Android App Links and iOS Universal Links. Be certain
         * to follow the latest security practices documented by the app's
         * native platform.
         *
         * If using an entirely custom format for QR code log in URLs, the
         * assignment of these strings can be safely removed.
         */
        // The scheme and host for the expected QR code log in URL format.
        assert(qrCodeLoginUrlScheme != "your-qr-code-login-url-scheme", "Please add your login QR code URL's scheme.")
        assert(qrCodeLoginUrlHost != "your-qr-code-login-url-host", "Please add your login QR code URL's host.")
        // The path, parameter names and JSON keys for the expected QR code log in URL format.
        SalesforceLoginViewController.qrCodeLoginUrlPath = "your-qr-code-login-url-path"
        SalesforceLoginViewController.qrCodeLoginUrlJsonParameterName = "your-qr-code-login-url-json-parameter-name"
        SalesforceLoginViewController.qrCodeLoginUrlJsonFrontdoorBridgeUrlKey = "your-qr-code-login-url-json-frontdoor-bridge-url-key"
        SalesforceLoginViewController.qrCodeLoginUrlJsonPkceCodeVerifierKey = "your-qr-code-login-url-json-pkce-code-verifier-key"
        assert(SalesforceLoginViewController.qrCodeLoginUrlPath != "your-qr-code-login-url-path", "Please add your login QR code URL's path.")
        assert(SalesforceLoginViewController.qrCodeLoginUrlJsonParameterName != "your-qr-code-login-url-json-parameter-name", "Please add your login QR code URL's UI Bridge API JSON query string parameter name.")
        assert(SalesforceLoginViewController.qrCodeLoginUrlJsonFrontdoorBridgeUrlKey != "your-qr-code-login-url-json-frontdoor-bridge-url-key", "Please add your login QR code URL's UI Bridge API JSON frontdoor bridge URL key.")
        assert(SalesforceLoginViewController.qrCodeLoginUrlJsonPkceCodeVerifierKey != "your-qr-code-login-url-json-pkce-code-verifier-key", "Please add your login QR code URL's UI Bridge API JSON PKCE code verifier key.")
    }
    
}
