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

/**
 * AppDelegate handles application lifecycle events and Salesforce Mobile SDK initialization.
 * 
 * This class serves as the main entry point for the Agentforce iOS demo application,
 * managing SDK initialization, push notifications, and URL handling for authentication flows.
 * 
 * ## Key Responsibilities
 * - Initialize Salesforce Mobile SDK components
 * - Handle application lifecycle events
 * - Manage push notification registration (optional)
 * - Support Identity Provider (IDP) authentication flows
 * - Configure scene-based architecture for iOS 13+
 * 
 * ## SDK Integration
 * The AppDelegate initializes MobileSyncSDKManager which provides:
 * - Core Salesforce authentication
 * - Data synchronization capabilities
 * - Network request handling
 * - User account management
 * 
 * ## Scene Support
 * Starting with iOS 13, the app uses scene-based architecture managed through
 * SceneDelegate for window and view lifecycle management.
 */
@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate {
    /// Main application window (used for iOS 12 and earlier compatibility)
    var window: UIWindow?
    
    /**
     * Initializes the AppDelegate and Salesforce Mobile SDK.
     * 
     * This initializer is called when the application first launches and performs
     * critical SDK setup before any UI components are created.
     * 
     * ## Initialization Process
     * 1. Calls super.init() to initialize UIApplicationDelegate
     * 2. Initializes MobileSyncSDKManager for Salesforce functionality
     * 
     * ## SDK Components Initialized
     * - SalesforceSDKCore: Authentication and core services
     * - MobileSync: Data synchronization and offline capabilities
     * - Network layer for API communication
     * - User account management
     * 
     * ## Thread Safety
     * This method is called on the main thread during app launch.
     */
    override init() {
        super.init()
        // Initialize Salesforce Mobile SDK with core services
        MobileSyncSDKManager.initializeSDK()
    }
    
    // MARK: UISceneSession Lifecycle
    
    /**
     * Configures the scene session for new UI scenes.
     * 
     * This method is called when the system creates a new scene session,
     * typically when the app launches or when the user creates a new window
     * on iPad or other multi-window capable devices.
     * 
     * ## Scene Configuration
     * Returns a default scene configuration that uses SceneDelegate
     * to manage the window and view hierarchy for the new scene.
     * 
     * - Parameter application: The singleton app object
     * - Parameter connectingSceneSession: The session object for the new scene
     * - Parameter options: Connection options for the scene
     * - Returns: Scene configuration for the new scene
     */
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Return default configuration defined in Info.plist
        // This configuration specifies SceneDelegate as the scene delegate class
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    /**
     * Handles cleanup when scene sessions are discarded.
     * 
     * Called when the user closes scenes (windows) or when the system
     * discards scenes to free up resources. Use this method to clean up
     * any scene-specific resources.
     * 
     * ## Cleanup Scenarios
     * - User explicitly closes a scene/window
     * - System discards scenes due to memory pressure
     * - App was terminated while scenes were inactive
     * 
     * - Parameter application: The singleton app object
     * - Parameter sceneSessions: Set of sessions that were discarded
     */
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Perform cleanup for discarded scenes
        // In this demo app, no scene-specific resources need cleanup
        // In production apps, you might:
        // - Cancel scene-specific network requests
        // - Clean up temporary files
        // - Save unsaved data
    }

    // MARK: - App delegate lifecycle
    
    /**
     * Completes application launch configuration.
     * 
     * Called after the app has launched and basic initialization is complete.
     * This is the primary location for final app setup and optional feature
     * configuration.
     * 
     * ## Configuration Options
     * The method includes commented code for push notification registration.
     * Uncomment and configure as needed for your specific use case.
     * 
     * ## Push Notification Setup
     * To enable push notifications:
     * 1. Uncomment the registerForRemotePushNotifications() call
     * 2. Implement didRegisterForRemoteNotificationsWithDeviceToken
     * 3. Configure push notification entitlements
     * 4. Set up Salesforce push notification handling
     * 
     * - Parameter application: The singleton app object
     * - Parameter launchOptions: Dictionary with launch options
     * - Returns: true to indicate successful launch completion
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Optional: Register for push notifications
        // Uncomment the line below to enable push notifications from Salesforce
        // Note: You must also implement didRegisterForRemoteNotificationsWithDeviceToken
        // self.registerForRemotePushNotifications()
        
        return true
    }

    /**
     * Registers the application for remote push notifications.
     * 
     * This method requests user permission for push notifications and registers
     * with the system if permission is granted. It integrates with Salesforce's
     * push notification system for real-time updates.
     * 
     * ## Permission Flow
     * 1. Requests authorization for alert, sound, and badge notifications
     * 2. If granted, registers with APNs via PushNotificationManager
     * 3. Logs results for debugging purposes
     * 
     * ## Integration with Salesforce
     * Once registered, the app can receive:
     * - Agent response notifications
     * - System alerts and updates
     * - Custom business logic notifications
     * 
     * ## Error Handling
     * All authorization errors are logged using SalesforceLogger
     * for debugging and monitoring purposes.
     * 
     * ## Thread Safety
     * The registration call is dispatched to the main thread as required by APNs.
     */
    func registerForRemotePushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                // Registration must occur on main thread
                DispatchQueue.main.async {
                    PushNotificationManager.sharedInstance().registerForRemoteNotifications()
                }
            } else {
                SalesforceLogger.d(AppDelegate.self, message: "Push notification authorization denied")
            }

            // Log any authorization errors for debugging
            if let error = error {
                SalesforceLogger.e(AppDelegate.self, message: "Push notification authorization error: \(error)")
            }
        }
    }
        
    /**
     * Handles successful device token registration with APNs.
     * 
     * Called by the system when the device successfully registers for push
     * notifications and receives a device token from Apple Push Notification service.
     * 
     * ## Usage
     * Uncomment the method call to didRegisterForRemoteNotifications to enable
     * full push notification integration with Salesforce services.
     * 
     * - Parameter application: The singleton app object
     * - Parameter deviceToken: Unique device token from APNs
     */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Uncomment the code below to register your device token with the push notification manager
        // didRegisterForRemoteNotifications(deviceToken)
    }
    
    /**
     * Completes push notification setup with Salesforce services.
     * 
     * This method registers the device token with Salesforce's push notification
     * system, enabling the app to receive notifications from Salesforce services
     * including Agentforce updates.
     * 
     * ## Registration Process
     * 1. Registers device token with PushNotificationManager
     * 2. Checks for valid user authentication
     * 3. Registers with Salesforce notification services
     * 4. Handles registration success/failure
     * 
     * ## Authentication Requirement
     * The user must be authenticated with Salesforce before notifications
     * can be registered. The method checks for a valid access token.
     * 
     * ## Error Handling
     * Registration results are logged for debugging purposes.
     * Failed registrations should be retried after user authentication.
     * 
     * - Parameter deviceToken: Device token from APNs registration
     */
    func didRegisterForRemoteNotifications(_ deviceToken: Data) {
        // Register device token with Salesforce push notification manager
        PushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        
        // Only register for Salesforce notifications if user is authenticated
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
    
    /**
     * Handles push notification registration failures.
     * 
     * Called by the system when device registration with APNs fails.
     * Common causes include network connectivity issues, invalid provisioning,
     * or simulator usage (which doesn't support push notifications).
     * 
     * ## Error Handling Strategy
     * - Log the error for debugging
     * - Implement retry logic if appropriate
     * - Gracefully degrade functionality if push notifications are not available
     * 
     * - Parameter application: The singleton app object
     * - Parameter error: Error describing the registration failure
     */
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error ) {
        // Log registration failure for debugging
        SalesforceLogger.e(AppDelegate.self, message: "Failed to register for remote notifications: \(error)")
        
        // Implement fallback behavior for apps that require push notifications
        // For example, you might:
        // - Display an alert to the user
        // - Disable features that depend on push notifications
        // - Schedule retry attempts
    }
    
    /**
     * Handles URL opening requests for authentication flows.
     * 
     * Called when another app or system service requests to open a URL
     * in this application. This is commonly used for OAuth authentication
     * redirects and Identity Provider (IDP) login flows.
     * 
     * ## Authentication Flow Usage
     * When users authenticate through external identity providers:
     * 1. User is redirected to external authentication service
     * 2. After successful authentication, user is redirected back to app
     * 3. This method receives the callback URL with authentication tokens
     * 4. enableIDPLoginFlowForURL processes the authentication response
     * 
     * ## Configuration
     * To enable IDP login flow:
     * 1. Uncomment the enableIDPLoginFlowForURL call
     * 2. Configure URL schemes in Info.plist
     * 3. Set up identity provider in Salesforce org
     * 
     * - Parameter app: The singleton app object
     * - Parameter url: URL that triggered the app opening
     * - Parameter options: Dictionary containing open options
     * - Returns: true if URL was handled, false otherwise
     */
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Uncomment following block to enable IDP Login flow
        // return self.enableIDPLoginFlowForURL(url, options: options)
        return false;
    }
    
    /**
     * Processes Identity Provider authentication callback URLs.
     * 
     * This method handles OAuth callback URLs from external identity providers
     * such as Google, Microsoft, or custom SAML providers configured in
     * Salesforce. It extracts authentication tokens and completes the login flow.
     * 
     * ## IDP Integration Flow
     * 1. User initiates login through external identity provider
     * 2. External service authenticates user and redirects to app
     * 3. This method processes the callback URL
     * 4. UserAccountManager extracts tokens and creates session
     * 5. User is logged into the Salesforce environment
     * 
     * ## URL Format
     * Callback URLs typically contain:
     * - Authorization codes
     * - Access tokens
     * - State parameters for security
     * - Error codes if authentication failed
     * 
     * ## Security Considerations
     * The UserAccountManager validates:
     * - URL scheme matches configured callback
     * - State parameters prevent CSRF attacks
     * - Tokens are properly formatted and valid
     * 
     * - Parameter url: Authentication callback URL
     * - Parameter options: Additional URL opening options
     * - Returns: true if authentication URL was processed successfully
     */
    func enableIDPLoginFlowForURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return  UserAccountManager.shared.handleIdentityProviderResponse(from: url, with: options)
    }
    
}
