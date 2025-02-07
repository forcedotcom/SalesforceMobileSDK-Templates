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

import android.content.res.Configuration.UI_MODE_NIGHT_YES
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CornerSize
import androidx.compose.material.BottomAppBar
import androidx.compose.material.FabPosition
import androidx.compose.material.FloatingActionButton
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R.drawable.ic_undo
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_add_contact
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_back
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_delete
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_edit
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_save
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_undelete
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.label_contact_department
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.label_contact_first_name
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.label_contact_last_name
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.label_contact_title
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.ContactsActivityMenuButton
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.ContactsActivityMenuHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.SyncImage
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsComponentClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.LoadingOverlay
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.FormattedStringRes
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactRecord
import org.jetbrains.annotations.TestOnly

/**
 * Composable for when the Contact Details component should take up all space in the app. Acts like
 * a full screen Activity for interacting with contact details including viewing, editing, saving,
 * deleting, and undeleting.
 */
@Composable
fun ContactDetailsSinglePaneComponent(
    details: ContactDetailsUiState,
    showLoadingOverlay: Boolean,
    componentClickHandler: ContactDetailsComponentClickHandler,
    menuHandler: ContactsActivityMenuHandler,
    modifier: Modifier = Modifier,
) {
    val contactDetailsUi = details as? ContactDetailsUiState.ViewingContactDetails
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar {
                ContactDetailsTopAppBarSinglePane(
                    label = contactDetailsUi?.fullName ?: "",
                    syncIconContent = {
                        contactDetailsUi?.let {
                            SyncImage(uiSyncState = contactDetailsUi.uiSyncState)
                        }
                    },
                    onUpClick =
                    if (contactDetailsUi?.isEditingEnabled == true)
                        componentClickHandler::exitEditClick
                    else
                        componentClickHandler::deselectContactClick
                )

                ContactsActivityMenuButton(menuHandler = menuHandler)
            }
        },

        bottomBar = {
            BottomAppBar(cutoutShape = MaterialTheme.shapes.small.copy(CornerSize(percent = 50))) {
                if (contactDetailsUi != null) {
                    ContactDetailsBottomAppBarSinglePane(
                        showDelete = contactDetailsUi.uiSyncState != SObjectUiSyncState.Deleted,
                        detailsDeleteClick = componentClickHandler::deleteClick
                    )
                }
            }
        },
        floatingActionButtonPosition = FabPosition.Center,
        floatingActionButton = {
            ContactDetailsFab(uiState = details, handler = componentClickHandler)
        },
        isFloatingActionButtonDocked = true
    ) { paddingValues ->
        ContactDetailsComponentFormContent(
            modifier = Modifier.padding(paddingValues),
            details = details,
            contentPadding = PaddingValues(all = 8.dp)
        )

        if (showLoadingOverlay) {
            LoadingOverlay()
        }
    }
}


@Composable
private fun RowScope.ContactDetailsTopAppBarSinglePane(
    label: String,
    syncIconContent: @Composable () -> Unit,
    onUpClick: () -> Unit
) {
    IconButton(onClick = onUpClick) {
        Icon(
            Icons.AutoMirrored.Filled.ArrowBack,
            contentDescription = stringResource(id = content_desc_back)
        )
    }

    Text(
        label,
        modifier = Modifier.weight(1f),
        maxLines = 1,
        overflow = TextOverflow.Ellipsis
    )

    syncIconContent()
}

@Composable
private fun RowScope.ContactDetailsBottomAppBarSinglePane(
    showDelete: Boolean,
    detailsDeleteClick: () -> Unit
) {
    Spacer(modifier = Modifier.weight(1f))
    if (showDelete) {
        IconButton(onClick = detailsDeleteClick) {
            Icon(
                Icons.Default.Delete,
                contentDescription = stringResource(id = cta_delete)
            )
        }
    }
}

