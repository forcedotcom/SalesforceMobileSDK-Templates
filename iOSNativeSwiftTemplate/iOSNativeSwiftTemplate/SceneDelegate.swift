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

import UIKit
import SwiftUI
import MobileSync
import SalesforceSDKCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    // MARK: - UISceneDelegate Implementation
    
    func scene(_ scene: UIScene,
               openURLContexts urlContexts: Set<UIOpenURLContext>)
    {
  
        // Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes.
        /*
         * Note: The app's Info.plist must be updated with the URL type, scheme
         * and any other desired options to support custom URL scheme deep links
         * for the QR login code.  It is possible to use universal links for
         * this also so long as the app is configured, the UI bridge API
         * parameters are obtained and passed to
         * LoginTypeSelectionViewController.loginWithFrontdoorBridgeUrl
         */
//        // When the app process was running and receives a custom URL scheme deep link, use login QR code if applicable.
//        if let urlContext = urlContexts.first {
//            useQrCodeLogInUrl(urlContext.url)
//        }
    }
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions)
    {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        self.window?.windowScene = windowScene
       
        AuthHelper.registerBlock(forCurrentUserChangeNotifications: {
           self.resetViewState {
               self.setupRootViewController()
           }
        })
        
        // Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes.
        // When the app process was not running and receives a custom URL scheme deep link, use login QR code if applicable.
//        if let urlContext = connectionOptions.urlContexts.first {
//            useQrCodeLogInUrl(urlContext.url)
//        }
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
    
    // MARK: - Private Methods
    
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
    
    // MARK: - QR Code Login Via Salesforce Identity API UI Bridge Private Implementation
    
    /**
     * Validates and uses a QR code log in URL.
     * - Parameters
     *   - url: The URL to validate and use as a QR code log in URL
     */
    private func useQrCodeLogInUrl(_ url: URL) {
        
        /*
         * When enabling log in via Salesforce UI Bridge API generated QR codes,
         * customize the template content of this method to receive the URL and
         * provide Salesforce Mobile SDK with the log in parameters. The
         * required UI Bridge API parameters are the frontdoor URL and, for web
         * server flow, the PKCE code verifier.
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
         */
        
        // Choose to use the reference QR code log in URL format for an entirely custom format.
        let isAppExpectedReferenceQrCodeLoginUrlFormat = true /* To-do: An app will likely use on of the two options, so this variable may be removed. */
        if (isAppExpectedReferenceQrCodeLoginUrlFormat) {
            
            // When using `loginWithFrontdoorBridgeUrlFromQrCode` and the reference QR code log in URL format, validate the potential QR code log in URL matches the app's expections.
            /* To set up QR code log in using `loginWithFrontdoorBridgeUrlFromQrCode`, provide the scheme and host for the expected QR code log in URL format */
            let expectedScheme = "your-qr-code-login-url-scheme"
            let expectedHost = "your-qr-code-login-url-host"
            assert(expectedScheme != "your-qr-code-login-url-scheme", "Please add your login QR code URL's scheme.")
            assert(expectedHost != "your-qr-code-login-url-host", "Please add your login QR code URL's host.")
            /* To set up QR code log in using `loginWithFrontdoorBridgeUrlFromQrCode`, provide the path, parameter names and JSON keys for the expected QR code log in URL format */
            SalesforceLoginViewController.qrCodeLoginUrlPath = "your-qr-code-login-url-path"
            SalesforceLoginViewController.qrCodeLoginUrlJsonParameterName = "your-qr-code-login-url-json-parameter-name"
            SalesforceLoginViewController.qrCodeLoginUrlJsonFrontdoorBridgeUrlKey = "your-qr-code-login-url-json-frontdoor-bridge-url-key"
            SalesforceLoginViewController.qrCodeLoginUrlJsonPkceCodeVerifierKey = "your-qr-code-login-url-json-pkce-code-verifier-key"
            assert(SalesforceLoginViewController.qrCodeLoginUrlPath != "your-qr-code-login-url-path", "Please add your login QR code URL's path.")
            assert(SalesforceLoginViewController.qrCodeLoginUrlJsonParameterName != "your-qr-code-login-url-json-parameter-name", "Please add your login QR code URL's UI Bridge API JSON query string parameter name.")
            assert(SalesforceLoginViewController.qrCodeLoginUrlJsonFrontdoorBridgeUrlKey != "your-qr-code-login-url-json-frontdoor-bridge-url-key", "Please add your login QR code URL's UI Bridge API JSON frontdoor bridge URL key.")
            assert(SalesforceLoginViewController.qrCodeLoginUrlJsonPkceCodeVerifierKey != "your-qr-code-login-url-json-pkce-code-verifier-key", "Please add your login QR code URL's UI Bridge API JSON PKCE code verifier key.")
            
            // Log in using `loginWithFrontdoorBridgeUrlFromQrCode` if applicable
            guard let components = NSURLComponents(
                url: url,
                resolvingAgainstBaseURL: true),
                  let scheme = components.scheme,
                  scheme == expectedScheme,
                  let host = components.host,
                  host == expectedHost,
                  let path = components.path,
                  path == SalesforceLoginViewController.qrCodeLoginUrlPath,
                  let queryItems = components.queryItems,
                  let _ = queryItems.first(where: { $0.name == SalesforceLoginViewController.qrCodeLoginUrlJsonParameterName })?.value else {
                SFSDKCoreLogger().e(classForCoder, message: "Invalid QR code log in URL.")
                return
            }
            let _ = LoginTypeSelectionViewController.loginWithFrontdoorBridgeUrlFromQrCode(url.absoluteString)
        } else {
            
            /*
             * When using `loginWithFrontdoorBridgeUrl` and an entirely custom
             * QR code login URL format, set
             * `isAppExpectedReferenceQrCodeLoginUrlFormat` to `false` (or
             * remove it entirely) and implement URL handling in this block
             * before calling `loginWithFrontdoorBridgeUrl`.
             */
            
            /* To-do: Implement URL handling to retrieve UI Bridge API parameters */
            /* To set up QR code log in using `loginWithFrontdoorBridgeUrlFromQrCode`, provide the scheme and host for the expected QR code log in URL format */
            let frontdoorBridgeUrl = "your-qr-code-login-frontdoor-bridge-url"
            let pkceCodeVerifier = "your-qr-code-login-pkce-code-verifier"
            assert(frontdoorBridgeUrl != "your-qr-code-login-frontdoor-bridge-url", "Please implement your app's frontdoor bridge URL retrieval.")
            assert(pkceCodeVerifier != "your-qr-code-login-pkce-code-verifier", "Please add your app's PKCE code verifier retrieval if web server flow is used.")
            let _ = LoginTypeSelectionViewController.loginWithFrontdoorBridgeUrl(
                frontdoorBridgeUrl,
                pkceCodeVerifier: pkceCodeVerifier
            )
        }
    }
}
