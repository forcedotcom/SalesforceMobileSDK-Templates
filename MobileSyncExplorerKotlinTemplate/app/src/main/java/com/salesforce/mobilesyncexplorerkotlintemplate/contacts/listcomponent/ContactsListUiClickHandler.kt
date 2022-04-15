package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

interface ContactsListUiClickHandler {
    fun contactClick(contactId: String)
    fun createClick()
    fun editClick(contactId: String)
}
