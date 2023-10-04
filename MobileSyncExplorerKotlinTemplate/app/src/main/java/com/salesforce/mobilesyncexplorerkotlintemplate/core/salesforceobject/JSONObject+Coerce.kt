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

import com.salesforce.androidsdk.mobilesync.target.SyncTarget.*
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.Companion.LOCALLY_CREATED
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.Companion.LOCALLY_DELETED
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.Companion.LOCALLY_UPDATED
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

@Throws(CoerceException::class)
fun JSONObject.getRequiredStringOrThrow(key: String, valueCanBeBlank: Boolean = true): String =
    try {
        val value = this.getString(key)
        if (!valueCanBeBlank) {
            value.ifBlank {
                throw InvalidPropertyValue(
                    propertyKey = key,
                    allowedValuesDescription = "$key must not be blank.",
                    offendingJsonString = this.toString()
                )
            }
        }

        value
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

@Throws(CoerceException::class)
fun JSONObject.getRequiredIntOrThrow(key: String): Int =
    try {
        this.getInt(key)
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

@Throws(CoerceException::class)
fun JSONObject.getRequiredLongOrThrow(key: String): Long =
    try {
        this.getLong(key)
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

@Throws(CoerceException::class)
fun JSONObject.getRequiredDoubleOrThrow(key: String): Double =
    try {
        this.getDouble(key)
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

@Throws(CoerceException::class)
fun JSONObject.getRequiredBooleanOrThrow(key: String): Boolean =
    try {
        this.getBoolean(key)
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

@Throws(CoerceException::class)
fun JSONObject.getRequiredObjectOrThrow(key: String): JSONObject =
    try {
        this.getJSONObject(key)
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

@Throws(CoerceException::class)
fun JSONObject.getRequiredArrayOrThrow(key: String): JSONArray =
    try {
        this.getJSONArray(key)
    } catch (ex: JSONException) {
        throw MissingRequiredProperties(propertyKeys = arrayOf(key), offendingJsonString = this.toString())
    }

fun JSONObject.coerceToSyncState(): SObjectSyncState {
    val locallyCreated: Boolean = optBoolean(LOCALLY_CREATED, false)
    val locallyDeleted: Boolean = optBoolean(LOCALLY_DELETED, false)
    val locallyUpdated: Boolean = optBoolean(LOCALLY_UPDATED, false)

    return when {
        locallyDeleted -> {
            if (locallyUpdated) SObjectSyncState.LocallyDeletedAndLocallyUpdated
            else SObjectSyncState.LocallyDeleted
        }
        locallyCreated -> SObjectSyncState.LocallyCreated
        locallyUpdated -> SObjectSyncState.LocallyUpdated
        else -> SObjectSyncState.MatchesUpstream
    }
}
