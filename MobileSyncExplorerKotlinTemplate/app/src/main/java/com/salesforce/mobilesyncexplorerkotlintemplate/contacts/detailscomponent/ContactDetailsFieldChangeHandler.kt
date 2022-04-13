package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent

interface ContactDetailsFieldChangeHandler {
    fun onFirstNameChange(newFirstName: String)
    fun onLastNameChange(newLastName: String)
    fun onTitleChange(newTitle: String)
    fun onDepartmentChange(newDepartment: String)
}
