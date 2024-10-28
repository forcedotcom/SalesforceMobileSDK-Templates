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
package com.salesforce.samples.salesforceandroididptemplateapp

import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView.OnItemClickListener
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TabHost
import android.widget.Toast
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import com.salesforce.samples.salesforceandroididptemplateapp.R.id.root
import com.salesforce.androidsdk.accounts.UserAccount
import com.salesforce.androidsdk.accounts.UserAccountManager
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.auth.idp.interfaces.IDPManager
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.rest.ApiVersionStrings
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.rest.RestClient.AsyncRequestCallback
import com.salesforce.androidsdk.rest.RestRequest
import com.salesforce.androidsdk.rest.RestResponse
import com.salesforce.androidsdk.ui.SalesforceActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.UnsupportedEncodingException
import java.util.*

/**
 * This activity represents the landing screen. It displays 2 tabs - 1 for apps
 * and the other for signed in users. It can be used to add users or launch
 * SP apps with the specified user to trigger login on the SP app.
 *
 * @author bhariharan
 */
class MainActivity : SalesforceActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val USERS_TAB = "Users"
        private const val APPS_TAB = "Apps"
        private const val ADD_NEW_USER = "Add New User"
        private const val MOBILE_SYNC_EXPLORER = "MobileSyncExplorer"
        private const val REST_EXPLORER = "RestExplorer"
        private const val ACCOUNT_EDITOR = "AccountEditor"
        private const val MOBILE_SYNC_EXPLORER_PACKAGE = "com.salesforce.samples.mobilesyncexplorer"
        private const val REST_EXPLORER_PACKAGE = "com.salesforce.samples.restexplorer"
        private const val ACCOUNT_EDITOR_PACKAGE = "com.salesforce.samples.accounteditor"
    }

    private var client: RestClient? = null
    private var usersListView: ListView? = null
    private var appsListView: ListView? = null
    private var currentUser: UserAccount? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val isDarkTheme = MobileSyncSDKManager.getInstance().isDarkTheme
        setTheme(if (isDarkTheme) R.style.SalesforceSDK_Dark else R.style.SalesforceSDK)
        MobileSyncSDKManager.getInstance().setViewNavigationVisibility(this)
        setContentView(R.layout.main)
        val tabHost = findViewById<TabHost>(R.id.tab_host)
        tabHost.setup()

        // Tab that displays list of users.
        val usersTabSpec: TabHost.TabSpec = tabHost.newTabSpec(USERS_TAB)
        usersTabSpec.setContent(R.id.users_tab)
        usersTabSpec.setIndicator(USERS_TAB)
        tabHost.addTab(usersTabSpec)

        // Tab that displays list of apps.
        val appsTabSpec = tabHost.newTabSpec(APPS_TAB)
        appsTabSpec.setContent(R.id.apps_tab)
        appsTabSpec.setIndicator(APPS_TAB)
        tabHost.addTab(appsTabSpec)

        // Getting a handle on list views.
        usersListView = findViewById(R.id.users_list)
        appsListView = findViewById(R.id.apps_list)

        // Setting click listeners for the list views.
        (usersListView as ListView).onItemClickListener = OnItemClickListener { _, _, position, _ -> handleUserListItemClick(position) }
        (appsListView as ListView).onItemClickListener = OnItemClickListener { _, _, position, _ -> handleAppsListItemClick(position) }

        // Fix UI being drawn behind status and navigation bars on Android 15
        if (SDK_INT > UPSIDE_DOWN_CAKE) {
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
        findViewById<ViewGroup>(R.id.root).visibility = View.INVISIBLE
        super.onResume()
    }

    override fun onResume(client: RestClient) {
        this.client = client
        currentUser = UserAccountManager.getInstance().currentUser
        findViewById<ViewGroup>(R.id.root).visibility = View.VISIBLE

        // Displays list of users available.
        usersListView?.adapter = ArrayAdapter(this,
                android.R.layout.simple_selectable_list_item, buildListOfUsers())

        // Displays list of apps available.
        appsListView?.adapter = ArrayAdapter(this, android.R.layout.simple_selectable_list_item,
                arrayListOf(MOBILE_SYNC_EXPLORER, REST_EXPLORER, ACCOUNT_EDITOR))
    }

    private fun buildListOfUsers(): List<String> {
        val users = UserAccountManager.getInstance().authenticatedUsers
        val usernames: MutableList<String> = mutableListOf()
        if (users != null) {
            for (user in users) {
                usernames.add(user.username)
            }
        }
        usernames.add(ADD_NEW_USER)
        return usernames
    }

    private fun getUserFromUsername(username: String?): UserAccount? {
        val users = UserAccountManager.getInstance().authenticatedUsers
        if (users != null) {
            for (user in users) {
                if (user.username.equals(username)) {
                    return user
                }
            }
        }
        return null
    }

    private fun handleUserListItemClick(position: Int) {
        val username = usersListView?.adapter?.getItem(position) as String
        Log.d(TAG, "User list item clicked, position: " + position + ", username: " + username)
        if (ADD_NEW_USER.equals(username)) {
            UserAccountManager.getInstance().switchToNewUser()
        } else {
            UserAccountManager.getInstance().switchToUser(getUserFromUsername(username))
            currentUser = UserAccountManager.getInstance().currentUser
        }
    }

    private fun handleAppsListItemClick(position: Int) {
        Log.d(TAG, "Apps list item clicked, position: " + position)
        val appName = appsListView?.adapter?.getItem(position) as String
        val spAppPackageName = when (appName) {
            MOBILE_SYNC_EXPLORER -> MOBILE_SYNC_EXPLORER_PACKAGE
            REST_EXPLORER -> REST_EXPLORER_PACKAGE
            ACCOUNT_EDITOR -> ACCOUNT_EDITOR_PACKAGE
            else -> null
        }
        Log.d(TAG, "Launching SP app ${appName} with package ${spAppPackageName}")
        if (spAppPackageName != null) {
            SalesforceSDKManager.getInstance().idpManager?.let { idpManager ->
                idpManager.kickOffIDPInitiatedLoginFlow(this, spAppPackageName,
                    object:IDPManager.StatusUpdateCallback {
                        override fun onStatusUpdate(status: IDPManager.Status) {
                            Log.d(TAG, "Got update ${status}")
                            CoroutineScope(Dispatchers.Main).launch {
                                Toast.makeText(
                                    applicationContext,
                                    getString(status.resIdForDescription),
                                    Toast.LENGTH_SHORT
                                ).show()
                            }
                        }
                    }
                )
            } ?: run {
                Log.e(TAG, "Cannot proceed with launch of ${appName} - not configured as IDP")
            }
        }
    }
}

