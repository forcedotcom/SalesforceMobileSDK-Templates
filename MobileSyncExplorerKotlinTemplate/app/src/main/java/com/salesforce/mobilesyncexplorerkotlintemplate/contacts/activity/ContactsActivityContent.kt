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

import android.content.res.Configuration.UI_MODE_NIGHT_YES
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateIntAsState
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.BottomAppBar
import androidx.compose.material.DropdownMenu
import androidx.compose.material.DropdownMenuItem
import androidx.compose.material.FabPosition
import androidx.compose.material.FloatingActionButton
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.Scaffold
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_add_contact
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_cancel_edit
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_item_deleted_locally
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_item_saved_locally
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_item_synced
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_menu
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_not_saved
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_inspect_db
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_logout
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_search
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_switch_user
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_sync
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.label_contacts
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsComponentClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ui.ContactDetailsComponentFormContent
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ui.ContactDetailsSinglePaneComponent
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ui.ContactDetailsTopBarContentExpanded
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ui.toPreviewViewingContactDetails
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ui.ContactsListComponentListContent
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ui.ContactsListSinglePaneComponent
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.LoadingOverlay
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.FormattedStringRes
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.WINDOW_SIZE_COMPACT_CUTOFF_DP
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.WINDOW_SIZE_MEDIUM_CUTOFF_DP
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.WindowSizeClass
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.WindowSizeClasses
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.MIN_TOUCH_TARGET_SIZE_DP
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.emptyFlow
import org.jetbrains.annotations.TestOnly

/**
 * The main entry point for all Contacts Activity UI.
 */
@Composable
fun ContactsActivityContent(
    activityUiInteractor: ContactsActivityUiInteractor,
    menuHandler: ContactsActivityMenuHandler,
    windowSizeClasses: WindowSizeClasses
) {
    val detailsUiState by activityUiInteractor.detailsUiState.collectAsState()
    val listUiState by activityUiInteractor.listUiState.collectAsState()
    val activityUiState by activityUiInteractor.activityUiState.collectAsState()

    // Use the provided window size class to determine high-level Activity layout:
    when (windowSizeClasses.toContactsActivityContentLayout()) {
        ContactsActivityContentLayout.SinglePane -> SinglePane(
            activityUiState = activityUiState,
            detailsUiState = detailsUiState,
            detailsClickHandler = activityUiInteractor.detailsClickHandler,
            listUiState = listUiState,
            listClickHandler = activityUiInteractor.listClickHandler,
            menuHandler = menuHandler
        )

        ContactsActivityContentLayout.ListDetail -> ListDetail(
            activityUiState = activityUiState,
            detailsUiState = detailsUiState,
            detailsClickHandler = activityUiInteractor.detailsClickHandler,
            listUiState = listUiState,
            listClickHandler = activityUiInteractor.listClickHandler,
            menuHandler = menuHandler,
            windowSizeClasses = windowSizeClasses
        )
    }

    activityUiState.dialogUiState?.RenderDialog(modifier = Modifier)
}

@Composable
private fun SinglePane(
    activityUiState: ContactsActivityUiState,
    detailsUiState: ContactDetailsUiState,
    detailsClickHandler: ContactDetailsComponentClickHandler,
    listUiState: ContactsListUiState,
    listClickHandler: ContactsListClickHandler,
    menuHandler: ContactsActivityMenuHandler,
) {
    val showLoading = activityUiState.dataOpIsActive || activityUiState.isSyncing

    // If the user is viewing contact details then only show the details component in single pane
    // mode; else show the list component. This acts like a back stack even though there are no
    // Fragment transactions or navigation.

    when (detailsUiState) {
        is ContactDetailsUiState.ViewingContactDetails -> ContactDetailsSinglePaneComponent(
            details = detailsUiState,
            showLoadingOverlay = showLoading,
            componentClickHandler = detailsClickHandler,
            menuHandler = menuHandler
        )

        else -> ContactsListSinglePaneComponent(
            uiState = listUiState,
            showLoading = showLoading,
            listClickHandler = listClickHandler,
            menuHandler = menuHandler
        )
    }
}

