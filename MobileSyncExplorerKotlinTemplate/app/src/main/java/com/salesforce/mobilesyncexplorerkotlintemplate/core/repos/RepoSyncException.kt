package com.salesforce.mobilesyncexplorerkotlintemplate.core.repos

import com.salesforce.mobilesyncexplorerkotlintemplate.core.CleanResyncGhostsException

sealed class SyncDownException : Exception() {
    data class FailedToFinish(
        override val cause: Throwable? = null,
        override val message: String? = null,
    ) : SyncDownException()

    data class FailedToStart(
        override val cause: Throwable? = null,
        override val message: String? = null,
    ) : SyncDownException()

    data class CleaningUpstreamRecordsFailed(
        override val cause: CleanResyncGhostsException?
    ) : SyncDownException() {
        override val message: String = "The incremental Sync Down operation succeeded, but some ghost records may still exist on the device"
    }
}

sealed class SyncUpException : Exception() {
    data class FailedToFinish(
        override val message: String? = null,
        override val cause: Throwable? = null
    ) : SyncUpException()

    data class FailedToStart(
        override val cause: Throwable? = null,
        override val message: String? = null
    ) : SyncUpException()
}
