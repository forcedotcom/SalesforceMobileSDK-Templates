/*
 * Copyright (c) 2012-present, salesforce.com, inc.
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
package com.salesforce.androidnativeagentforcetemplate

import android.os.Bundle
import androidx.activity.compose.LocalOnBackPressedDispatcherOwner
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.LocalViewModelStoreOwner
import com.salesforce.android.agentforcesdkimpl.AgentforceClient
import com.salesforce.android.agentforcesdkimpl.AgentforceConversation
import com.salesforce.android.agentforcesdkimpl.configuration.AgentforceConfiguration
import com.salesforce.android.agentforceservice.AgentforceAuthCredentials
import com.salesforce.androidsdk.app.SalesforceSDKManager

class MainActivity : AppCompatActivity() {
    private val copilotClient = AgentforceClient()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // First, create your implementations of the required interfaces
        val network =
            AgentforceNetwork(SalesforceSDKManager.getInstance().clientManager.peekRestClient())
        val logger = AgentforceLogger() // Your implementation of Logger
        val navigation = AgentforceNavigation() // Your implementation of Navigation

        // Then create the configuration using the builder
        val configuration = AgentforceConfiguration.builder(
            authCredentialProvider =
                object : com.salesforce.android.agentforceservice.AgentforceAuthCredentialProvider {
                    override fun getAuthCredentials(): AgentforceAuthCredentials {
                        return AgentforceAuthCredentials(
                            authToken = SalesforceSDKManager.getInstance().userAccountManager.currentUser.authToken,
                            orgId = SalesforceSDKManager.getInstance().userAccountManager.currentUser.orgId,
                            userId = SalesforceSDKManager.getInstance().userAccountManager.currentUser.userId
                        )
                    }
                },
        ).setApplication(application)
            .setSalesforceDomain(SalesforceSDKManager.getInstance().userAccountManager.currentUser.instanceServer)
            .setNetwork(network)
            .setLogger(logger)
            .setNavigation(navigation)
            .build()

        // Initialize the client
        copilotClient.init(agentforceConfiguration = configuration)

        // Start the conversation
        copilotClient.startAgentforceConversation()

        // Create a new AgentforceConversation object
        val conversation = AgentforceConversation(
            configuration = configuration,
            conversationService = copilotClient.conversationService
        )

        // Display the conversation UI
        setContent {
            CompositionLocalProvider(
                LocalOnBackPressedDispatcherOwner provides this,
                LocalViewModelStoreOwner provides this
            ) {
                MaterialTheme {
                    Box(
                        modifier = Modifier
                            .safeDrawingPadding()
                            .fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        copilotClient.AgentforceConversationContainer(
                            conversation,
                            onClose = {
                            }
                        )
                    }
                }
            }
        }
    }
}
