package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent

import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.DialogUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

sealed interface ContactDetailsUiState {
    val curDialogUiState: DialogUiState?
    val dataOperationIsActive: Boolean // TODO it may be a good idea to break this up into discrete flags for the different types of data operations, and then the UI just shows the spinner if any of the flags are true.
    val doingInitialLoad: Boolean

    data class ViewingContactDetails(
        val firstNameField: ContactDetailsField.FirstName,
        val lastNameField: ContactDetailsField.LastName,
        val titleField: ContactDetailsField.Title,
        val departmentField: ContactDetailsField.Department,

        val uiSyncState: SObjectUiSyncState,
        val isEditingEnabled: Boolean,
        val shouldScrollToErrorField: Boolean,

        override val curDialogUiState: DialogUiState?,
        override val dataOperationIsActive: Boolean,
        override val doingInitialLoad: Boolean = false
    ) : ContactDetailsUiState {
        val fullName = ContactObject.formatFullName(
            firstName = firstNameField.fieldValue,
            lastName = lastNameField.fieldValue
        )
    }

    data class NoContactSelected(
        override val curDialogUiState: DialogUiState?,
        override val dataOperationIsActive: Boolean,
        override val doingInitialLoad: Boolean = false
    ) : ContactDetailsUiState
}

fun ContactDetailsUiState.copy(
    curDialogUiState: DialogUiState? = this.curDialogUiState,
    dataOperationIsActive: Boolean = this.dataOperationIsActive,
    doingInitialLoad: Boolean = this.doingInitialLoad,
) = when (this) {
    is ContactDetailsUiState.NoContactSelected -> this.copy(
        curDialogUiState = curDialogUiState,
        dataOperationIsActive = dataOperationIsActive,
        doingInitialLoad = doingInitialLoad,
    )
    is ContactDetailsUiState.ViewingContactDetails -> this.copy(
        curDialogUiState = curDialogUiState,
        dataOperationIsActive = dataOperationIsActive,
        doingInitialLoad = doingInitialLoad,
    )
}
