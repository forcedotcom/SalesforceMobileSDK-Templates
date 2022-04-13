package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

interface ContactsListDataOpHandler {
    fun deleteClick(contactId: String)
    fun undeleteClick(contactId: String)
}