@Composable
private fun ListDetail(
    activityUiState: ContactsActivityUiState,
    detailsUiState: ContactDetailsUiState,
    detailsClickHandler: ContactDetailsComponentClickHandler,
    listUiState: ContactsListUiState,
    listClickHandler: ContactsListClickHandler,
    menuHandler: ContactsActivityMenuHandler,
    windowSizeClasses: WindowSizeClasses
) {
    Scaffold(
        topBar = {
            TopAppBar {
                when (detailsUiState) {
                    is ContactDetailsUiState.NoContactSelected -> Text(stringResource(id = label_contacts))
                    is ContactDetailsUiState.ViewingContactDetails -> {
                        SyncImage(uiSyncState = detailsUiState.uiSyncState)
                        Text(detailsUiState.fullName)
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                ContactDetailsTopBarContentExpanded(
                    detailsUiState = detailsUiState,
                    eventHandler = detailsClickHandler
                )
            }
        },
        bottomBar = {
            BottomAppBar {
                Spacer(modifier = Modifier.weight(1f))
                ContactsActivityMenuButton(menuHandler = menuHandler)
            }
        },
        floatingActionButton = {
            FloatingActionButton(onClick = detailsClickHandler::createClick) {
                Icon(
                    Icons.Default.Add,
                    contentDescription = stringResource(id = content_desc_add_contact)
                )
            }
        },
        floatingActionButtonPosition = FabPosition.End,
        isFloatingActionButtonDocked = false
    ) { paddingVals ->
        val evenSplit = windowSizeClasses.horiz != WindowSizeClass.Expanded
        val topPadding = paddingVals.calculateTopPadding()
        val bottomPadding = paddingVals.calculateBottomPadding()

        // Entire Activity is implemented as a single row with two columns -- one for the list and
        // one for the details:
        Row(modifier = Modifier.fillMaxSize()) {
            val listModifier: Modifier
            val detailModifier: Modifier

            if (evenSplit) {
                listModifier = Modifier.weight(0.5f)
                detailModifier = Modifier.weight(0.5f)
            } else {
                listModifier = Modifier.width((WINDOW_SIZE_MEDIUM_CUTOFF_DP / 2).dp)
                detailModifier = Modifier.weight(1f)
            }

            Column(modifier = listModifier.padding(top = topPadding, bottom = bottomPadding)) {
                ContactsListComponentListContent(
                    modifier = Modifier.fillMaxSize(),
                    uiState = listUiState,
                    listClickHandler = listClickHandler,
                )
            }

            Column(modifier = detailModifier.padding(top = topPadding, bottom = bottomPadding)) {
                ListDetailContactDetailsContent(
                    detailsUiState = detailsUiState,
                    onExitClick = detailsClickHandler::exitEditClick
                )
            }
        }

        if (activityUiState.dataOpIsActive || activityUiState.isSyncing) {
            LoadingOverlay()
        }
    }
}

@Composable
private fun ListDetailContactDetailsContent(
    detailsUiState: ContactDetailsUiState,
    onExitClick: () -> Unit
) {
    val isEditing = detailsUiState is ContactDetailsUiState.ViewingContactDetails
            && detailsUiState.isEditingEnabled

    val clearButtonPaddingDp = 4
    val topPadding by animateIntAsState(targetValue = if (isEditing) MIN_TOUCH_TARGET_SIZE_DP + clearButtonPaddingDp else 8)

    Box(modifier = Modifier.fillMaxSize()) {
        ContactDetailsComponentFormContent(
            details = detailsUiState,
            modifier = Modifier
                .animateContentSize()
                .fillMaxSize()
                .padding(horizontal = 8.dp),
            contentPadding = PaddingValues(top = topPadding.dp)
        )

        AnimatedVisibility(
            visible = isEditing,
            modifier = Modifier
                .padding(clearButtonPaddingDp.dp)
                .align(Alignment.TopEnd)
        ) {
            IconButton(onClick = onExitClick) {
                Icon(
                    Icons.Default.Close,
                    contentDescription = stringResource(id = content_desc_cancel_edit)
                )
            }
        }
    }
}

@Composable
fun ContactsActivityMenuButton(
    modifier: Modifier = Modifier,
    menuHandler: ContactsActivityMenuHandler
) {
    var menuExpanded by remember { mutableStateOf(false) }

    IconButton(modifier = modifier, onClick = { menuExpanded = !menuExpanded }) {
        Icon(
            Icons.Default.MoreVert,
            contentDescription = stringResource(id = content_desc_menu)
        )

        DropdownMenu(expanded = menuExpanded, onDismissRequest = { menuExpanded = false }) {
            DropdownMenuItem(onClick = { menuExpanded = false; menuHandler.onSyncClick() }) {
                Text(stringResource(id = cta_sync))
            }

            DropdownMenuItem(onClick = { menuExpanded = false; menuHandler.onSwitchUserClick() }) {
                Text(stringResource(id = cta_switch_user))
            }

            DropdownMenuItem(onClick = { menuExpanded = false; menuHandler.onLogoutClick() }) {
                Text(stringResource(id = cta_logout))
            }

            DropdownMenuItem(onClick = { menuExpanded = false; menuHandler.onInspectDbClick() }) {
                Text(stringResource(id = cta_inspect_db))
            }
        }
    }
}

/**
 * The Composable for rendering an icon corresponding to the provided [uiSyncState].
 */
@Composable
fun SyncImage(modifier: Modifier = Modifier, uiSyncState: SObjectUiSyncState) {
    when (uiSyncState) {
        SObjectUiSyncState.NotSaved -> Icon(
            Icons.Default.Star,
            contentDescription = stringResource(id = content_desc_not_saved)
        )

        SObjectUiSyncState.Deleted -> Icon(
            Icons.Default.Delete,
            contentDescription = stringResource(id = content_desc_item_deleted_locally),
            modifier = modifier
        )

        SObjectUiSyncState.Updated -> Image(
            painter = painterResource(id = R.drawable.sync_local),
            contentDescription = stringResource(id = content_desc_item_saved_locally),
            modifier = modifier
        )

        SObjectUiSyncState.Synced -> Image(
            painter = painterResource(id = R.drawable.sync_save),
            contentDescription = stringResource(id = content_desc_item_synced),
            modifier = modifier
        )
    }
}

/**
 * The different top-level UI configurations for the [ContactsActivity]
 */
private enum class ContactsActivityContentLayout {
    SinglePane,
    ListDetail
}

private fun WindowSizeClasses.toContactsActivityContentLayout() = when (horiz) {
    WindowSizeClass.Compact -> ContactsActivityContentLayout.SinglePane
    WindowSizeClass.Medium,
    WindowSizeClass.Expanded -> ContactsActivityContentLayout.ListDetail
}

@Preview(showBackground = true)
@Composable
private fun SinglePaneListPreview() {
    val contacts = (1..100).map { it.toString() }.map {
        SObjectRecord(
            id = it,
            syncState = SObjectSyncState.MatchesUpstream,
            sObject = ContactObject(
                firstName = "First $it",
                lastName = "Last $it",
                title = "Title $it",
                department = "Department $it"
            )
        )
    }

    val detailsVm = PreviewDetailsComponentVm(
        uiState = ContactDetailsUiState.NoContactSelected()
    )

    val listVm = PreviewListVm(
        uiState = ContactsListUiState(
            contacts = contacts,
            curSelectedContactId = null,
            isDoingInitialLoad = false,
            isDoingDataAction = false,
            isSearchJobRunning = false,
            searchField = previewContactListSearchField(
                fieldValue = null,
                onValueChanged = {}
            )
        )
    )

    val vm = PreviewActivityVm(
        activityState = ContactsActivityUiState(
            isSyncing = false,
            dialogUiState = null,
            dataOpIsActive = false
        ),
        detailsState = detailsVm.uiStateValue,
        listState = listVm.uiStateValue
    )

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ContactsActivityContent(
                activityUiInteractor = vm,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
                windowSizeClasses = WindowSizeClasses(
                    horiz = WindowSizeClass.Compact,
                    vert = WindowSizeClass.Expanded
                )
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun SinglePaneDetailsPreview() {
    val contacts = (1..100).map { it.toString() }.map {
        SObjectRecord(
            id = it,
            syncState = SObjectSyncState.MatchesUpstream,
            sObject = ContactObject(
                firstName = "First $it",
                lastName = "Last $it",
                title = "Title $it",
                department = "Department $it"
            )
        )
    }

    val selectedContact = contacts[3]

    val detailsVm = PreviewDetailsComponentVm(
        uiState = selectedContact.toPreviewViewingContactDetails()
    )

    val listVm = PreviewListVm(
        uiState = ContactsListUiState(
            contacts = contacts,
            curSelectedContactId = selectedContact.id,
            isDoingInitialLoad = false,
            isDoingDataAction = false,
            isSearchJobRunning = false,
            searchField = previewContactListSearchField(
                fieldValue = null,
                onValueChanged = {},
            )
        )
    )

    val vm = PreviewActivityVm(
        activityState = ContactsActivityUiState(
            isSyncing = false,
            dialogUiState = null,
            dataOpIsActive = false
        ),
        detailsState = detailsVm.uiStateValue,
        listState = listVm.uiStateValue
    )

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ContactsActivityContent(
                activityUiInteractor = vm,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
                windowSizeClasses = WindowSizeClasses(
                    horiz = WindowSizeClass.Compact,
                    vert = WindowSizeClass.Expanded
                )
            )
        }
    }
}

@Preview(
    showBackground = true,
    widthDp = WINDOW_SIZE_COMPACT_CUTOFF_DP,
    heightDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP
)
@Composable
private fun ListDetailMediumPreview() {
    val contacts = (1..100).map { it.toString() }.map {
        SObjectRecord(
            id = it,
            syncState = SObjectSyncState.MatchesUpstream,
            sObject = ContactObject(
                firstName = "First $it",
                lastName = "Last $it",
                title = "Title $it",
                department = "Department $it"
            )
        )
    }

    val selectedContact = contacts[3]

    val detailsVm = PreviewDetailsComponentVm(
        uiState = selectedContact.toPreviewViewingContactDetails()
    )

    val listVm = PreviewListVm(
        uiState = ContactsListUiState(
            contacts = contacts,
            curSelectedContactId = selectedContact.id,
            isDoingInitialLoad = false,
            isDoingDataAction = false,
            isSearchJobRunning = false,
            searchField = previewContactListSearchField(
                fieldValue = null,
                onValueChanged = {}
            )
        )
    )

    val activityState = ContactsActivityUiState(
        isSyncing = false,
        dataOpIsActive = false,
        dialogUiState = null
    )

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ListDetail(
                activityUiState = activityState,
                detailsUiState = detailsVm.uiStateValue,
                detailsClickHandler = detailsVm,
                listUiState = listVm.uiStateValue,
                listClickHandler = listVm,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
                WindowSizeClasses(horiz = WindowSizeClass.Medium, vert = WindowSizeClass.Expanded)
            )
        }
    }
}

