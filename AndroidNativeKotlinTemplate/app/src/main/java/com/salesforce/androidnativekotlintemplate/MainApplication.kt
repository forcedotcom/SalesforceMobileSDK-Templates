/*
 * Copyright (c) 2017-present, salesforce.com, inc.
 * All rights reserved.
 * Redistribution and use of this software in source and binary forms, with or
 * without modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * - Neither the name of salesforce.com, inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission of salesforce.com, inc.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package com.salesforce.androidnativekotlintemplate

import android.app.Application
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.ui.LoginActivity.Companion.qrCodeLoginUrlJsonFrontdoorBridgeUrlKey
import com.salesforce.androidsdk.ui.LoginActivity.Companion.qrCodeLoginUrlJsonParameterName
import com.salesforce.androidsdk.ui.LoginActivity.Companion.qrCodeLoginUrlJsonPkceCodeVerifierKey
import com.salesforce.androidsdk.ui.LoginActivity.Companion.qrCodeLoginUrlPath

/**
 * Application class for our application.
 */
class MainApplication : Application() {

    companion object {
        private const val FEATURE_APP_USES_KOTLIN = "KT"
    }

    // region Activity Implementation

    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(
            applicationContext,
            MainActivity::class.java,
            /*
             * Enable login via Salesforce UI Bridge API generated QR code using
             * a custom log in activity.
             */
            // Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes
            /*QrCodeEnabledLoginActivity::class.java*/
        )
        MobileSyncSDKManager.getInstance().registerUsedAppFeature(FEATURE_APP_USES_KOTLIN)

        /*
         * Uncomment the following line to enable IDP login flow. This will allow the user to
         * either authenticate using the current app or use the designated IDP app for login.
         * Replace 'com.salesforce.samples.salesforceandroididptemplateapp' with the package name
         * of the IDP app meant to be used.
         */
        // MobileSyncSDKManager.getInstance().idpAppPackageName = "com.salesforce.samples.salesforceandroididptemplateapp"

        /*
		 * Un-comment the line below to enable push notifications in this app.
		 * Replace 'pnInterface' with your implementation of 'PushNotificationInterface'.
		 * Add your Firebase 'google-services.json' file to the 'app' folder of your project.
		 */
        // MobileSyncSDKManager.getInstance().pushNotificationReceiver = pnInterface

        /* Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes. */
        //setupQrCodeLogin()
    }

    // endregion
    // region QR Code Login Via Salesforce Identity API UI Bridge Public Implementation

    /**
     * When enabling log in via Salesforce UI Bridge API generated QR codes, choose to use the
     * Salesforce Mobile SDK reference format for QR code login URLs or an entirely custom format.
     *
     * If only one of the two formats is used, which is the most likely implementation for apps using this
     * template, this variable and code related to the unused implementation could be removed.
     */
    internal var isQrCodeLoginUsingReferenceUrlFormat = true

    /**
     * When enabling log in via Salesforce UI Bridge API generated QR codes and using the reference QR
     * code log in URL format, the scheme for the expected QR code login URL format.
     */
    internal var qrCodeLoginUrlScheme = "your-qr-code-login-url-scheme"

    /**
     * When enabling log in via Salesforce UI Bridge API generated QR codes and using the reference QR
     * code log in URL format, the host for the expected QR code login URL format.
     */
    internal var qrCodeLoginUrlHost = "your-qr-code-login-url-host"

    // region QR Code Login Via Salesforce Identity API UI Bridge Private Implementation

    /**
     * Sets up QR code login.
     */
    private fun setupQrCodeLogin() {

        /*
         * When enabling log in via Salesforce UI Bridge API generated QR codes
         * and using the Salesforce Mobile SDK reference format for QR code log
         * in URLs, specify values for the string placeholders in this method to
         * control the parsing of QR code login URLs. The required UI Bridge
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
         * The reference QR code login URL format uses this structure where the
         * PKCE code verifier must be URL-Safe Base64 encoded and the overall
         * JSON content must be URL encoded:
         * [scheme]://[host]/[path]?[json-parameter-name]={[frontdoor-bridge-url-key]=<>,[pkce-code-verifier-key]=<>}
         *
         * Any URL link scheme supported by the native platform may be used.
         * This includes Android App Links and iOS Universal Links. Be certain
         * to follow the latest security practices documented by the app's
         * native platform.
         *
         * If using an entirely custom format for QR code login URLs, the
         * assignment of these strings can be safely removed.
         */
        // The scheme and host for the expected QR code log in URL format.
        check(qrCodeLoginUrlScheme != "your-qr-code-login-url-scheme") { "Please add your login QR code URL's scheme." }
        check(qrCodeLoginUrlHost != "your-qr-code-login-url-host") { "Please add your login QR code URL's host." }
        // The path, parameter names and JSON keys for the expected QR code log in URL format.
        qrCodeLoginUrlPath = "your-qr-code-login-url-path"
        qrCodeLoginUrlJsonParameterName = "your-qr-code-login-url-json-parameter-name"
        qrCodeLoginUrlJsonFrontdoorBridgeUrlKey = "your-qr-code-login-url-json-frontdoor-bridge-url-key"
        qrCodeLoginUrlJsonPkceCodeVerifierKey = "your-qr-code-login-url-json-pkce-code-verifier-key"
        check(qrCodeLoginUrlPath != "your-qr-code-login-url-path") { "Please add your login QR code URL's path." }
        check(qrCodeLoginUrlJsonParameterName != "your-qr-code-login-url-json-parameter-name") { "Please add your login QR code URL's UI Bridge API JSON query string parameter name." }
        check(qrCodeLoginUrlJsonFrontdoorBridgeUrlKey != "your-qr-code-login-url-json-frontdoor-bridge-url-key") { "Please add your login QR code URL's UI Bridge API JSON frontdoor bridge URL key." }
        check(qrCodeLoginUrlJsonPkceCodeVerifierKey != "your-qr-code-login-url-json-pkce-code-verifier-key") { "Please add your login QR code URL's UI Bridge API JSON PKCE code verifier key." }
    }

    // endregion
}
