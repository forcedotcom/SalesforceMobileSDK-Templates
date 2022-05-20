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

import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.SObjectUiSyncState
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

/**
 * Sealed interface encapsulating all possible states of the Contact Details component. This
 * interface defines several common properties shared between all sub-states of the component.
 */
sealed interface ContactDetailsUiState {
    val doingInitialLoad: Boolean
    val recordId: String?

    /**
     * State of the Contact Details component when the user is viewing or editing contact details.
     *
     * The [isEditingEnabled] flag is what controls whether the Details component is in "edit mode" or
     * "viewing mode." These two states could be represented by separate concrete types, but the only
     * difference between them would be the [isEditingEnabled] flag. For simplicity, these two modes
     * are combined into this one sub-state.
     */
    data class ViewingContactDetails(
        override val recordId: String?,
        val firstNameField: EditableTextFieldUiState,
        val lastNameField: EditableTextFieldUiState,
        val titleField: EditableTextFieldUiState,
        val departmentField: EditableTextFieldUiState,

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

    /**
     * State of the Contact Details component when the component has no details to show.
     */
    data class NoContactSelected(
        override val doingInitialLoad: Boolean = false
    ) : ContactDetailsUiState {
        override val recordId: String? = null
    }
}

/**
 * Convenience method to get data class copy semantics on the sealed interface. This method cannot
 * be used to change to a different sub-state of the Contact Details component; it only allows
 * modification of the shared state properties.
 */
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