@Preview(
    showBackground = true,
    widthDp = WINDOW_SIZE_COMPACT_CUTOFF_DP,
    heightDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP,
    uiMode = UI_MODE_NIGHT_YES
)
@Composable
private fun ListDetailEditingPreview() {
    val contacts = (1..100).map { it.toString() }.map {
        SObjectRecord(
            id = it,
            syncState = SObjectSyncState.MatchesUpstream,
            sObject = ContactObject(
                firstName = "First $it",
                lastName = "Last $it",
                title = "Title $it",
                department = "Department $it"
            )
        )
    }

    val selectedContact = contacts[3]

    val detailsVm = PreviewDetailsComponentVm(
        uiState = selectedContact.toPreviewViewingContactDetails(isEditingEnabled = true)
    )

    val listVm = PreviewListVm(
        uiState = ContactsListUiState(
            contacts = contacts,
            curSelectedContactId = selectedContact.id,
            isDoingInitialLoad = false,
            isDoingDataAction = false,
            isSearchJobRunning = false,
            searchField = previewContactListSearchField(
                fieldValue = null,
                onValueChanged = {}
            )
        )
    )

    val activityState = ContactsActivityUiState(
        isSyncing = false,
        dataOpIsActive = false,
        dialogUiState = null
    )

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ListDetail(
                activityUiState = activityState,
                detailsUiState = detailsVm.uiStateValue,
                detailsClickHandler = detailsVm,
                listUiState = listVm.uiStateValue,
                listClickHandler = listVm,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
                WindowSizeClasses(horiz = WindowSizeClass.Medium, vert = WindowSizeClass.Expanded)
            )
        }
    }
}

