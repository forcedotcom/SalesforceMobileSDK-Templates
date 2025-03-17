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

import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP
import android.net.Uri
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat.setOnApplyWindowInsetsListener
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsCompat.Type.displayCutout
import androidx.core.view.WindowInsetsCompat.Type.systemBars
import androidx.core.view.updatePadding
import com.salesforce.androidnativekotlintemplate.R.id.root
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.rest.ApiVersionStrings
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.rest.RestClient.AsyncRequestCallback
import com.salesforce.androidsdk.rest.RestRequest
import com.salesforce.androidsdk.rest.RestResponse
import com.salesforce.androidsdk.ui.LoginActivity
import com.salesforce.androidsdk.ui.LoginActivity.Companion.EXTRA_KEY_FRONTDOOR_BRIDGE_URL
import com.salesforce.androidsdk.ui.LoginActivity.Companion.EXTRA_KEY_PKCE_CODE_VERIFIER
import com.salesforce.androidsdk.ui.LoginActivity.Companion.isQrCodeLoginUrlIntent
import com.salesforce.androidsdk.ui.LoginActivity.Companion.qrCodeLoginUrlJsonParameterName
import com.salesforce.androidsdk.ui.LoginActivity.Companion.qrCodeLoginUrlPath
import com.salesforce.androidsdk.ui.SalesforceActivity
import com.salesforce.androidsdk.util.SalesforceSDKLogger.e
import java.io.UnsupportedEncodingException
import java.util.*

/**
 * Main activity
 */
class MainActivity : SalesforceActivity() {

    private var client: RestClient? = null
    private var listAdapter: ArrayAdapter<String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set Theme
        val isDarkTheme = MobileSyncSDKManager.getInstance().isDarkTheme
        setTheme(if (isDarkTheme) R.style.SalesforceSDK_Dark else R.style.SalesforceSDK)
        MobileSyncSDKManager.getInstance().setViewNavigationVisibility(this)

        // Setup view
        setContentView(R.layout.main)

