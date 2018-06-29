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

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView.OnItemClickListener
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TabHost
import com.salesforce.androidsdk.accounts.UserAccount
import com.salesforce.androidsdk.accounts.UserAccountManager
import com.salesforce.androidsdk.auth.idp.IDPInititatedLoginReceiver
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.ui.SalesforceActivity

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
        private const val SMART_SYNC_EXPLORER = "SmartSyncExplorer"
        private const val REST_EXPLORER = "RestExplorer"
        private const val ACCOUNT_EDITOR = "AccountEditor"
        private const val SMART_SYNC_EXPLORER_PACKAGE = "com.salesforce.samples.smartsyncexplorer"
        private const val REST_EXPLORER_PACKAGE = "com.salesforce.samples.restexplorer"
        private const val ACCOUNT_EDITOR_PACKAGE = "com.salesforce.samples.accounteditor"
        private const val SMART_SYNC_COMPONENT_NAME = "MainActivity"
        private const val REST_EXPLORER_COMPONENT_NAME = "ExplorerActivity"
        private const val ACCOUNT_EDITOR_COMPONENT_NAME = "SalesforceDroidGapActivity"
        private const val COLON = ":"
    }

    private var client: RestClient? = null
    private var usersListView: ListView? = null
    private var appsListView: ListView? = null
    private var currentUser: UserAccount? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
        usersListView = findViewById<ListView>(R.id.users_list)
        appsListView = findViewById<ListView>(R.id.apps_list)

        // Setting click listeners for the list views.
        (usersListView as ListView).onItemClickListener = OnItemClickListener { _, _, position, _ -> handleUserListItemClick(position) }
        (appsListView as ListView).onItemClickListener = OnItemClickListener { _, _, position, _ -> handleAppsListItemClick(position) }
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
        val users = UserAccountManager.getInstance().authenticatedUsers
        usersListView?.adapter = ArrayAdapter(this,
                android.R.layout.simple_selectable_list_item, buildListOfUsers())

        // Displays list of apps available.
        appsListView?.adapter = ArrayAdapter(this, android.R.layout.simple_selectable_list_item,
                arrayListOf(SMART_SYNC_EXPLORER, REST_EXPLORER, ACCOUNT_EDITOR))
    }

    private fun buildListOfUsers(): List<String>? {
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
        var appPackageName = ""
        var appComponentName = ""
        when (appName) {
            SMART_SYNC_EXPLORER -> {
                appPackageName = SMART_SYNC_EXPLORER_PACKAGE
                appComponentName = SMART_SYNC_COMPONENT_NAME
            }
            REST_EXPLORER -> {
                appPackageName = REST_EXPLORER_PACKAGE
                appComponentName = REST_EXPLORER_COMPONENT_NAME
            }
            ACCOUNT_EDITOR -> {
                appPackageName = ACCOUNT_EDITOR_PACKAGE
                appComponentName = ACCOUNT_EDITOR_COMPONENT_NAME
            }
        }
        Log.d(TAG, "App being launched: " + appName + ", package name: " + appPackageName)
        val intent = Intent(IDPInititatedLoginReceiver.IDP_LOGIN_REQUEST_ACTION)
        intent.addCategory(Intent.CATEGORY_DEFAULT)

        // Limiting intent to the target app's package.
        intent.`package` = appPackageName

        // Adding user hint and target component.
        intent.putExtra(IDPInititatedLoginReceiver.USER_HINT_KEY, currentUser?.orgId + COLON + currentUser?.userId)
        intent.putExtra(IDPInititatedLoginReceiver.SP_ACTVITY_NAME_KEY, appComponentName)
        sendBroadcast(intent)
    }
}
