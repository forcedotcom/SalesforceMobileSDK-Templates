package com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions

import com.salesforce.mobilesyncexplorerkotlintemplate.BuildConfig
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

fun Mutex.requireIsLocked() {
    require(isLocked) { "This operation is only permitted while this mutex is locked." }
}

/**
 * Convenience method for providing this coroutine context's [Job] as the default owner to the
 * [withLock] invocation if [BuildConfig.DEBUG] is `true`.
 *
 * This is SAFE to be used in production code because this will behave identically to [withLock] when
 * [BuildConfig.DEBUG] is false.
 *
 * Using the [Job] ensures that coroutines that attempt to re-acquire this [Mutex]'s lock will fail-
 * fast with an uncaught exception instead of silently dead-locking. Multiple coroutines contending
 * for the lock will behave as expected, suspending until it is unlocked. During development this can
 * greatly aid in debugging.
 *
 * @param owner An optional owner object you may specify to be used instead of the [Job].
 * @param action The action to take while under the lock.
 */
suspend inline fun <T> Mutex.withLockDebug(owner: Any? = null, action: () -> T): T {
    val debugOwner = owner ?: if (BuildConfig.DEBUG) currentCoroutineContext()[Job] else null

    return withLock(
        owner = debugOwner,
        action = action
    )
}
