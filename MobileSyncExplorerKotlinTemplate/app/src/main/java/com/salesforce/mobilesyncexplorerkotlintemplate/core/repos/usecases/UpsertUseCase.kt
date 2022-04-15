package com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.usecases

import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.RepoOperationException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SObjectSyncableRepo
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObject
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

sealed interface UpsertResponse<T : SObject> {
    class Started<T : SObject> : UpsertResponse<T>
    data class UpsertSuccess<T : SObject>(val record: SObjectRecord<T>) : UpsertResponse<T>
    data class Finished<T : SObject>(val exception: RepoOperationException? = null) :
        UpsertResponse<T>
}

class UpsertUseCase<T : SObject>(private val repo: SObjectSyncableRepo<T>) {
    operator fun invoke(id: String?, so: T): Flow<UpsertResponse<T>> = runUpsert(id = id, so = so)

    private fun runUpsert(id: String?, so: T): Flow<UpsertResponse<T>> = flow {
        var exception: RepoOperationException? = null
        try {
            emit(UpsertResponse.Started())

            val record = if (id == null) {
                repo.locallyCreate(so = so)
            } else {
                repo.locallyUpdate(id = id, so = so)
            }

            emit(UpsertResponse.UpsertSuccess(record))

        } catch (ex: RepoOperationException) {
            exception = ex
        } finally {
            emit(UpsertResponse.Finished(exception = exception))
        }
    }
}
