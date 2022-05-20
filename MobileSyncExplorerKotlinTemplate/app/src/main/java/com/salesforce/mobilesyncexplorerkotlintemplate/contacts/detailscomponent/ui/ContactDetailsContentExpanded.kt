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
package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R.drawable.ic_undo
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.*
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsComponentClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.WINDOW_SIZE_MEDIUM_CUTOFF_DP
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactRecord

/**
 * Composable for the top app bar of the Contact Details component when the app window is in the
 * expanded size class.
 */
@Composable
fun RowScope.ContactDetailsTopBarContentExpanded(
    detailsUiState: ContactDetailsUiState,
    eventHandler: ContactDetailsComponentClickHandler
) {
    Spacer(modifier = Modifier.weight(1f))
    when (detailsUiState) {
        is ContactDetailsUiState.NoContactSelected -> {}
        is ContactDetailsUiState.ViewingContactDetails -> {
            if (detailsUiState.uiSyncState != SObjectUiSyncState.Deleted) {
                IconButton(onClick = eventHandler::deleteClick) {
                    Icon(
                        Icons.Default.Delete,
                        contentDescription = stringResource(id = cta_delete)
                    )
                }
            }
            when {
                detailsUiState.uiSyncState == SObjectUiSyncState.Deleted -> {
                    IconButton(onClick = eventHandler::undeleteClick) {
                        Icon(
                            painter = painterResource(id = ic_undo),
                            contentDescription = stringResource(id = cta_undelete)
                        )
                    }
                }
                detailsUiState.isEditingEnabled -> {
                    IconButton(onClick = eventHandler::saveClick) {
                        Icon(
                            Icons.Default.Check,
                            contentDescription = stringResource(id = cta_save)
                        )
                    }
                }
                else -> {
                    IconButton(onClick = eventHandler::editClick) {
                        Icon(
                            Icons.Default.Edit,
                            contentDescription = stringResource(id = cta_edit)
                        )
                    }
                }
            }
        }
    }
}

@Preview(showBackground = true, widthDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP)
@Composable
private fun ContactDetailsTopBarExpandedPreview() {
    val mockContact = ContactRecord(
        id = "1",
        syncState = SObjectSyncState.MatchesUpstream,
        sObject = ContactObject(
            firstName = "First",
            lastName = "Last",
            title = null,
            department = null
        )
    )
    SalesforceMobileSDKAndroidTheme {
        Surface {
            Column {
                Text("Viewing Mode:", modifier = Modifier.padding(top = 8.dp))
                TopAppBar(modifier = Modifier.padding(8.dp)) {
                    Text("Other Top App Bar Content")
                    ContactDetailsTopBarContentExpanded(
                        detailsUiState = mockContact.toPreviewViewingContactDetails(),
                        eventHandler = PREVIEW_CONTACT_DETAILS_UI_HANDLER
                    )
                }

                Text("Editing Mode:", modifier = Modifier.padding(top = 8.dp))
                TopAppBar(modifier = Modifier.padding(8.dp)) {
                    Text("Other Top App Bar Content")
                    ContactDetailsTopBarContentExpanded(
                        detailsUiState = mockContact.toPreviewViewingContactDetails(
                            isEditingEnabled = true
                        ),
                        eventHandler = PREVIEW_CONTACT_DETAILS_UI_HANDLER
                    )
                }

                Text("Locally Deleted:", modifier = Modifier.padding(top = 8.dp))
                TopAppBar(modifier = Modifier.padding(8.dp)) {
                    Text("Other Top App Bar Content")
                    ContactDetailsTopBarContentExpanded(
                        detailsUiState = mockContact.toPreviewViewingContactDetails(
                            uiSyncState = SObjectUiSyncState.Deleted
                        ),
                        eventHandler = PREVIEW_CONTACT_DETAILS_UI_HANDLER
                    )
                }

                Text("No Contact Selected:", modifier = Modifier.padding(top = 8.dp))
                TopAppBar(modifier = Modifier.padding(8.dp)) {
                    Text("Other Top App Bar Content")
                    ContactDetailsTopBarContentExpanded(
                        detailsUiState = ContactDetailsUiState.NoContactSelected(),
                        eventHandler = PREVIEW_CONTACT_DETAILS_UI_HANDLER
                    )
                }
            }
        }
    }
}
