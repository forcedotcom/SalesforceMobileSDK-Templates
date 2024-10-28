/*
 * Copyright (c) 2022-present, salesforce.com, inc.
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
package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity

import android.content.Intent
import android.os.Bundle
import android.view.KeyEvent
import android.widget.Toast
import android.widget.Toast.LENGTH_SHORT
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.toComposeRect
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.lifecycle.*
import androidx.window.layout.WindowMetricsCalculator
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.smartstore.ui.SmartStoreInspectorActivity
import com.salesforce.androidsdk.ui.SalesforceActivityDelegate
import com.salesforce.androidsdk.ui.SalesforceActivityInterface
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.toWindowSizeClasses
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.DarkBackground
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.Purple40
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

/**
 * The realization of the following user task: "I want to view and edit the contacts in my Org."
 *
 * This Activity combines the Contacts List component and the Contact Details component to create a
 * list of contacts that the user can search through. They can then click on a contact to see its
 * full details and edit those details.
 */
class ContactsActivity
    : ComponentActivity(),
    SalesforceActivityInterface,
    ContactsActivityMenuHandler {

    private lateinit var vm: ContactsActivityViewModel
    private lateinit var salesforceActivityDelegate: SalesforceActivityDelegate

    private val vmBackPressedCallback = object : OnBackPressedCallback(false) {
        override fun handleOnBackPressed() {
            vm.handleBackClick()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private val vmFactory = object : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return DefaultContactsActivityViewModel() as T
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        vm = ViewModelProvider(this, vmFactory)[DefaultContactsActivityViewModel::class.java]
        salesforceActivityDelegate = SalesforceActivityDelegate(this).also { it.onCreate() }

        setContent {
            // Using LocalConfiguration.current as a key for remember allows recomposition when device configuration changes:
            val windowSize = remember(LocalConfiguration.current) {
                WindowMetricsCalculator.getOrCreate()
                    .computeCurrentWindowMetrics(this)
                    .bounds
                    .toComposeRect()
                    .size
            }
            val windowSizeClasses = with(LocalDensity.current) {
                windowSize.toDpSize().toWindowSizeClasses()
            }
            val backgroundColor = if (SalesforceSDKManager.getInstance().isDarkTheme) DarkBackground else Purple40

            SalesforceMobileSDKAndroidTheme {
                Box(modifier = Modifier
                    .background(backgroundColor)
                    .safeDrawingPadding()
                ) {
                    ContactsActivityContent(
                        activityUiInteractor = vm,
                        menuHandler = this@ContactsActivity,
                        windowSizeClasses = windowSizeClasses
                    )
                }
            }
        }

        // Coroutine to reactively enable/disable the VM back handling
        lifecycleScope.launch {
            repeatOnLifecycle(state = Lifecycle.State.RESUMED) {
                vm.isHandlingBackEvents.collect { vmBackPressedCallback.isEnabled = it }
            }
        }

        lifecycleScope.launch {
            repeatOnLifecycle(state = Lifecycle.State.RESUMED) {
                vm.messages.collect {
                    Toast.makeText(this@ContactsActivity, it.stringRes, LENGTH_SHORT)
                        .show()
                }
            }
        }

        onBackPressedDispatcher.addCallback(this, vmBackPressedCallback)
    }

    override fun onResume() {
        super.onResume()
        salesforceActivityDelegate.onResume(true)
    }

    override fun onDestroy() {
        salesforceActivityDelegate.onDestroy()
        super.onDestroy()
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        return salesforceActivityDelegate.onKeyUp(keyCode, event) || super.onKeyUp(keyCode, event)
    }

    override fun onResume(client: RestClient?) {
        val userAccount = MobileSyncSDKManager.getInstance().userAccountManager.currentUser
            ?: run {
                MobileSyncSDKManager.getInstance().logout(this)
                return
            }

        vm.switchUser(newUser = userAccount)
    }

    override fun onLogoutComplete() {}

    override fun onUserSwitched() {
        salesforceActivityDelegate.onResume(true)
    }

    override fun onInspectDbClick() {
        startActivity(
            SmartStoreInspectorActivity.getIntent(
                this@ContactsActivity,
                false,
                null
            )
        )
    }

    override fun onLogoutClick() {
        MobileSyncSDKManager.getInstance().logout(this)
    }

    override fun onSwitchUserClick() {
        val intent = Intent(this, SalesforceSDKManager.getInstance().accountSwitcherActivityClass)
            .apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }

        startActivity(intent)
    }

    override fun onSyncClick() {
        vm.fullSync()
    }

    companion object {
        const val COMPONENT_NAME = "ContactsActivity"
    }
}
