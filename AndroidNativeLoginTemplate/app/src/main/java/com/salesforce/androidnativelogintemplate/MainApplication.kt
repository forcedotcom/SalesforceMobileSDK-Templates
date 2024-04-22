/*
 * Copyright (c) 2024-present, salesforce.com, inc.
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
package com.salesforce.androidnativelogintemplate

import android.app.Application
import com.google.android.material.color.DynamicColors
import com.google.android.recaptcha.Recaptcha
import com.google.android.recaptcha.RecaptchaAction.Companion.LOGIN
import com.google.android.recaptcha.RecaptchaClient
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.util.SalesforceSDKLogger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers.Default
import kotlinx.coroutines.launch

/**
 * Application class for our application.
 */
class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Pass NativeLogin class with initNative
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java, null, NativeLogin::class.java)
        MobileSyncSDKManager.getInstance().registerUsedAppFeature(FEATURE_APP_USES_KOTLIN)
        DynamicColors.applyToActivitiesIfAvailable(this)

        /**
         * Fill in the values below from the connected app that was created for Native Login and
         * the url of your Experience Cloud community.
         */
        val clientId = "your-client-id"
        val redirectUri = "your-redirect-uri"
        val loginUrl = "your-community-url"

        check(clientId != "your-client-id") { "Please add your Native Login client id." }
        check(redirectUri != "your-redirect-uri") { "Please add your Native Login redirect uri." }
        check(loginUrl != "your-community-url") { "Please add your Native Login community url." }

        // Register Username / Password Native Login
        MobileSyncSDKManager.getInstance().useNativeLogin(clientId, redirectUri, loginUrl)

        /*
         * To setup Password-less login:
         *
         * Un-comment the code block below and fill in the values from the
         * the Google Cloud project reCAPTCHA settings.  Note that only enterprise
         * reCAPTCHA requires the reCAPTCHA Site Key Id and Google Cloud Project Id.
         *
         * When using non-enterprise reCAPTCHA, set reCAPTCHA Site Key Id and
         * Google Cloud Project Id to nil along with a false value for the
         * enterprise parameter.
         */
//        val reCaptchaSiteKeyId = "your-recaptcha-site-key-id"
//        val googleCloudProjectId = "your-google-cloud-project-id"
//        val isReCaptchaEnterprise = true
//
//        check(reCaptchaSiteKeyId != "your-recaptcha-site-key-id") { "Please add your Google Cloud reCAPTCHA Site Key Id." }
//        check(googleCloudProjectId != "your-google-cloud-project-id") { "Please add your Google Cloud Project Id." }
//
//        initializeRecaptchaClient(
//            application = this,
//            reCaptchaSiteKeyId = reCaptchaSiteKeyId
//        )
//
//        // Register Password-less Native Login
//        MobileSyncSDKManager.getInstance().useNativeLogin(
//            consumerKey = clientId,
//            callbackUrl = redirectUri,
//            communityUrl = loginUrl,
//            googleCloudProjectId = googleCloudProjectId,
//            reCaptchaSiteKeyId = reCaptchaSiteKeyId,
//            isReCaptchaEnterprise = isReCaptchaEnterprise
//        )

        /*
		 * Un-comment the line below to enable push notifications in this app.
		 * Replace 'pnInterface' with your implementation of 'PushNotificationInterface'.
		 * Add your Firebase 'google-services.json' file to the 'app' folder of your project.
		 */
        // MobileSyncSDKManager.getInstance().pushNotificationReceiver = pnInterface
    }

    companion object {
        private const val FEATURE_APP_USES_KOTLIN = "KT"
        private const val TAG = "AndroidNativeLoginTemplate"

        // region Google reCAPTCHA Integration

        /** The reCAPTCHA client used to obtain reCAPTCHA tokens when needed for Salesforce Headless Identity API requests. */
        private var recaptchaClient: RecaptchaClient? = null

        /**
         * Initializes the Google reCAPTCHA client.
         * @param application The Android application
         * @param reCaptchaSiteKeyId The Google Cloud project reCAPTCHA Key's "Id"
         * as shown in Google Cloud Console under "Products & Solutions", "Security"
         * and "reCAPTCHA Enterprise"
         */
        private fun initializeRecaptchaClient(
            application: Application,
            @Suppress("SameParameterValue") reCaptchaSiteKeyId: String
        ) {
            CoroutineScope(Default).launch {
                Recaptcha.getClient(
                    application,
                    reCaptchaSiteKeyId
                ).onSuccess { client ->
                    recaptchaClient = client
                }.onFailure { exception ->
                    SalesforceSDKLogger.e(
                        TAG,
                        "Cannot get reCAPTCHA client due to an error.",
                        exception
                    )
                }
            }
        }

        /**
         * Executes the Google reCAPTCHA client for a new login action token.
         * @param completion The function to invoke with the new token or null
         * if the token could not be obtained
         */
        internal fun executeLoginAction(
            completion: (String?) -> Unit
        ) = CoroutineScope(Default).launch {
            recaptchaClient?.execute(LOGIN)
                ?.onSuccess { token ->
                    completion(token)
                }?.onFailure { exception ->
                    SalesforceSDKLogger.e(
                        TAG,
                        "Could not obtain a reCAPTCHA token due to error.",
                        exception
                    )
                    completion(null)
                }
        }
    }
}
