package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

interface ContactsListClickHandler {
    fun contactClick(contactId: String)
    fun createClick()
    fun editClick(contactId: String)
    fun deleteClick(contactId: String)
    fun undeleteClick(contactId: String)
}
