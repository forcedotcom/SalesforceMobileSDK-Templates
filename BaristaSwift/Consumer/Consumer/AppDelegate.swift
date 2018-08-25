/*
  AppDelegate.swift
  Consumer

  Created by Nicholas McDonald on 1/25/18.

 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
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

import UIKit
import Foundation
import SalesforceSDKCore
import SalesforceSwiftSDK
import SmartSync
import Fabric
import Crashlytics
import Common
import PromiseKit

// Fill these in when creating a new Connected Application on Force.com
// Primary
// SFDCOAuthLoginHost - app-data-4945-dev-ed.cs62.my.salesforce.com

// Backup
// SFDCOAuthLoginHost - innovation-saas-8421-dev-ed.cs54.my.salesforce.com
//let RemoteAccessConsumerKey = "3MVG9XmM8CUVepGaQs_Zw_6A0W73CMRjybtIurEoszHDXQg0I5rhxU2Ph1JaFesaFPFhRo3OhFXVzsT_dyTwc"


@UIApplicationMain
class AppDelegate : UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    override init() {
        super.init()
        _ =  SalesforceSwiftSDKManager.initSDK()
        
        SFSDKAuthHelper.registerBlock(forCurrentUserChangeNotifications: { [weak self] in
            self?.resetViewState {
                self?.setupRootViewController()
            }
        })
        
    }
    
    // MARK: - App delegate lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
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
        
        SFSDKAuthHelper.loginIfRequired { [weak self] in
            if let _ = SFUserAccountManager.sharedInstance().currentUserIdentity?.userId {
                _ = AccountStore.instance.syncDown()
                    .then { _ -> Promise<Account> in
                        return AccountStore.instance.getOrCreateMyAccount()
                    }
                    .then { _ -> Promise<Void> in
                        return (self?.beginSyncDown())!
                    }
                    .done { _ in
                        DispatchQueue.main.async {
                            self?.setupRootViewController()
                        }
                }
            } else {
                SFUserAccountManager.sharedInstance().logout()
            }
        }
        
        Fabric.with([Crashlytics.self])
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        //
        // Uncomment the code below to register your device token with the push notification manager
        //
        //
        // SFPushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        // if (SFUserAccountManager.sharedInstance().currentUser?.credentials.accessToken != nil)
        // {
        //     SFPushNotificationManager.sharedInstance().registerSalesforceNotifications(completionBlock: nil, fail: nil)
        // }
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error )
    {
        // Respond to any push notification registration errors here.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool
    {
        // Uncomment following block to enable IDP Login flow
        // return  SFUserAccountManager.sharedInstance().handleIDPAuthenticationResponse(url, options: options)
        return false;
    }
    
    // MARK: - Private methods
    func initializeAppViewState()
    {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window!.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window!.makeKeyAndVisible()
    }
    
    func setupRootViewController()
    {
        let mainStoryboard : UIStoryboard = UIStoryboard(name: "RootStoryboard", bundle: nil)
        let initialViewController = mainStoryboard.instantiateInitialViewController()
        self.window?.rootViewController = initialViewController
    }
    
    func beginSyncDown() -> Promise<Void> {
        let progressView = SyncProgressViewController()
        self.window?.rootViewController = progressView
        
        let syncFuncs : [() -> Promise<Void>] = [
            CategoryStore.instance.syncDown,
            ProductStore.instance.syncDown,
            ProductOptionStore.instance.syncDown,
            ProductCategoryAssociationStore.instance.syncDown,
            OrderStore.instance.syncDown,
            OrderItemStore.instance.syncDown,
            QuoteStore.instance.syncDown,
            QuoteLineItemStore.instance.syncDown,
            QuoteLineGroupStore.instance.syncDown,
            OpportunityStore.instance.syncDown,
            PricebookStore.instance.syncDown,
            FavoritesStore.instance.syncDown
        ]

        var syncedCount = 0
        let updateProgressView = { () -> Promise<Void> in
            syncedCount = syncedCount + 1
            
            let completed = Float(syncedCount)/Float(syncFuncs.count)
            DispatchQueue.main.async {
                progressView.updateProgress(completed * 100.0)
            }
            return Promise.value(())
        }
                
        let syncs : [Promise<Void>] = syncFuncs.map { syncFunc in
            return syncFunc().then { updateProgressView() }
        }
        
        return when(fulfilled: syncs)
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ())
    {
        if let rootViewController = self.window!.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        
        postResetBlock()
    }
    
   
}

