package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject

data class ContactsListUiState(
    val contacts: List<SObjectRecord<ContactObject>>,
    val curSelectedContactId: String?,
    val isDoingInitialLoad: Boolean,
    val curSearchTerm: String = ""
)
