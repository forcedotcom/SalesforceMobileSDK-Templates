/*
 * Copyright (c) 2022-present, salesforce.com, inc.
 * All rights reserved.
 * Redistribution and use of this software in source and binary forms, with or
 * without modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * - Neither the name of salesforce.com, inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission of salesforce.com, inc.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject

import com.salesforce.androidsdk.mobilesync.target.SyncTarget
import com.salesforce.androidsdk.mobilesync.util.Constants
import org.json.JSONObject
import java.util.*

interface SObjectDeserializer<T : SObject> {
    @Throws(CoerceException::class)
    fun coerceFromJsonOrThrow(json: JSONObject): SObjectRecord<T>
}

abstract class SObjectDeserializerBase<T : SObject>(val objectType: String) :
    SObjectDeserializer<T> {

    @Throws(CoerceException::class)
    override fun coerceFromJsonOrThrow(json: JSONObject): SObjectRecord<T> {
        SObjectDeserializerHelper.requireSoType(json, objectType)

        val id = SObjectDeserializerHelper.getIdOrThrow(json)
        val syncState = json.coerceToSyncState()
        val model = buildModel(fromJson = json)

        return SObjectRecord(id = id, syncState = syncState, sObject = model)
    }

    @Throws(CoerceException::class)
    protected abstract fun buildModel(fromJson: JSONObject): T
}

/**
 * Convenience method for setting up a JSON with the properties required for all Salesforce Objects.
 *
 * This will create a local ID, add the correct object type, and set the correct combination of
 * local flags on the returned JSON, leaving the rest of the customization to the subclasses to implement.
 */
fun createNewSoupEltBase(forObjType: String): JSONObject {
    val attributes = JSONObject().put(Constants.TYPE.lowercase(Locale.US), forObjType)
    val id = SyncTarget.createLocalId()

    return JSONObject().apply {
        put(Constants.ID, id)
        put(Constants.ATTRIBUTES, attributes)
        put(SyncTarget.LOCALLY_CREATED, true)
        put(SyncTarget.LOCALLY_DELETED, false)
        put(SyncTarget.LOCALLY_UPDATED, false)
        put(SyncTarget.LOCAL, true)
    }
}
