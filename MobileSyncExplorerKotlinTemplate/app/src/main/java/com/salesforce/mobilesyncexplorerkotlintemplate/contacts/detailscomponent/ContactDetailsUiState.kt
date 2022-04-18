package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent

import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

sealed interface ContactDetailsUiState {
    val doingInitialLoad: Boolean

    data class ViewingContactDetails(
        val firstNameField: ContactDetailsField.FirstName,
        val lastNameField: ContactDetailsField.LastName,
        val titleField: ContactDetailsField.Title,
        val departmentField: ContactDetailsField.Department,

        val uiSyncState: SObjectUiSyncState,
        val isEditingEnabled: Boolean,
        val shouldScrollToErrorField: Boolean,

        override val doingInitialLoad: Boolean = false
    ) : ContactDetailsUiState {
        val fullName = ContactObject.formatFullName(
            firstName = firstNameField.fieldValue,
            lastName = lastNameField.fieldValue
        )
    }

    data class NoContactSelected(
        override val doingInitialLoad: Boolean = false
    ) : ContactDetailsUiState
}

fun ContactDetailsUiState.copy(
    doingInitialLoad: Boolean = this.doingInitialLoad,
) = when (this) {
    is ContactDetailsUiState.NoContactSelected -> this.copy(
        doingInitialLoad = doingInitialLoad,
    )
    is ContactDetailsUiState.ViewingContactDetails -> this.copy(
        doingInitialLoad = doingInitialLoad,
    )
}
