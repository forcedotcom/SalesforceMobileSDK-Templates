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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions

import com.salesforce.androidsdk.smartstore.store.SmartStore
import org.json.JSONObject

/**
 * Convenience method to return a single SmartStore Soup ELT by an arbitrary ID column.
 *
 * @throws NoSuchElementException If the ELT could not be found.
 * @throws IllegalArgumentException If more than one ELT was found for the given [id] and [idColName], or the ELT could not be retrieved due to a SmartStore error.
 */
@Throws(
    NoSuchElementException::class,
    IllegalArgumentException::class
)
fun SmartStore.retrieveSingleById(
    soupName: String,
    idColName: String,
    id: String
): RetrievedSoupElt = synchronized(database) {
    beginTransaction()

    try {
        val soupIdResult = runCatching { lookupSoupEntryId(soupName, idColName, id) }

        soupIdResult.exceptionOrNull()?.let {
            throw IllegalArgumentException(
                "Could not retrieve single soup ID for provided ID=$id and column name=$idColName",
                it
            )
        }

        val soupId = soupIdResult.getOrThrow()

        val result = if (soupId < 0) {
            throw NoSuchElementException("id=$id was not found in soup $soupName")
        } else {
            val results = runCatching { retrieve(soupName, soupId) }

            results.exceptionOrNull()?.let {
                throw IllegalArgumentException(
                    "Could not retrieve single soup ID for provided ID=$id and column name=$idColName",
                    it
                )
            }

            RetrievedSoupElt(
                elt = results.getOrThrow().first(), // either succeeds or throws appropriate exception
                soupId = soupId
            )
        }

        setTransactionSuccessful()
        result
    } finally {
        endTransaction()
    }
}

data class RetrievedSoupElt(val elt: JSONObject, val soupId: Long)