@Preview(
    showBackground = true,
    widthDp = WINDOW_SIZE_COMPACT_CUTOFF_DP,
    heightDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP
)
@Composable
private fun ListDetailNoContactPreview() {
    val curSearchTerm = "9"
    val contacts = (1..100).map { it.toString() }.map {
        SObjectRecord(
            id = it,
            syncState = SObjectSyncState.MatchesUpstream,
            sObject = ContactObject(
                firstName = "First $it",
                lastName = "Last $it",
                title = "Title $it",
                department = "Department $it"
            )
        )
    }.filter { it.sObject.fullName.contains(curSearchTerm) }

    val detailsVm = PreviewDetailsComponentVm(
        uiState = ContactDetailsUiState.NoContactSelected()
    )

    val listVm = PreviewListVm(
        uiState = ContactsListUiState(
            contacts = contacts,
            curSelectedContactId = null,
            isDoingInitialLoad = false,
            isDoingDataAction = false,
            isSearchJobRunning = false,
            searchField = previewContactListSearchField(
                fieldValue = curSearchTerm,
                onValueChanged = {}
            )
        )
    )

    val activityState = ContactsActivityUiState(
        isSyncing = false,
        dataOpIsActive = false,
        dialogUiState = null
    )

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ListDetail(
                activityUiState = activityState,
                detailsUiState = detailsVm.uiStateValue,
                detailsClickHandler = detailsVm,
                listUiState = listVm.uiStateValue,
                listClickHandler = listVm,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
                WindowSizeClasses(horiz = WindowSizeClass.Medium, vert = WindowSizeClass.Expanded)
            )
        }
    }
}

