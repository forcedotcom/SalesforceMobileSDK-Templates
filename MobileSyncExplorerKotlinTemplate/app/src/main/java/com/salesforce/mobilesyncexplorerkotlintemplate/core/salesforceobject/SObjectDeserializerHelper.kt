package com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject

import com.salesforce.androidsdk.mobilesync.util.Constants
import org.json.JSONObject
import java.util.*

object SObjectDeserializerHelper {

    @Throws(CoerceException::class)
    fun requireSoType(json: JSONObject, requiredObjType: String) {
        val attributes = json.getRequiredObjectOrThrow(Constants.ATTRIBUTES)

        val type = attributes.optString(Constants.TYPE.lowercase(Locale.US))
        if (type != requiredObjType) {
            throw IncorrectObjectType(
                expectedObjectType = requiredObjType,
                foundObjectType = type,
                offendingJsonString = json.toString()
            )
        }
    }

    @Throws(CoerceException::class)
    fun getIdOrThrow(json: JSONObject): String =
        json.getRequiredStringOrThrow(Constants.ID, valueCanBeBlank = false)
}
