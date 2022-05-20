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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.repos

import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObject
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import kotlinx.coroutines.flow.Flow

/**
 * Core interface for all Repos which handle CRUD and sync operations for a single SObject [T].
 *
 * This interface purposefully does not expose a "get by ID" API. The emissions via [recordsById]
 * represent the current snapshot of the records in SmartStore and should be responded to in a
 * reactive manner.
 */
interface SObjectSyncableRepo<T : SObject> {
    /**
     * The most recent snapshot of all records in SmartStore for the given SObject [T] mapped to
     * their IDs. The [SObjectRecord] class already has an ID property, but by creating a JVM [Map]
     * of the potentially large amount of records, downstream collectors can access records by their
     * IDs in constant time instead of O(N) time.
     */
    val recordsById: Flow<Map<String, SObjectRecord<T>>>

    /**
     * Performs a full sync down -- including cleaning resync ghosts -- for the Sync Target defined
     * in `usersyncs.json` for the SObject [T].
     */
    @Throws(
        SyncDownException::class,
        RepoOperationException.SmartStoreOperationFailed::class,
    )
    suspend fun syncDown()

    /**
     * Performs a full sync up for the Sync Target defined in `usersyncs.json` for the SObject [T].
     */
    @Throws(SyncUpException::class)
    suspend fun syncUp()

    /**
     * Performs an update (NB _not_ upsert) operation by applying the properties of the provided [so]
     * to the record with the provided [id] in SmartStore. This only affects SmartStore, and so changes
     * to records will not be reflected in the Org until [syncUp] is performed.
     *
     * @return The updated record from SmartStore.
     */
    @Throws(RepoOperationException::class)
    suspend fun locallyUpdate(id: String, so: T): SObjectRecord<T>

    /**
     * Performs a create operation in SmartStore, creating a new SObject of type [T] with the
     * properties of the provided [so]. This only affects SmartStore, and so changes to records will
     * not be reflected in the Org until [syncUp] is performed.
     *
     * @return The newly created record from SmartStore.
     */
    @Throws(RepoOperationException::class)
    suspend fun locallyCreate(so: T): SObjectRecord<T>

    /**
     * Does one of two things:
     *
     * If the record with the provided [id] exists in the Org, this method marks that record for
     * deletion upon next sync up. This operation is reversible via [locallyUndelete].
     *
     * OR
     *
     * If the record with the provided [id] was created locally on this device and has not yet been
     * synced up, this method will permanently delete the record from SmartStore. This operation is
     * _not_ reversible.
     *
     * @return The record with updated deleted status set to true, or null if the record was permanently deleted from SmartStore.
     */
    @Throws(RepoOperationException::class)
    suspend fun locallyDelete(id: String): SObjectRecord<T>?

    /**
     * Marks the record with the provided [id] as _not_ locally deleted. If the record is not marked
     * for deletion, this method does nothing.
     *
     * @return The record with the updated deleted status set to false.
     */
    @Throws(RepoOperationException::class)
    suspend fun locallyUndelete(id: String): SObjectRecord<T>

    /**
     * Forces a full refresh of the records from the soup containing records for SObject [T]. Useful
     * for initial fetching of records after a Repo instance has been created. This is a heavy
     * operation, so use it sparingly.
     */
    @Throws(RepoOperationException.SmartStoreOperationFailed::class)
    suspend fun refreshRecordsListFromSmartStore()
}
