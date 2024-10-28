//
//  SceneDelegate.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 2/5/21.
//  Copyright (c) 2021-present, salesforce.com, inc. All rights reserved.
//
//  Redistribution and use of this software in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials provided
//  with the distribution.
//  * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission of salesforce.com, inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import UIKit
import SwiftUI
import SalesforceSDKCore
import MobileSync

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene

        AuthHelper.registerBlock(forCurrentUserChangeNotifications: scene) {
            self.resetViewState {
                self.setupRootViewController(userActivity: connectionOptions.userActivities.first)
            }
        }
        self.initializeAppViewState()
        AuthHelper.loginIfRequired(scene) {
            self.setupRootViewController(userActivity: connectionOptions.userActivities.first)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Uncomment following block to enable IDP Login flow
//        if let urlContext = URLContexts.first {
//            self.enableIDPLoginFlowForURLContext(urlContext, scene: scene)
//
//        }
        guard let url = URLContexts.first?.url, let userAccount = UserAccountManager.shared.currentUserAccount else {
            return
        }

        let sObjectManager = SObjectDataManager.sharedInstance(for: userAccount)
        if url.absoluteString.contains("contact/new") {
            self.window?.rootViewController = UIHostingController(rootView: ContactListView(sObjectManager: sObjectManager, newContact: true))
        } else if let contactRange = url.absoluteString.range(of: "contact/") {
            let id = String(url.absoluteString[contactRange.upperBound...])
            self.window?.rootViewController = UIHostingController(rootView: NavigationStack {
                ContactDetailView(localId: id, sObjectDataManager: sObjectManager)
            })
        }
    }
    
    func enableIDPLoginFlowForURLContext(_ urlContext: UIOpenURLContext, scene: UIScene) -> Bool {
        return UserAccountManager.shared.handleIdentityProviderResponse(from: urlContext.url, with: [UserAccountManager.IDPSceneKey: scene.session.persistentIdentifier])
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
   
    func setupRootViewController(userActivity: NSUserActivity?) {
        let sObjectManager = SObjectDataManager.sharedInstance(for: UserAccountManager.shared.currentUserAccount!)

        if let userActivity = userActivity, userActivity.title == openDetailPath,
           let selectionId = userActivity.userInfo?[openDetailRecordIdKey] as? String {
            self.window?.rootViewController = UIHostingController(rootView:  NavigationStack {
                ContactDetailView(localId: selectionId, sObjectDataManager: sObjectManager)
            })
        } else {
            self.window?.rootViewController = UIHostingController(rootView: Tabs(sObjectDataManager: sObjectManager))
        }
    }

    func resetViewState(_ postResetBlock: @escaping () -> ()) {
        if let rootViewController = self.window?.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
            self.window?.rootViewController = nil
        }
        postResetBlock()
    }
}
