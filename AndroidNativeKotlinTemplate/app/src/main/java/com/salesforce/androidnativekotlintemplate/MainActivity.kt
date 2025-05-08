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
import android.os.Build.VERSION_CODES.TIRAMISU
import android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.annotation.RequiresApi
import androidx.core.view.ViewCompat.setOnApplyWindowInsetsListener
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsCompat.Type.displayCutout
import androidx.core.view.WindowInsetsCompat.Type.systemBars
import androidx.core.view.updatePadding
import com.salesforce.androidnativekotlintemplate.R.id.root
import com.salesforce.androidnativekotlintemplate.R.raw.asf_api_client_transcription_demo_input
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.auth.HttpAccess.DEFAULT
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.rest.AgentforceSpeechFoundationsApiClient
import com.salesforce.androidsdk.rest.ApiVersionStrings
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.rest.RestClient.AsyncRequestCallback
import com.salesforce.androidsdk.rest.RestClient.ClientInfo
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers.Default
import kotlinx.coroutines.Dispatchers.IO
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.Response
import okhttp3.WebSocket
import okhttp3.WebSocketListener
import okio.ByteString
import okio.ByteString.Companion.toByteString
import java.io.InputStream
import java.io.UnsupportedEncodingException
import java.lang.System.arraycopy
import java.nio.ByteBuffer.allocate
import java.nio.ByteBuffer.wrap
import java.util.*
import java.util.Arrays.copyOfRange
import kotlin.math.min
import kotlin.text.Charsets.UTF_8

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

    @RequiresApi(TIRAMISU)
    override fun onResume(client: RestClient?) {
        // Keeping reference to rest client
        this.client = client

        // Show everything
        findViewById<ViewGroup>(root).visibility = View.VISIBLE

        // Launch to ASF API client demo.
        client?.let { restClientUnwrapped ->
            // Use a custom REST client, optionally with a custom access token and access token refresh disabled.
            val restClientCustomAccessToken = RestClient(
                restClientUnwrapped.clientInfo.run /* Copy */ {
                    ClientInfo(
                        instanceUrl,
                        loginUrl,
                        identityUrl,
                        accountName,
                        username,
                        userId,
                        orgId + "_custom_access_token", // TODO: Inquire if there's another way to circumvent the cached OAuth interceptors in RestClient.setOAuthRefreshInterceptor(authToken). ECJ20250507
                        communityId,
                        communityUrl,
                        firstName,
                        lastName,
                        displayName,
                        email,
                        photoUrl,
                        thumbnailUrl,
                        additionalOauthValues,
                        lightningDomain,
                        lightningSid,
                        vfDomain,
                        vfSid,
                        contentDomain,
                        contentSid,
                        csrfToken
                    )
                },
                restClientUnwrapped.authToken /* For testing just hard-code the current user's access token.  Any access can be provided here */,
                DEFAULT,
                null /* A null authorization token provider disables automatic token refresh on 400-series response status codes */
            )

            startAsfApiClientTranscriptionsDemo(restClientCustomAccessToken /*restClientUnwrapped*/)
        }
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
    // region Agentforce Speech Foundations API Client Demo

    /**
     * Starts the Agentforce Speech Foundations API client demo.
     */
    @RequiresApi(TIRAMISU)
    private fun startAsfApiClientTranscriptionsDemo(
        restClient: RestClient
    ) = CoroutineScope(Default).launch {

        // Open the web socket.
        val webSocket = AgentforceSpeechFoundationsApiClient(
            apiHostName = "api.salesforce.com",
            modelName = "transcribeV1",
            restClient = restClient,
        ).openStreamingTranscriptionsWebSocket(AsfApiClientTranscriptionsDemoWebSocketListener())

        // Send the test audio file.
        sendAudioStream(
            webSocket,
            resources.openRawResource(asf_api_client_transcription_demo_input)
        )
    }

    @RequiresApi(TIRAMISU)
    private suspend fun sendAudioStream(
        webSocket: WebSocket,
        inputStreamPcm16KHzAudio: InputStream
    ) = withContext(IO) {
        val bytes = inputStreamPcm16KHzAudio.readAllBytes()

        val chunkSize = 4096
        var chunkStartOffset = 0
        while (chunkStartOffset < bytes.size) {
            val chunkEndOffset = min(
                (chunkStartOffset + chunkSize).toDouble(),
                bytes.size.toDouble()
            ).toInt()
            val chunk = copyOfRange(bytes, chunkStartOffset, chunkEndOffset)
            val fullSizedChunk = ByteArray(chunkSize)
            arraycopy(chunk, 0, fullSizedChunk, 0, chunk.size)

            webSocket.send(wrap(fullSizedChunk).toByteString())

            delay(128)

            chunkStartOffset += chunkSize
        }
        webSocket.send(allocate(0).toByteString())
    }

    // endregion
}

// region Agentforce Speech Foundations API Client Demo Web Socket Listeners

/**
 * A websocket listener for the ASF API client transcriptions demo.
 */
private class AsfApiClientTranscriptionsDemoWebSocketListener : WebSocketListener() {

    override fun onClosed(
        webSocket: WebSocket,
        code: Int,
        reason: String,
    ) {
        super.onClosed(webSocket, code, reason)

        Log.i("AsfApiClientTranscriptionsDemo", "Closed: '$code', '$reason'.")
    }

    override fun onClosing(
        webSocket: WebSocket,
        code: Int,
        reason: String,
    ) {
        super.onClosing(webSocket, code, reason)

        Log.i("AsfApiClientTranscriptionsDemo", "Closing: '$code', '$reason'.")
    }

    override fun onFailure(
        webSocket: WebSocket,
        t: Throwable,
        response: Response?,
    ) {
        super.onFailure(webSocket, t, response)

        Log.e("AsfApiClientTranscriptionsDemo", "Failure: '${response?.body?.string()}'.", t)
    }

    override fun onMessage(
        webSocket: WebSocket,
        text: String,
    ) {
        super.onMessage(webSocket, text)

        Log.i("AsfApiClientTranscriptionsDemo", "Message: Text: '$text'.")
    }

    override fun onMessage(
        webSocket: WebSocket,
        bytes: ByteString,
    ) {
        super.onMessage(webSocket, bytes)

        Log.i("AsfApiClientTranscriptionsDemo", "Message: Bytes: '${bytes.string(UTF_8)}'.")
    }

    override fun onOpen(
        webSocket: WebSocket,
        response: Response,
    ) {
        super.onOpen(webSocket, response)

        Log.i("AsfApiClientTranscriptionsDemo", "Open: '${response.body?.string()}'.")
    }
}

// endregion
