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

import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.Toast
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import com.salesforce.androidnativelogintemplate.R.id.root
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.rest.ApiVersionStrings
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.rest.RestClient.AsyncRequestCallback
import com.salesforce.androidsdk.rest.RestRequest
import com.salesforce.androidsdk.rest.RestResponse
import com.salesforce.androidsdk.ui.SalesforceActivity
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
        val idDarkTheme = MobileSyncSDKManager.getInstance().isDarkTheme
        setTheme(if (idDarkTheme) R.style.SalesforceSDK_Dark else R.style.SalesforceSDK)
        MobileSyncSDKManager.getInstance().setViewNavigationVisibility(this)

        // Setup view
        setContentView(R.layout.main)

        // Fix UI being drawn behind status and navigation bars on Android 15
        if (SDK_INT > UPSIDE_DOWN_CAKE) {
            enableEdgeToEdge()
            ViewCompat.setOnApplyWindowInsetsListener(findViewById(root)) { listenerView, windowInsets ->
                val insets = windowInsets.getInsets(
                    WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
                )

                listenerView.updatePadding(insets.left, insets.top, insets.right, insets.bottom)
                WindowInsetsCompat.CONSUMED
            }
        }
    }

    override fun onResume() {
        // Hide everything until we are logged in
        findViewById<ViewGroup>(R.id.root).visibility = View.INVISIBLE

        // Create list adapter
        listAdapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, ArrayList<String>())
        findViewById<ListView>(R.id.contacts_list).adapter = listAdapter

        super.onResume()
    }

    override fun onResume(client: RestClient) {
        // Keeping reference to rest client
        this.client = client

        // Show everything
        findViewById<ViewGroup>(R.id.root).visibility = View.VISIBLE
    }

    /**
     * Called when "Logout" button is clicked.

     * @param v
     */
    @Suppress("UNUSED_PARAMETER")
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
                        for (i in 0..records.length() - 1) {
                            listAdapter!!.add(records.getJSONObject(i).getString("Name"))
                        }
                    } catch (e: Exception) {
                        onError(e)
                    }
                }
            }

            override fun onError(exception: Exception) {
                runOnUiThread {
                    Toast.makeText(
                        this@MainActivity,
                        this@MainActivity.getString(R.string.sf__generic_error, exception.toString()),
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        })
    }
}
