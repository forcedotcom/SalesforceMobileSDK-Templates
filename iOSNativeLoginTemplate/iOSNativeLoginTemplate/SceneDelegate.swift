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

import MobileSync
import RecaptchaEnterprise
import SalesforceSDKCore
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    /// The reCAPTCHA client used to obtain reCAPTCHA tokens when needed for Salesforce Headless Identity API requests.
    var recaptchaClientObservable: ReCaptchaClientObservable? = nil
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene
        
        //
        // Fill in the values below from the connected app that was created for Native Login and
        // the url of your Experience Cloud community.
        //
        let clientId = "your-client-id"
        let redirectUri = "your-redirect-uri"
        let loginUrl = "your-community-url"
        
        assert(clientId != "your-client-id", "Please add your Native Login client id.")
        assert(redirectUri != "your-redirect-uri", "Please add your Native Login redirect uri.")
        assert(loginUrl != "your-community-url", "Please add your Native Login community url.")
        
        // Used to create a View Controller from SwiftUI.
        let nativeLoginViewController = NativeLoginViewFactory.create()
        
        // This line tells the SDK the app intends to use Native Login.
        SalesforceManager.shared.useNativeLogin(withConsumerKey: clientId,
                                                callbackUrl: redirectUri,
                                                communityUrl: loginUrl,
                                                nativeLoginViewController: nativeLoginViewController,
                                                scene:scene)
        
        //
        // To setup Password-less login:
        //
        // Un-comment the code block below and fill in the values from the Google Cloud project
        // reCAPTCA settings.  Note that only enterprise reCAPTCHA requires the reCAPTCHA
        // Site Key Id and Google Cloud Project Id.
        //
        // When using non-enterprise reCAPTCHA, set reCAPTCHA Site Key Id and
        // Google Cloud Project Id to nil along with a false value for the
        // enterprise parameter.
        //
//        let reCaptchaSiteKeyId = "your-recaptcha-site-key-id"
//        let googleCloudProjectId = "your-google-cloud-project-id"
//        let isReCaptchaEnterprise = true
//
//        assert(reCaptchaSiteKeyId != "your-recaptcha-site-key-id", "Please add your Google Cloud reCAPTCHA Site Key Id.")
//        assert(googleCloudProjectId != "your-google-cloud-project-id", "Please add your Google Cloud Project Id.")
//
//        let recaptchaClientObservable = ReCaptchaClientObservable(reCaptchaSiteKey: reCaptchaSiteKeyId)
//        self.recaptchaClientObservable = recaptchaClientObservable
//
//        // Used to create a View Controller from SwiftUI.
//        let nativeLoginViewController = NativeLoginViewFactory.create(
//            reCaptchaClientObservable: recaptchaClientObservable)
//
//        // This line tells the SDK the app intends to use Password-less Native Login.
//        SalesforceManager.shared.useNativeLogin(withConsumerKey: clientId,
//                                                callbackUrl: redirectUri,
//                                                communityUrl: loginUrl,
//                                                reCaptchaSiteKeyId: reCaptchaSiteKeyId,
//                                                googleCloudProjectId: googleCloudProjectId,
//                                                isReCaptchaEnterprise: isReCaptchaEnterprise,
//                                                nativeLoginViewController: nativeLoginViewController,
//                                                scene:scene)
        
        AuthHelper.registerBlock(forCurrentUserChangeNotifications: {
            self.resetViewState {
                self.setupRootViewController()
            }
        })
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        self.initializeAppViewState()
        AuthHelper.loginIfRequired {
            self.setupRootViewController()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
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
       // Setup store based on config userstore.json
       MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
       // Setup syncs based on config usersyncs.json
       MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()
    
       self.window?.rootViewController = UIHostingController(
           rootView: AccountsListView()
       )
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

@MainActor class ReCaptchaClientObservable: ObservableObject {
    
    @Published var reCaptchaClient: RecaptchaClient? = nil
    
    init(reCaptchaSiteKey: String) {
        Task(priority: .medium) {
            await initializeReCaptchaClient(reCaptchaSiteKey: reCaptchaSiteKey)
        }
    }
    
    final func initializeReCaptchaClient(reCaptchaSiteKey: String) async {
        do {

            reCaptchaClient = try await Recaptcha.getClient(withSiteKey: reCaptchaSiteKey)
        } catch let error {
            SalesforceLogger.e(SceneDelegate.self, message: "Cannot get reCAPTCHA client due to an error with description '\(error.localizedDescription).'.")
        }
    }
}
