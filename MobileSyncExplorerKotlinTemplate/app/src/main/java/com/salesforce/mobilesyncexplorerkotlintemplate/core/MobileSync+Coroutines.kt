package com.salesforce.mobilesyncexplorerkotlintemplate.core

import com.salesforce.androidsdk.mobilesync.manager.SyncManager
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

@Throws(CleanResyncGhostsException::class)
suspend fun SyncManager.suspendCleanResyncGhosts(syncName: String) = withContext(NonCancellable) {
    suspendCoroutine<Int> { cont ->
        val callback = object : SyncManager.CleanResyncGhostsCallback {
            override fun onSuccess(numRecords: Int) {
                cont.resume(numRecords)
            }

            override fun onError(e: java.lang.Exception) {
                cont.resumeWithException(
                    CleanResyncGhostsException.FailedToFinish(
                        message = "Clean Resync Ghosts failed to run to completion",
                        cause = e
                    )
                )
            }
        }

        try {
            cleanResyncGhosts(syncName, callback)
        } catch (ex: Exception) {
            throw CleanResyncGhostsException.FailedToStart(
                message = "Clean Resync Ghosts operation failed to start",
                cause = ex
            )
        }
    }
}

sealed class CleanResyncGhostsException : Exception() {
    data class FailedToFinish(
        override val message: String?,
        override val cause: Throwable? = null
    ) : CleanResyncGhostsException()

    data class FailedToStart(
        override val message: String?,
        override val cause: Throwable?
    ) : CleanResyncGhostsException()
}
