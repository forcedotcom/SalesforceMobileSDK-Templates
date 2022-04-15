package com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.usecases

import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.RepoOperationException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SObjectSyncableRepo
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObject
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

sealed interface DeleteResponse<T : SObject> {
    class Started<T : SObject> : DeleteResponse<T>
    data class DeleteSuccess<T : SObject>(val record: SObjectRecord<T>?) : DeleteResponse<T>
    data class Finished<T : SObject>(val exception: RepoOperationException? = null) :
        DeleteResponse<T>
}

class DeleteUseCase<T : SObject>(private val repo: SObjectSyncableRepo<T>) {
    operator fun invoke(id: String): Flow<DeleteResponse<T>> = runDelete(id = id)

    private fun runDelete(id: String): Flow<DeleteResponse<T>> = flow {
        var exception: RepoOperationException? = null
        try {
            emit(DeleteResponse.Started())

            val record = repo.locallyDelete(id = id)

            emit(DeleteResponse.DeleteSuccess(record))

        } catch (ex: RepoOperationException) {
            exception = ex
        } finally {
            emit(DeleteResponse.Finished(exception = exception))
        }
    }
}
