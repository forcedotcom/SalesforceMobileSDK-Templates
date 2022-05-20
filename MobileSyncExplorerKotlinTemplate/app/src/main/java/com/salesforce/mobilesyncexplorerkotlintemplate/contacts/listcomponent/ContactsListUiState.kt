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
package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.EditableTextFieldUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

/**
 * UI state for the Contacts List component.
 *
 * @param contacts The list of contacts to render. Set this to your filtered list of contacts when search results are obtained.
 * @param curSelectedContactId Used to visually indicate which contact the user has selected.
 * @param isDoingInitialLoad Flag to visually indicate that the list is doing its initial data fetch (e.g. showing a loading spinner).
 * @param isDoingDataAction Flag to visually indicate that the list is doing a data operation such as deleting a contact.
 * @param isSearchJobRunning Flag to visually indicate that the contact list search operation is active.
 * @param searchField Field object to encapsulate the search bar for the contacts list.
 */
data class ContactsListUiState(
    val contacts: List<SObjectRecord<ContactObject>>,
    val curSelectedContactId: String?,
    val isDoingInitialLoad: Boolean,
    val isDoingDataAction: Boolean,
    val isSearchJobRunning: Boolean,
    val searchField: EditableTextFieldUiState
)