        // Fix UI being drawn behind status and navigation bars on Android 15
        if (SDK_INT > UPSIDE_DOWN_CAKE) {
            enableEdgeToEdge()
            setOnApplyWindowInsetsListener(findViewById(root)) { listenerView, windowInsets ->
                val insets = windowInsets.getInsets(
                    systemBars() or displayCutout()
                )

                listenerView.updatePadding(insets.left, insets.top, insets.right, insets.bottom)
                WindowInsetsCompat.CONSUMED
            }
        }
    }

    override fun onResume() {
        // Hide everything until we are logged in
        findViewById<ViewGroup>(root).visibility = View.INVISIBLE

        // Create list adapter
        listAdapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, ArrayList())
        findViewById<ListView>(R.id.contacts_list).adapter = listAdapter

        // Check for and use the intent's QR code login URL if applicable.
        // Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes
        //intent.data?.let { useQrCodeLogInUrl(it) }

        super.onResume()
    }

    override fun onResume(client: RestClient?) {
        // Keeping reference to rest client
        this.client = client

        // Show everything
        findViewById<ViewGroup>(root).visibility = View.VISIBLE
    }

    /**
     * Called when "Logout" button is clicked.

     * @param v
     */
    @Suppress("UNUSED", "UNUSED_PARAMETER")
    fun onLogoutClick(v: View) {
        SalesforceSDKManager.getInstance().logout(this)
    }

    /**
     * Called when "Clear" button is clicked.

     * @param v
     */
    @Suppress("UNUSED_PARAMETER")
    fun onClearClick(v: View) {
        listAdapter!!.clear()
    }

    /**
     * Called when "Fetch Contacts" button is clicked

     * @param v
     * *
     * @throws UnsupportedEncodingException
     */
    @Throws(UnsupportedEncodingException::class)
    @Suppress("UNUSED_PARAMETER")
    fun onFetchContactsClick(v: View) {
        sendRequest("SELECT Name FROM Contact")
    }

    /**
     * Called when "Fetch Accounts" button is clicked.
     *
     * @param v
     * @throws UnsupportedEncodingException
     */
    @Throws(UnsupportedEncodingException::class)
    @Suppress("UNUSED_PARAMETER")
    fun onFetchAccountsClick(v: View) {
        sendRequest("SELECT Name FROM Account")
    }

    @Throws(UnsupportedEncodingException::class)
    private fun sendRequest(soql: String) {
        val restRequest = RestRequest.getRequestForQuery(ApiVersionStrings.getVersionNumber(this), soql)

        client!!.sendAsync(restRequest, object : AsyncRequestCallback {
            override fun onSuccess(request: RestRequest, result: RestResponse) {
                result.consumeQuietly() // consume before going back to main thread
                runOnUiThread {
                    try {
                        listAdapter!!.clear()
                        val records = result.asJSONObject().getJSONArray("records")
                        for (i in 0..<records.length()) {
                            listAdapter!!.add(records.getJSONObject(i).getString("Name"))
                        }
                    } catch (e: Exception) {
                        onError(e)
                    }
                }
            }

            override fun onError(exception: Exception) {
                runOnUiThread {
                    Toast.makeText(this@MainActivity,
                            this@MainActivity.getString(R.string.sf__generic_error, exception.toString()),
                            Toast.LENGTH_LONG).show()
                }
            }
        })
    }

    // region QR Code Login Via Salesforce Identity API UI Bridge Public Implementation

    /**
     * Validates and uses the intent's QR code login URL.
     * @param url The QR code login URL
     */
    @Suppress("KotlinConstantConditions", "UNUSED")
    private fun useQrCodeLogInUrl(url: Uri) {
        isBuildRestClientOnResumeEnabled = true

        val app = application as? MainApplication ?: return
        if (!isQrCodeLoginUrlIntent(intent)) return

        // While using a QR Code Login URL, disable the default login activity.
        isBuildRestClientOnResumeEnabled = false

        // Use the specified QR code login URL format.
        if (app.isQrCodeLoginUsingReferenceUrlFormat) {

            // Log in using `loginWithFrontdoorBridgeUrlFromQrCode` if applicable
            if (url.scheme != app.qrCodeLoginUrlScheme
                || url.host != app.qrCodeLoginUrlHost
                || url.path != qrCodeLoginUrlPath
                || !url.queryParameterNames.contains(qrCodeLoginUrlJsonParameterName)
            ) {
                e(javaClass.name, "Invalid QR code login URL.")
                isBuildRestClientOnResumeEnabled = true
                return
            }
            startActivity(
                Intent(
                    this@MainActivity,
                    LoginActivity::class.java
                ).apply {
                    data = url
                })
        } else {

            /*
             * When using `loginWithFrontdoorBridgeUrl` and an entirely custom
             * QR code login URL format, set
             * `isAppExpectedReferenceQrCodeLoginUrlFormat` to `false` (or
             * remove it entirely) and implement URL handling in this block
             * before calling `loginWithFrontdoorBridgeUrl`.
             */

            /* To-do: Implement URL handling to retrieve UI Bridge API parameters */
            /* To set up QR code login using `loginWithFrontdoorBridgeUrlFromQrCode`, provide the scheme and host for the expected QR code login URL format */
            val frontdoorBridgeUrl = "your-qr-code-login-frontdoor-bridge-url"
            val pkceCodeVerifier = "your-qr-code-login-pkce-code-verifier"
            check(frontdoorBridgeUrl != "your-qr-code-login-frontdoor-bridge-url") { "Please implement your app's frontdoor bridge URL retrieval." }
            check(pkceCodeVerifier != "your-qr-code-login-pkce-code-verifier") { "Please add your app's PKCE code verifier retrieval if web server flow is used." }

            startActivity(Intent(
                this,
                LoginActivity::class.java
            ).apply {
                putExtra(EXTRA_KEY_FRONTDOOR_BRIDGE_URL, frontdoorBridgeUrl)
                putExtra(EXTRA_KEY_PKCE_CODE_VERIFIER, pkceCodeVerifier)
                flags = FLAG_ACTIVITY_SINGLE_TOP
            })
        }

        // Clear the intent data so that the QR code login URL is used only once.
        intent.data = null
    }

    // endregion
}
