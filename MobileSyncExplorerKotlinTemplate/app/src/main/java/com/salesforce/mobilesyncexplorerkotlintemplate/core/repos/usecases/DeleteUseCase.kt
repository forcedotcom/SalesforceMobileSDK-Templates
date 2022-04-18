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
}

class DeleteUseCase<T : SObject>(private val repo: SObjectSyncableRepo<T>) {
    @Throws(RepoOperationException::class)
    operator fun invoke(id: String): Flow<DeleteResponse<T>> = runDelete(id = id)

    @Throws(RepoOperationException::class)
    private fun runDelete(id: String): Flow<DeleteResponse<T>> = flow {
        emit(DeleteResponse.Started())
        val record = repo.locallyDelete(id = id)
        emit(DeleteResponse.DeleteSuccess(record))
    }
}