@Composable
private fun ContactDetailsFab(
    modifier: Modifier = Modifier,
    uiState: ContactDetailsUiState,
    handler: ContactDetailsComponentClickHandler
) {
    when (uiState) {
        is ContactDetailsUiState.ViewingContactDetails -> {
            when {
                uiState.uiSyncState == SObjectUiSyncState.Deleted ->
                    FloatingActionButton(
                        onClick = handler::undeleteClick,
                        modifier = modifier
                    ) {
                        Icon(
                            painter = painterResource(id = ic_undo),
                            contentDescription = stringResource(id = cta_undelete)
                        )
                    }

                uiState.isEditingEnabled ->
                    FloatingActionButton(
                        onClick = handler::saveClick,
                        modifier = modifier
                    ) {
                        Icon(
                            Icons.Default.Check,
                            contentDescription = stringResource(id = cta_save)
                        )
                    }

                else ->
                    FloatingActionButton(
                        onClick = handler::editClick,
                        modifier = modifier
                    ) {
                        Icon(
                            Icons.Default.Edit,
                            contentDescription = stringResource(id = cta_edit)
                        )
                    }
            }
        }

        is ContactDetailsUiState.NoContactSelected -> FloatingActionButton(
            onClick = handler::createClick,
            modifier = modifier
        ) {
            Icon(
                Icons.Default.Add,
                contentDescription = stringResource(id = content_desc_add_contact)
            )
        }
    }
}

@Preview(showBackground = true)
@Preview(showBackground = true, uiMode = UI_MODE_NIGHT_YES)
@Composable
private fun ContactDetailViewModePreview() {
    val contact = ContactRecord(
        id = "1",
        syncState = SObjectSyncState.MatchesUpstream,
        sObject = ContactObject(
            firstName = "FirstFirstFirstFirstFirstFirstFirstFirstFirstFirstFirstFirstFirst",
            lastName = "LastLastLastLastLastLastLastLastLastLastLastLastLastLastLastLast",
            title = "Titletitletitletitletitletitletitletitletitletitletitletitletitletitle",
            department = "DepartmentDepartmentDepartmentDepartmentDepartmentDepartmentDepartmentDepartmentDepartmentDepartment"
        )
    )

    SalesforceMobileSDKAndroidTheme {
        Surface(modifier = Modifier.fillMaxSize()) {
            ContactDetailsSinglePaneComponent(
                details = contact.toPreviewViewingContactDetails(),
                showLoadingOverlay = false,
                componentClickHandler = PREVIEW_CONTACT_DETAILS_UI_HANDLER,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
            )
        }
    }
}

@TestOnly
fun ContactRecord.toPreviewViewingContactDetails(
    uiSyncState: SObjectUiSyncState = SObjectUiSyncState.Updated,
    isEditingEnabled: Boolean = false,
    shouldScrollToErrorField: Boolean = false,
) = ContactDetailsUiState.ViewingContactDetails(
    recordId = id,
    firstNameField = EditableTextFieldUiState(
        fieldValue = sObject.firstName,
        onValueChange = {},
        isInErrorState = false,
        label = FormattedStringRes(label_contact_first_name),
        placeholder = FormattedStringRes(label_contact_first_name),
        helper = null,
        maxLines = 1u
    ),
    lastNameField = EditableTextFieldUiState(
        fieldValue = sObject.lastName,
        onValueChange = {},
        isInErrorState = false,
        label = FormattedStringRes(label_contact_last_name),
        placeholder = FormattedStringRes(label_contact_last_name),
        helper = null,
        maxLines = 1u
    ),
    titleField = EditableTextFieldUiState(
        fieldValue = sObject.title,
        onValueChange = {},
        isInErrorState = false,
        label = FormattedStringRes(label_contact_title),
        placeholder = FormattedStringRes(label_contact_title),
        helper = null
    ),
    departmentField = EditableTextFieldUiState(
        fieldValue = sObject.department,
        onValueChange = {},
        isInErrorState = false,
        label = FormattedStringRes(label_contact_department),
        placeholder = FormattedStringRes(label_contact_department),
        helper = null
    ),
    uiSyncState = uiSyncState,
    isEditingEnabled = isEditingEnabled,
    shouldScrollToErrorField = shouldScrollToErrorField,
)

val PREVIEW_CONTACT_DETAILS_UI_HANDLER = object : ContactDetailsComponentClickHandler {
    override fun createClick() {}
    override fun deleteClick() {}
    override fun undeleteClick() {}
    override fun deselectContactClick() {}
    override fun editClick() {}
    override fun exitEditClick() {}
    override fun saveClick() {}
}
