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

import com.salesforce.androidsdk.accounts.UserAccount
import com.salesforce.androidsdk.analytics.logger.SalesforceLogger
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
import com.salesforce.androidsdk.mobilesync.manager.SyncManager
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.*
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.Companion.LOCAL
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.Companion.LOCALLY_DELETED
import com.salesforce.androidsdk.mobilesync.target.SyncTarget.Companion.LOCALLY_UPDATED
import com.salesforce.androidsdk.mobilesync.util.Constants
import com.salesforce.androidsdk.mobilesync.util.SyncState
import com.salesforce.androidsdk.smartstore.store.QuerySpec
import com.salesforce.androidsdk.smartstore.store.SmartStore
import com.salesforce.mobilesyncexplorerkotlintemplate.appContext
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.*
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.*
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withContext
import org.json.JSONObject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * A base implementation of [SObjectSyncableRepo] for a single SObject of type [T].
 *
 * NB: Caution is advised when using this implementation at large scales because of the
 * [MutableSharedFlow] with _replay_. This hot [Flow] will keep the latest emission of records loaded
 * in-memory at all times, and for large numbers of records this can significantly impact memory
 * usage.
 */
abstract class SObjectSyncableRepoBase<T : SObject>(
    account: UserAccount,
    protected val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : SObjectSyncableRepo<T> {

    // region Public and Private Properties


    private val syncMutex = Mutex()
    private val listMutex = Mutex()

    private val mutRecordsById = mutableMapOf<String, SObjectRecord<T>>()

    /**
     * This is equivalent to a StateFlow that does not require an initial value.
     */
    private val mutState = MutableSharedFlow<Map<String, SObjectRecord<T>>>(
        replay = 1,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override val recordsById: Flow<Map<String, SObjectRecord<T>>> = mutState.distinctUntilChanged()

    protected val store: SmartStore = MobileSyncSDKManager.getInstance().getSmartStore(account)
    protected val syncManager: SyncManager = SyncManager.getInstance(account)
    protected val logger = SalesforceLogger.getLogger(COMPONENT_NAME, appContext)

    init {
        MobileSyncSDKManager.getInstance().apply {
            setupUserStoreFromDefaultConfig()
            setupUserSyncsFromDefaultConfig()
        }
    }

    protected abstract val soupName: String
    protected abstract val syncDownName: String
    protected abstract val syncUpName: String
    protected abstract val deserializer: SObjectDeserializer<T>


    // endregion
    // region Public Sync Implementation


    @Throws(
        SyncDownException::class,
        RepoOperationException.SmartStoreOperationFailed::class,
    )
    override suspend fun syncDown() = withContext(ioDispatcher) {
        syncMutex.withLockDebug {
            doSyncDown()
            try {
                syncManager.suspendCleanResyncGhosts(syncName = syncDownName)
            } catch (ex: SyncManager.CleanResyncGhostsException) {
                throw SyncDownException.CleaningUpstreamRecordsFailed(cause = ex)
            }
        }

        withContext(NonCancellable) { refreshRecordsListFromSmartStore() }
    }

    @Throws(SyncUpException::class)
    override suspend fun syncUp() = withContext(ioDispatcher) {
        syncMutex.withLockDebug { doSyncUp() }
        Unit
    }


    // endregion
    // region Private Sync Implementation


    @Throws(SyncDownException::class)
    private suspend fun doSyncDown(): SyncState {
        try {
            return syncManager.suspendReSync(syncDownName)
        } catch (es: SyncManager.ReSyncException.FailedToStart) {
            throw SyncDownException.FailedToStart(cause = es)
        } catch (ef: SyncManager.ReSyncException.FailedToFinish) {
            throw SyncDownException.FailedToFinish(cause = ef)
        }
    }

    @Throws(SyncUpException::class)
    private suspend fun doSyncUp(): SyncState {
        try {
            return syncManager.suspendReSync(syncUpName)
        } catch (es: SyncManager.ReSyncException.FailedToStart) {
            throw SyncUpException.FailedToStart(cause = es)
        } catch (ef: SyncManager.ReSyncException.FailedToFinish) {
            throw SyncUpException.FailedToFinish(cause = ef)
        }
    }

    // endregion
    // region Local Modifications


    @Throws(RepoOperationException::class)
    override suspend fun locallyUpdate(id: String, so: T) =
        withContext(ioDispatcher + NonCancellable) {
            val updateResult = doUpdateBlocking(id = id, so = so)

            val result = updateResult.coerceUpdatedObjToModelOrCleanupAndThrow()
            updateStateWithObject(result)
            result
        }

    @Throws(RepoOperationException::class)
    private fun doUpdateBlocking(id: String, so: T): JSONObject = synchronized(store.database) {
        store.beginTransaction()

        try {
            val retrievedElt = retrieveByIdOrThrowOperationException(id = id).elt
            val retrievedAsRecord = deserializer.coerceFromJsonOrThrow(retrievedElt)

            if (retrievedAsRecord.sObject == so) {
                return@synchronized retrievedElt
            }

            with(so) {
                retrievedElt
                    .applyObjProperties()
                    .apply {
                        put(LOCALLY_UPDATED, true)
                        put(LOCAL, true)
                    }
            }

            val result = try {
                store.upsert(soupName, retrievedElt)!!
            } catch (ex: Exception) {
                throw RepoOperationException.SmartStoreOperationFailed(
                    message = "Failed to update the object in SmartStore.",
                    cause = ex
                )
            }

            store.setTransactionSuccessful()

            result
        } finally {
            store.endTransaction()
        }
    }

    @Throws(RepoOperationException::class)
    override suspend fun locallyCreate(so: T): SObjectRecord<T> =
        withContext(ioDispatcher + NonCancellable) {
            val createResult = try {
                val elt = with(so) {
                    createNewSoupEltBase(forObjType = objectType)
                        .applyObjProperties()
                }

                store.upsert(soupName, elt)!!
            } catch (ex: Exception) {
                throw RepoOperationException.SmartStoreOperationFailed(
                    message = "Failed to create the object in SmartStore.",
                    cause = ex
                )
            }

            val result = createResult.coerceUpdatedObjToModelOrCleanupAndThrow()
            updateStateWithObject(result)
            result
        }

    @Throws(RepoOperationException::class)
    override suspend fun locallyDelete(id: String) =
        withContext(ioDispatcher + NonCancellable) {

            val so = doDeleteBlocking(id = id)
                ?.coerceUpdatedObjToModelOrCleanupAndThrow()

            if (so == null) {
                removeAllFromObjectList(listOf(id))
            } else {
                updateStateWithObject(so)
            }

            so
        }

    @Throws(RepoOperationException::class)
    private fun doDeleteBlocking(id: String): JSONObject? = synchronized(store.database) {
        store.beginTransaction()

        try {
            val retrieved = retrieveByIdOrThrowOperationException(id)
            val localStatus = retrieved.elt.coerceToSyncState()

            val result = when {
                localStatus.isLocallyCreated -> {
                    try {
                        store.delete(soupName, retrieved.soupId)
                    } catch (ex: Exception) {
                        throw RepoOperationException.SmartStoreOperationFailed(
                            message = "Failed deleting locally-created object. SmartStore.delete(soupName=$soupName, soupId=${retrieved.soupId}) threw an exception.",
                            cause = ex
                        )
                    }
                    null
                }

                localStatus.isLocallyDeleted -> retrieved.elt

                else -> {
                    retrieved.elt
                        .putOpt(LOCALLY_DELETED, true)
                        .putOpt(LOCAL, true)

                    try {
                        store.update(soupName, retrieved.elt, retrieved.soupId)!!
                    } catch (ex: Exception) {
                        throw RepoOperationException.SmartStoreOperationFailed(
                            message = "Locally-delete operation failed. Could not save the updated object in SmartStore.",
                            cause = ex
                        )
                    }
                }
            }

            store.setTransactionSuccessful()
            result
        } finally {
            store.endTransaction()
        }
    }

    @Throws(RepoOperationException::class)
    override suspend fun locallyUndelete(id: String) =
        withContext(ioDispatcher + NonCancellable) {

            val updatedJson = doUndeleteBlocking(id = id)

            val result = updatedJson.coerceUpdatedObjToModelOrCleanupAndThrow()
            updateStateWithObject(result)

            result
        }

    @Throws(RepoOperationException::class)
    private fun doUndeleteBlocking(id: String): JSONObject = synchronized(store.database) {
        store.beginTransaction()

        try {
            val retrieved = retrieveByIdOrThrowOperationException(id)
            val curLocalStatus = retrieved.elt.coerceToSyncState()

            if (!curLocalStatus.isLocallyDeleted) {
                store.setTransactionSuccessful()
                return@synchronized retrieved.elt
            }

            retrieved.elt
                .putOpt(LOCALLY_DELETED, false)
                .putOpt(
                    LOCAL,
                    curLocalStatus.isLocallyCreated || curLocalStatus.isLocallyUpdated
                )

            try {
                val result = store.update(soupName, retrieved.elt, retrieved.soupId)!!
                store.setTransactionSuccessful()
                result
            } catch (ex: Exception) {
                throw RepoOperationException.SmartStoreOperationFailed(
                    message = "Locally-undelete operation failed. Could not save the updated object in SmartStore.",
                    cause = ex
                )
            }
        } finally {
            store.endTransaction()
        }
    }


    // endregion
    // region Protected Store Operations


    @Throws(RepoOperationException.SmartStoreOperationFailed::class)
    override suspend fun refreshRecordsListFromSmartStore(): Unit = withContext(ioDispatcher) {
        val (parseSuccesses, parseFailures) = runFetchAllQuery()
        val messages = parseFailures.mapNotNull { it.message }
        logger.e(
            TAG,
            "There were parse failures from the contacts soup: $messages"
        )
        setRecordsList(parseSuccesses)
    }

    protected suspend fun setRecordsList(records: List<SObjectRecord<T>>) =
        listMutex.withLockDebug {
            mutRecordsById.clear()
            records.associateByTo(mutRecordsById) { it.id }
            mutState.emit(mutRecordsById.toMap())
        }

    @Throws(RepoOperationException.SmartStoreOperationFailed::class)
    protected suspend fun runFetchAllQuery(): ResultPartition<SObjectRecord<T>> =
        withContext(ioDispatcher) {
            val queryResults = try {
                store.query(
                    QuerySpec.buildAllQuerySpec(
                        soupName,
                        null,
                        null,
                        10_000
                    ),
                    0
                )
            } catch (ex: Exception) {
                throw RepoOperationException.SmartStoreOperationFailed(
                    message = "Failed to refresh the repo objects list. The objects list may be out of date with SmartStore.",
                    cause = ex
                )
            }

            queryResults
                .map { runCatching { deserializer.coerceFromJsonOrThrow(it) } }
                .partitionBySuccess()
        }


    // endregion
    // region Convenience Methods


    /**
     * Convenience method for running an object list update procedure while under the Mutex for said
     * list. Also eliminates the need for subclasses to handle Mutexes themselves.
     */
    protected suspend fun updateStateWithObject(obj: SObjectRecord<T>): Unit =
        listMutex.withLockDebug {
            mutRecordsById[obj.id] = obj
            mutState.emit(mutRecordsById.toMap())
        }

    /**
     * Convenience method for running an object list update procedure while under the Mutex for said
     * list. Also eliminates the need for subclasses to handle Mutexes themselves.
     */
    protected suspend fun removeAllFromObjectList(ids: List<String>) {
        listMutex.withLockDebug {
            for (id in ids) {
                mutRecordsById.remove(id)
            }
            mutState.emit(mutRecordsById.toMap())
        }
    }

    /**
     * Convenience method for the common procedure of trying to coerce the SmartStore updated object
     * to a model while catching the coerce exception and removing that object from the objects list
     * to maintain data integrity.
     */
    @Throws(RepoOperationException.InvalidResultObject::class)
    protected suspend fun JSONObject.coerceUpdatedObjToModelOrCleanupAndThrow() = try {
        deserializer.coerceFromJsonOrThrow(this)
    } catch (ex: Exception) {
        val ids = mutableListOf<String>()
        this.optStringOrNull(Constants.ID)?.also { ids.add(it) }

        removeAllFromObjectList(ids)

        throw RepoOperationException.InvalidResultObject(
            message = "SmartStore operation was successful, but failed to deserialize updated JSON. This object has been removed from the list of objects in this repo to preserve data integrity",
            cause = ex
        )
    }

    /**
     * Convenience method for the common procedure of trying to retrieve a single object by its ID
     * or throwing the corresponding exception.
     */
    @Throws(
        RepoOperationException.RecordNotFound::class,
        RepoOperationException.SmartStoreOperationFailed::class,
    )
    protected fun retrieveByIdOrThrowOperationException(id: String) = try {
        store.retrieveSingleById(soupName = soupName, idColName = Constants.ID, id = id)
    } catch (ex: NoSuchElementException) {
        throw RepoOperationException.RecordNotFound(id = id, soupName = soupName, cause = ex)
    } catch (ex: IllegalArgumentException) {
        throw RepoOperationException.SmartStoreOperationFailed(message = ex.message, cause = ex)
    }


    // endregion

    private companion object {
        private const val COMPONENT_NAME = "SObjectSyncableRepo"
        private const val TAG = "SObjectSyncableRepoBase"
    }
}