@Preview(
    showBackground = true,
    widthDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP,
    heightDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP
)
@Preview(
    showBackground = true,
    widthDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP,
    heightDp = WINDOW_SIZE_MEDIUM_CUTOFF_DP,
    uiMode = UI_MODE_NIGHT_YES
)
@Composable
private fun ListDetailExpandedPreview() {
    val contacts = (1..100).map { it.toString() }.map {
        SObjectRecord(
            id = it,
            syncState = SObjectSyncState.MatchesUpstream,
            sObject = ContactObject(
                firstName = "First $it",
                lastName = "Last $it",
                title = "Title $it",
                department = "Department $it"
            )
        )
    }

    val selectedContact = contacts[3]

    val detailsVm = PreviewDetailsComponentVm(
        uiState = selectedContact.toPreviewViewingContactDetails()
    )

    val listVm = PreviewListVm(
        uiState = ContactsListUiState(
            contacts = contacts,
            curSelectedContactId = selectedContact.id,
            isDoingInitialLoad = false,
            isDoingDataAction = false,
            isSearchJobRunning = false,
            searchField = previewContactListSearchField(
                fieldValue = null,
                onValueChanged = {}
            )
        )
    )

    val activityState = ContactsActivityUiState(
        isSyncing = false,
        dataOpIsActive = false,
        dialogUiState = null
    )

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ListDetail(
                activityUiState = activityState,
                detailsUiState = detailsVm.uiStateValue,
                detailsClickHandler = detailsVm,
                listUiState = listVm.uiStateValue,
                listClickHandler = listVm,
                menuHandler = PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER,
                WindowSizeClasses(horiz = WindowSizeClass.Expanded, vert = WindowSizeClass.Expanded)
            )
        }
    }
}

class PreviewDetailsComponentVm(uiState: ContactDetailsUiState) :
    ContactDetailsComponentClickHandler {

    val uiState: StateFlow<ContactDetailsUiState> = MutableStateFlow(uiState)
    val uiStateValue get() = this.uiState.value

    override fun createClick() {}
    override fun deleteClick() {}
    override fun undeleteClick() {}
    override fun deselectContactClick() {}
    override fun editClick() {}
    override fun exitEditClick() {}
    override fun saveClick() {}
}

class PreviewListVm(uiState: ContactsListUiState) : ContactsListClickHandler {
    val uiState: StateFlow<ContactsListUiState> = MutableStateFlow(uiState)
    val uiStateValue get() = this.uiState.value

    override fun contactClick(contactId: String) {}
    override fun createClick() {}
    override fun deleteClick(contactId: String) {}
    override fun editClick(contactId: String) {}
    override fun undeleteClick(contactId: String) {}
}

class PreviewActivityVm(
    activityState: ContactsActivityUiState,
    detailsState: ContactDetailsUiState,
    listState: ContactsListUiState
) : ContactsActivityUiInteractor {
    override val activityUiState: StateFlow<ContactsActivityUiState> =
        MutableStateFlow(activityState)

    private val detailsVm = PreviewDetailsComponentVm(detailsState)
    private val listVm = PreviewListVm(listState)

    override val detailsUiState: StateFlow<ContactDetailsUiState> get() = detailsVm.uiState
    override val listUiState: StateFlow<ContactsListUiState> get() = listVm.uiState

    override val detailsClickHandler: ContactDetailsComponentClickHandler get() = detailsVm
    override val listClickHandler: ContactsListClickHandler get() = listVm
    override val messages: Flow<ContactsActivityMessages>
        get() = emptyFlow()
}

val PREVIEW_CONTACTS_ACTIVITY_MENU_HANDLER = object : ContactsActivityMenuHandler {
    override fun onInspectDbClick() {}
    override fun onLogoutClick() {}
    override fun onSwitchUserClick() {}
    override fun onSyncClick() {}
}

@TestOnly
fun previewContactListSearchField(
    fieldValue: String?,
    onValueChanged: (String) -> Unit,
) = EditableTextFieldUiState(
    fieldValue = fieldValue,
    onValueChange = onValueChanged,
    isInErrorState = false,
    label = null,
    placeholder = FormattedStringRes(cta_search),
    helper = null,
    maxLines = 1u,
)
