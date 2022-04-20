package com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject

data class SObjectRecord<T : SObject>(
    val id: String,
    val localStatus: LocalStatus,
    val sObject: T
)
