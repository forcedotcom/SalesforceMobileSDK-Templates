package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent

interface ContactDetailsUiEventHandler {
    fun createClick()
    fun deleteClick()
    fun undeleteClick()
    fun deselectContact()
    fun editClick()
    fun exitEditClick()
    fun saveClick()
}
