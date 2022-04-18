package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ui

import android.content.res.Configuration.UI_MODE_NIGHT_YES
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_cancel_search
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_search
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.PreviewListVm
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.LocalStatus
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.FloatingTextEntryBar
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.LoadingOverlay
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.rememberSimpleSpinAnimation
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.toUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

@Composable
fun ContactsListContent(
    modifier: Modifier = Modifier,
    uiState: ContactsListUiState,
    listClickHandler: ContactsListClickHandler,
    onSearchTermUpdated: (newSearchTerm: String) -> Unit
) {
    LazyColumn(modifier = modifier) {
        item {
            val searchTerm = uiState.curSearchTerm
            val isSearchActive = uiState.isSearchJobRunning
            FloatingTextEntryBar(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                value = searchTerm,
                onValueChange = onSearchTermUpdated,
                placeholder = { Text(stringResource(id = cta_search)) },
                leadingIcon = {
                    if (isSearchActive) {
                        val angle: Float by rememberSimpleSpinAnimation(hertz = 1f)
                        Icon(
                            Icons.Default.Refresh,
                            contentDescription = stringResource(id = cta_search),
                            modifier = Modifier.graphicsLayer { rotationZ = angle }
                        )
                    } else {
                        Icon(
                            Icons.Default.Search,
                            contentDescription = stringResource(id = cta_search)
                        )
                    }
                },
                trailingIcon = {
                    if (searchTerm.isNotBlank()) {
                        IconButton(onClick = { onSearchTermUpdated("") }) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = stringResource(id = content_desc_cancel_search)
                            )
                        }
                    }
                }
            )
        }

        items(items = uiState.contacts, key = { it.id }) { record ->
            ContactCard(
                modifier = Modifier.padding(4.dp),
                startExpanded = false,
                model = record.sObject,
                syncState = record.localStatus.toUiSyncState(),
                onCardClick = { listClickHandler.contactClick(record.id) },
                onDeleteClick = { listClickHandler.deleteClick(record.id) },
                onUndeleteClick = { listClickHandler.undeleteClick(record.id) },
                onEditClick = { listClickHandler.editClick(record.id) },
            )
        }
    }

    if (uiState.isDoingInitialLoad || uiState.isDoingDataAction) {
        LoadingOverlay()
    }
}

@Preview(showBackground = true)
@Composable
private fun ContactsListContentPreview(searchTerm: String = "9") {
    val contacts = (1..100)
        .map { it.toString() }
        .map {
            SObjectRecord(
                id = it,
                localStatus = LocalStatus.MatchesUpstream,
                sObject = ContactObject(
                    firstName = "First $it",
                    lastName = "Last $it",
                    title = "Title $it",
                    department = "Department $it"
                )
            )
        }
        .filter { it.sObject.fullName.contains(searchTerm) }

    val uiState = ContactsListUiState(
        contacts = contacts,
        curSelectedContactId = contacts.first().id,
        isDoingInitialLoad = false,
        isDoingDataAction = false,
        isSearchJobRunning = false,
        curSearchTerm = searchTerm
    )

    val vm = PreviewListVm(uiState = uiState)

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ContactsListContent(
                uiState = vm.uiStateValue,
                listClickHandler = vm,
                onSearchTermUpdated = vm::onSearchTermUpdated
            )
        }
    }
}

@Preview(showBackground = true, uiMode = UI_MODE_NIGHT_YES)
@Composable
private fun ContactsListContentPreviewNight() {
    ContactsListContentPreview(searchTerm = "")
}
