package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent

import com.salesforce.mobilesyncexplorerkotlintemplate.R
import com.salesforce.mobilesyncexplorerkotlintemplate.core.vm.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.vm.FieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactValidationException

sealed interface ContactDetailsField : FieldUiState {
    data class FirstName(
        override val fieldValue: String?,
        override val onValueChange: (newValue: String) -> Unit,
        override val fieldIsEnabled: Boolean = true,
        override val maxLines: UInt = 1u
    ) : ContactDetailsField, EditableTextFieldUiState {
        override val isInErrorState: Boolean = false
        override val helperRes: Int? = null
        override val labelRes: Int = R.string.label_contact_first_name
        override val placeholderRes: Int = R.string.label_contact_first_name
    }

    data class LastName(
        override val fieldValue: String?,
        override val onValueChange: (newValue: String) -> Unit,
        override val fieldIsEnabled: Boolean = true,
        override val maxLines: UInt = 1u
    ) : ContactDetailsField, EditableTextFieldUiState {
        override val isInErrorState: Boolean
        override val helperRes: Int?

        init {
            val validateException = runCatching { ContactObject.validateLastName(fieldValue) }
                .exceptionOrNull() as ContactValidationException?

            if (validateException == null) {
                isInErrorState = false
                helperRes = null
            } else {
                isInErrorState = true
                helperRes = when (validateException) {
                    ContactValidationException.LastNameCannotBeBlank -> R.string.help_cannot_be_blank
                }
            }
        }

        override val labelRes: Int = R.string.label_contact_last_name
        override val placeholderRes: Int = R.string.label_contact_last_name
    }

    data class Title(
        override val fieldValue: String?,
        override val onValueChange: (newValue: String) -> Unit,
        override val fieldIsEnabled: Boolean = true,
        override val maxLines: UInt = 1u
    ) : ContactDetailsField, EditableTextFieldUiState {
        override val isInErrorState: Boolean = false
        override val labelRes: Int = R.string.label_contact_title
        override val helperRes: Int? = null
        override val placeholderRes: Int = R.string.label_contact_title
    }

    data class Department(
        override val fieldValue: String?,
        override val onValueChange: (newValue: String) -> Unit,
        override val fieldIsEnabled: Boolean = true,
        override val maxLines: UInt = 1u
    ) : ContactDetailsField, EditableTextFieldUiState {
        override val isInErrorState: Boolean = false
        override val labelRes: Int = R.string.label_contact_department
        override val helperRes: Int? = null
        override val placeholderRes: Int = R.string.label_contact_department
    }
}
