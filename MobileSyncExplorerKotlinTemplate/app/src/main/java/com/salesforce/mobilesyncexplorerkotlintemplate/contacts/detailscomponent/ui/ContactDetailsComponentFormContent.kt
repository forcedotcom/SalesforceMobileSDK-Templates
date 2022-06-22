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
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.*
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.R.drawable.ic_help
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.*
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.LoadingOverlay
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components.OutlinedTextFieldWithHelp
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.FormattedStringRes
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme

/**
 * The form content of the Contact Details component. Adds all the fields in the [details] object to
 * the Compose UI in a single column scrollable format. Use this to embed the Contact Details form
 * within higher-level layouts.
 */
@Composable
fun ContactDetailsComponentFormContent(
    details: ContactDetailsUiState,
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(all = 0.dp)
) {
    when (details) {
        is ContactDetailsUiState.ViewingContactDetails -> ContactDetailsViewingContact(
            modifier = modifier,
            details = details,
            contentPadding = contentPadding
        )
        is ContactDetailsUiState.NoContactSelected -> ContactDetailsNoContactSelected()
    }
}

@Composable
private fun ContactDetailsViewingContact(
    modifier: Modifier = Modifier,
    details: ContactDetailsUiState.ViewingContactDetails,
    contentPadding: PaddingValues
) {
    val focusManager = LocalFocusManager.current
    val focusRequester = remember { FocusRequester.Default }
    val scrollState = rememberScrollState()

    Column(
        modifier = modifier
            .verticalScroll(state = scrollState)
            .padding(
                top = contentPadding.calculateTopPadding(),
                bottom = contentPadding.calculateBottomPadding(),
                start = contentPadding.calculateStartPadding(LocalLayoutDirection.current),
                end = contentPadding.calculateEndPadding(LocalLayoutDirection.current)
            ),
    ) {
        if (details.uiSyncState == SObjectUiSyncState.Deleted) {
            LocallyDeletedRow()
        }

        details.firstNameField.toOutlinedTextFieldWithHelp(
            isEditingEnabled = details.isEditingEnabled,
            focusManager = focusManager,
            focusRequester = focusRequester,
            imeAction = ImeAction.Next
        )
        details.lastNameField.toOutlinedTextFieldWithHelp(
            isEditingEnabled = details.isEditingEnabled,
            focusManager = focusManager,
            focusRequester = focusRequester,
            imeAction = ImeAction.Next
        )
        details.titleField.toOutlinedTextFieldWithHelp(
            isEditingEnabled = details.isEditingEnabled,
            focusManager = focusManager,
            focusRequester = focusRequester,
        )
        details.departmentField.toOutlinedTextFieldWithHelp(
            isEditingEnabled = details.isEditingEnabled,
            focusManager = focusManager,
            focusRequester = focusRequester,
        )
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
private fun EditableTextFieldUiState.toOutlinedTextFieldWithHelp(
    isEditingEnabled: Boolean,
    focusManager: FocusManager,
    focusRequester: FocusRequester,
    imeAction: ImeAction = ImeAction.Default
) {
    var hasFocus by remember { mutableStateOf(false) }
    var textFieldValueState by remember { mutableStateOf(TextFieldValue(fieldValue ?: "")) }
    val textFieldValue = textFieldValueState.copy(text = fieldValue ?: "")

    // Move the cursor to the end of the field content if IME action changes focus to this field:
    val focusChangeHandlerModifier = Modifier
        .onFocusChanged { newFocusState ->
            if (!hasFocus && newFocusState.hasFocus) {
                textFieldValueState = textFieldValueState.copy(
                    selection = TextRange(textFieldValue.text.length)
                )
            }
            hasFocus = newFocusState.hasFocus
        }
        .focusRequester(focusRequester)

    val onValueChangedHandler: (TextFieldValue) -> Unit = {
        val sanitized = it.copy(text = sanitizer(it.text))

        textFieldValueState = sanitized

        if (sanitized.text != (fieldValue ?: "")) {
            onValueChange(sanitized.text)
        }
    }

    OutlinedTextFieldWithHelp(
        modifier = Modifier.fillMaxWidth(),
        fieldModifier = focusChangeHandlerModifier.fillMaxWidth(),
        value = textFieldValue,
        isEditEnabled = isEditingEnabled && fieldIsEnabled,
        isError = isInErrorState,
        onValueChange = onValueChangedHandler,
        label = { label?.let { Text(stringResource(id = it.resId, *it.formattingArgs)) } },
        help = helper?.let { stringResource(id = it.resId, *it.formattingArgs) },
        placeholder = {
            placeholder?.let { Text(stringResource(id = it.resId, *it.formattingArgs)) }
        },
        keyboardActions = KeyboardActions(
            onNext = { focusManager.moveFocus(FocusDirection.Next) },
        ),
        keyboardOptions = KeyboardOptions(imeAction = imeAction),
        maxLines = maxLines
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

@Preview
@Composable
private fun ContactDetailsContentViewingContactPreview() {
    val detailsUiState = ContactDetailsUiState.ViewingContactDetails(
        recordId = "1",
        firstNameField = EditableTextFieldUiState(
            fieldValue = "Foo",
            onValueChange = {},
            isInErrorState = false,
            label = FormattedStringRes(label_contact_first_name),
            placeholder = FormattedStringRes(label_contact_first_name),
            helper = null
        ),
        lastNameField = EditableTextFieldUiState(
            fieldValue = null,
            onValueChange = {},
            isInErrorState = true,
            label = FormattedStringRes(label_contact_last_name),
            placeholder = FormattedStringRes(label_contact_last_name),
            helper = FormattedStringRes(help_cannot_be_blank)
        ),
        titleField = EditableTextFieldUiState(
            fieldValue = "Title",
            onValueChange = {},
            isInErrorState = false,
            label = FormattedStringRes(label_contact_title),
            placeholder = FormattedStringRes(label_contact_title),
            helper = null
        ),
        departmentField = EditableTextFieldUiState(
            fieldValue = null,
            onValueChange = {},
            isInErrorState = false,
            label = FormattedStringRes(label_contact_department),
            placeholder = FormattedStringRes(label_contact_department),
            helper = null
        ),
        uiSyncState = SObjectUiSyncState.Updated,
        isEditingEnabled = true,
        shouldScrollToErrorField = false,
    )
    SalesforceMobileSDKAndroidTheme {
        Surface {
            ContactDetailsViewingContact(
                details = detailsUiState,
                contentPadding = PaddingValues(all = 0.dp)
            )
        }
    }
}
