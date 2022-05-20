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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state

import androidx.compose.material.AlertDialog
import androidx.compose.material.Text
import androidx.compose.material.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.*

/**
 * Abstraction of a popover dialog which encapsulates the dialog rendering.
 */
interface DialogUiState {
    @Composable
    fun RenderDialog(modifier: Modifier)
}

/**
 * Reusable confirmation dialog which confirms whether the user wants to delete an SObject instance.
 *
 * @param objIdToDelete The ID of the SObject instance to delete. This will be provided to the [onConfirmDelete] callback if the user confirms the delete.
 * @param objName Optional friendly name of the SObject instance to help clarify exactly what is being deleted. If null, a fallback message will be used without the name.
 * @param onCancelDelete Invoked when the user cancels the delete action.
 * @param onConfirmDelete Invoked when the user confirms the delete action.
 */
data class DeleteConfirmationDialogUiState(
    val objIdToDelete: String,
    val objName: String?,
    val onCancelDelete: () -> Unit,
    val onConfirmDelete: (objId: String) -> Unit,
) : DialogUiState {
    @Composable
    override fun RenderDialog(modifier: Modifier) {
        AlertDialog(
            onDismissRequest = onCancelDelete,
            confirmButton = {
                TextButton(onClick = { onConfirmDelete(objIdToDelete) }) {
                    Text(stringResource(id = cta_delete))
                }
            },
            dismissButton = {
                TextButton(onClick = onCancelDelete) {
                    Text(stringResource(id = android.R.string.cancel))
                }
            },
            title = { Text(stringResource(id = label_delete_confirm)) },
            text = {
                if (objName.isNullOrBlank())
                    Text(stringResource(id = body_delete_confirm))
                else
                    Text(stringResource(id = body_delete_confirm_with_name, objName))
            },
            modifier = modifier
        )
    }
}

/**
 * Reusable confirmation dialog which confirms that the user is okay with losing their unsaved changes.
 */
data class DiscardChangesDialogUiState(
    val onCancelDiscardChanges: () -> Unit,
    val onConfirmDiscardChanges: () -> Unit,
) : DialogUiState {
    @Composable
    override fun RenderDialog(modifier: Modifier) {
        AlertDialog(
            onDismissRequest = onCancelDiscardChanges,
            confirmButton = {
                TextButton(onClick = onConfirmDiscardChanges) {
                    Text(stringResource(id = cta_discard))
                }
            },
            dismissButton = {
                TextButton(onClick = onCancelDiscardChanges) {
                    Text(stringResource(id = cta_continue_editing))
                }
            },
            title = { Text(stringResource(id = label_discard_changes)) },
            text = { Text(stringResource(id = body_discard_changes)) },
            modifier = modifier
        )
    }
}

/**
 * Reusable confirmation dialog which confirms whether the user wants to undelete an SObject instance.
 *
 * @param objIdToUndelete The ID of the SObject instance to undelete. This will be provided to the [onConfirmUndelete] callback if the user confirms the undelete.
 * @param objName Optional friendly name of the SObject instance to help clarify exactly what is being undeleted. If null, a fallback message will be used without the name.
 * @param onCancelUndelete Invoked when the user cancels the undelete action.
 * @param onConfirmUndelete Invoked when the user confirms the undelete action.
 */
data class UndeleteConfirmationDialogUiState(
    val objIdToUndelete: String,
    val objName: String?,
    val onCancelUndelete: () -> Unit,
    val onConfirmUndelete: (objId: String) -> Unit,
) : DialogUiState {
    @Composable
    override fun RenderDialog(modifier: Modifier) {
        AlertDialog(
            onDismissRequest = onCancelUndelete,
            confirmButton = {
                TextButton(onClick = { onConfirmUndelete(objIdToUndelete) }) {
                    Text(stringResource(id = cta_undelete))
                }
            },
            dismissButton = {
                TextButton(onClick = onCancelUndelete) {
                    Text(stringResource(id = android.R.string.cancel))
                }
            },
            title = { Text(stringResource(id = label_undelete_confirm)) },
            text = {
                if (objName.isNullOrBlank())
                    Text(stringResource(id = body_delete_confirm))
                else
                    Text(stringResource(id = body_undelete_confirm_with_name, objName))
            },
            modifier = modifier
        )
    }
}
