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
package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ui

import android.content.res.Configuration.UI_MODE_NIGHT_YES
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.ui.layout.SubcomposeLayout
import androidx.compose.ui.layout.layoutId
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.content_desc_cancel_search
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.cta_search
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.PreviewListVm
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.previewContactListSearchField
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.FloatingTextEntryBar
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.rememberSimpleSpinAnimation
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.toUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

/**
 * The Contacts List content without any scaffolding. Use this to embed the Contacts List within
 * higher-level layouts.
 */
@Composable
fun ContactsListComponentListContent(
    modifier: Modifier = Modifier,
    uiState: ContactsListUiState,
    listClickHandler: ContactsListClickHandler,
) {
    /* This layout first subcomposes and measures the search bar, using its measured height to apply
     * padding to the contacts list. This allows the search bar to appear to be laid out linearly
     * with the list content, but then it floats over the list when scrolled. */
    SubcomposeLayout(modifier = modifier) { constraints ->
        val searchConstraints = constraints.copy(minWidth = 0, minHeight = 0)

        val searchBarMeasureables = subcompose(slotId = ID_FLOATING_SEARCH_BAR) {
            SearchBar(
                modifier = Modifier.layoutId(ID_FLOATING_SEARCH_BAR),
                isSearchActive = uiState.isSearchJobRunning,
                field = uiState.searchField
            )
        }

        val searchBarPlaceable = searchBarMeasureables
            .first { it.layoutId == ID_FLOATING_SEARCH_BAR }
            .measure(searchConstraints)

        val listMeasureables = subcompose(slotId = ID_CONTACTS_LIST) {
            val paddingDp = with(LocalDensity.current) { searchBarPlaceable.height.toDp() }

            ContactsList(
                modifier = Modifier.layoutId(ID_CONTACTS_LIST),
                contentPadding = PaddingValues(top = paddingDp),
                uiState = uiState,
                listClickHandler = listClickHandler
            )
        }

        val listPlaceable = listMeasureables
            .first { it.layoutId == ID_CONTACTS_LIST }
            .measure(constraints)

        layout(
            width = maxOf(searchBarPlaceable.width, listPlaceable.width),
            height = maxOf(searchBarPlaceable.height, listPlaceable.height)
        ) {
            listPlaceable.placeRelative(0, 0)
            searchBarPlaceable.placeRelative(0, 0)
        }
    }
}

@Composable
private fun ContactsList(
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues,
    uiState: ContactsListUiState,
    listClickHandler: ContactsListClickHandler
) {
    LazyColumn(
        modifier = modifier,
        contentPadding = contentPadding
    ) {
        items(items = uiState.contacts, key = { it.id }) { record ->
            ContactCard(
                modifier = Modifier.padding(4.dp),
                startExpanded = false,
                model = record.sObject,
                syncState = record.syncState.toUiSyncState(),
                onCardClick = { listClickHandler.contactClick(record.id) },
                onDeleteClick = { listClickHandler.deleteClick(record.id) },
                onUndeleteClick = { listClickHandler.undeleteClick(record.id) },
                onEditClick = { listClickHandler.editClick(record.id) },
            )
        }
    }
}

@Composable
private fun SearchBar(
    modifier: Modifier = Modifier,
    isSearchActive: Boolean,
    field: EditableTextFieldUiState
) {
    FloatingTextEntryBar(
        modifier = modifier
            .fillMaxWidth()
            .padding(8.dp),
        value = field.fieldValue ?: "",
        onValueChange = {
            val sanitized = field.sanitizer(it)
            if (field.fieldValue != sanitized) {
                field.onValueChange(sanitized)
            }
        },
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
            if (field.fieldValue != null && field.fieldValue.isNotBlank()) {
                IconButton(onClick = { field.onValueChange("") }) {
                    Icon(
                        Icons.Default.Close,
                        contentDescription = stringResource(id = content_desc_cancel_search)
                    )
                }
            }
        },
        elevation = 16.dp
    )
}

private const val ID_CONTACTS_LIST = "ID_CONTACTS_LIST"
private const val ID_FLOATING_SEARCH_BAR = "ID_FLOATING_SEARCH_BAR"

@Preview(showBackground = true)
@Composable
private fun ContactsListContentPreview(searchTerm: String = "9") {
    val contacts = (1..100)
        .map { it.toString() }
        .map {
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
        .filter { it.sObject.fullName.contains(searchTerm) }

    val uiState = ContactsListUiState(
        contacts = contacts,
        curSelectedContactId = contacts.first().id,
        isDoingInitialLoad = false,
        isDoingDataAction = false,
        isSearchJobRunning = false,
        searchField = previewContactListSearchField(
            fieldValue = searchTerm,
            onValueChanged = {},
        )
    )

    val vm = PreviewListVm(uiState = uiState)

    SalesforceMobileSDKAndroidTheme {
        Surface {
            ContactsListComponentListContent(uiState = vm.uiStateValue, listClickHandler = vm)
        }
    }
}

@Preview(showBackground = true, uiMode = UI_MODE_NIGHT_YES)
@Composable
private fun ContactsListContentPreviewNight() {
    ContactsListContentPreview(searchTerm = "")
}
