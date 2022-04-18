package com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.usecases

import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.RepoOperationException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SObjectSyncableRepo
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObject
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

sealed interface UndeleteResponse<T : SObject> {
    class Started<T : SObject> : UndeleteResponse<T>
    data class UndeleteSuccess<T : SObject>(val record: SObjectRecord<T>) : UndeleteResponse<T>
}

class UndeleteUseCase<T : SObject>(private val repo: SObjectSyncableRepo<T>) {
    @Throws(RepoOperationException::class)
    operator fun invoke(id: String): Flow<UndeleteResponse<T>> = runUndelete(id = id)

    @Throws(RepoOperationException::class)
    private fun runUndelete(id: String): Flow<UndeleteResponse<T>> = flow {
        emit(UndeleteResponse.Started())
        val record = repo.locallyUndelete(id = id)
        emit(UndeleteResponse.UndeleteSuccess(record))

    }
}
