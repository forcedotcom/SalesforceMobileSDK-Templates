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
    data class Finished<T : SObject>(val exception: RepoOperationException? = null) :
        UndeleteResponse<T>
}

class UndeleteUseCase<T : SObject>(private val repo: SObjectSyncableRepo<T>) {
    operator fun invoke(id: String): Flow<UndeleteResponse<T>> = runUndelete(id = id)

    private fun runUndelete(id: String): Flow<UndeleteResponse<T>> = flow {
        var exception: RepoOperationException? = null
        try {
            emit(UndeleteResponse.Started())

            val record = repo.locallyUndelete(id = id)

            emit(UndeleteResponse.UndeleteSuccess(record))

        } catch (ex: RepoOperationException) {
            exception = ex
        } finally {
            emit(UndeleteResponse.Finished(exception = exception))
        }
    }
}
