package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

interface ContactsListDataActionClickHandler {
    fun deleteClick(contactId: String)
    fun undeleteClick(contactId: String)
}
