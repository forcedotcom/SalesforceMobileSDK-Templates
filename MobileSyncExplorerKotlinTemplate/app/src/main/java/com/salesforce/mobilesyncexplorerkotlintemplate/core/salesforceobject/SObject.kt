package com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject

import org.json.JSONObject

interface SObject {
    fun JSONObject.applyObjProperties(): JSONObject
    val objectType: String
}
