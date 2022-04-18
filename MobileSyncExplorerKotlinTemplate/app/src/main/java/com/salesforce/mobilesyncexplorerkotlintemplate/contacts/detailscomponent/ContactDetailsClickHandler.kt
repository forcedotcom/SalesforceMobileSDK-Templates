package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent

interface ContactDetailsClickHandler {
    fun createClick()
    fun deleteClick()
    fun undeleteClick()
    fun deselectContactClick()
    fun editClick()
    fun exitEditClick()
    fun saveClick()
}
