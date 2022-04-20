package com.salesforce.mobilesyncexplorerkotlintemplate.core.repos

import com.salesforce.mobilesyncexplorerkotlintemplate.core.CleanResyncGhostsException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObject
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import kotlinx.coroutines.flow.Flow

/**
 * This interface purposefully does not expose a "get by ID" API. The emissions via [recordsById]
 * represent the current snapshot of the records in SmartStore and should be responded to in a
 * reactive manner.  In highly parallel environments it is possible that the "get by ID" API would
 * return inconsistent results.
 */
interface SObjectSyncableRepo<T : SObject> {
    val recordsById: Flow<Map<String, SObjectRecord<T>>>

    @Throws(
        SyncDownException::class,
        RepoOperationException.SmartStoreOperationFailed::class,
    )
    suspend fun syncDown()

    @Throws(SyncUpException::class)
    suspend fun syncUp()

    @Throws(RepoOperationException::class)
    suspend fun locallyUpdate(id: String, so: T): SObjectRecord<T>

    @Throws(RepoOperationException::class)
    suspend fun locallyCreate(so: T): SObjectRecord<T>

    @Throws(RepoOperationException::class)
    suspend fun locallyDelete(id: String): SObjectRecord<T>?

    @Throws(RepoOperationException::class)
    suspend fun locallyUndelete(id: String): SObjectRecord<T>

    @Throws(RepoOperationException.SmartStoreOperationFailed::class)
    suspend fun refreshRecordsListFromSmartStore()
}
