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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions

import com.salesforce.mobilesyncexplorerkotlintemplate.BuildConfig
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

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
