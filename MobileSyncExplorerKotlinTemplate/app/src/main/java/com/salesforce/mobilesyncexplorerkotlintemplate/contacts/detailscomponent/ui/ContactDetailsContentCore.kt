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

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R.drawable.ic_help
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.*
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.LoadingOverlay
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.vm.EditableTextFieldUiState

@Composable
fun ContactDetailsContent(
    details: ContactDetailsUiState,
    modifier: Modifier = Modifier,
) {
    when (details) {
        is ContactDetailsUiState.ViewingContactDetails -> ContactDetailsViewingContact(
            modifier = modifier,
            details = details,
        )
        is ContactDetailsUiState.NoContactSelected -> ContactDetailsNoContactSelected()
    }
}

@Composable
private fun ContactDetailsViewingContact(
    modifier: Modifier = Modifier,
    details: ContactDetailsUiState.ViewingContactDetails,
) {
    val scrollState = rememberScrollState()
    Column(
        modifier = modifier
            .padding(horizontal = 8.dp)
            .verticalScroll(state = scrollState)
    ) {
        if (details.uiSyncState == SObjectUiSyncState.Deleted) {
            LocallyDeletedRow()
        }

        details.firstNameField.OutlinedTextFieldWithHelp(isEditingEnabled = details.isEditingEnabled)
        details.lastNameField.OutlinedTextFieldWithHelp(isEditingEnabled = details.isEditingEnabled)
        details.titleField.OutlinedTextFieldWithHelp(isEditingEnabled = details.isEditingEnabled)
        details.departmentField.OutlinedTextFieldWithHelp(isEditingEnabled = details.isEditingEnabled)
    }

    if (details.doingInitialLoad) {
        LoadingOverlay()
    }
}

@Composable
private fun ContactDetailsNoContactSelected() {
    Box(modifier = Modifier.fillMaxSize()) {
        Text(
            text = stringResource(id = label_nothing_selected),
            modifier = Modifier.align(Alignment.Center)
        )
    }
}

@Composable
private fun EditableTextFieldUiState.OutlinedTextFieldWithHelp(isEditingEnabled: Boolean) {
    com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.OutlinedTextFieldWithHelp(
        fieldValue = fieldValue,
        isEditEnabled = isEditingEnabled && fieldIsEnabled,
        isError = isInErrorState,
        onValueChange = onValueChange,
        label = { labelRes?.let { Text(stringResource(id = it)) } },
        help = { helperRes?.let { Text(stringResource(id = it)) } },
        placeholder = { placeholderRes?.let { Text(stringResource(id = it)) } }
    )
}

@Composable
private fun LocallyDeletedRow() {
    var infoIsExpanded by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { infoIsExpanded = true }
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        CompositionLocalProvider(LocalContentColor provides MaterialTheme.colors.error) {
            Text(stringResource(id = label_locally_deleted))
            Icon(
                painterResource(id = ic_help),
                contentDescription = stringResource(id = content_desc_help),
                modifier = Modifier
                    .size(32.dp)
                    .padding(8.dp)
            )
        }
    }
    if (infoIsExpanded) {
        LocallyDeletedInfoDialog(onDismiss = { infoIsExpanded = false })
    }
}

@Composable
private fun LocallyDeletedInfoDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(id = android.R.string.ok)) }
        },
        text = { Text(stringResource(id = body_locally_deleted_info)) }
    )
}
