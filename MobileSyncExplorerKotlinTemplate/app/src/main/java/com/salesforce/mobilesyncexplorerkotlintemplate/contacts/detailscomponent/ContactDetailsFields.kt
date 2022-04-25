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
