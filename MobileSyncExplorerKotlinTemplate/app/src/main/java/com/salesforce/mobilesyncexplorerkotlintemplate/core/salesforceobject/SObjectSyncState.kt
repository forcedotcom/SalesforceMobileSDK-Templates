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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject

/**
 * Enum representing all the possible sync states of a record in SmartStore. These are created to map
 * to all the allowed combinations of the `__LOCAL*__` flags added by MobileSync to records in
 * SmartStore. It purposefully does not expose individual flag values by themselves as this would be
 * a leak of implementation details that business and UI logic should not have to worry about.
 */
enum class SObjectSyncState {
    LocallyCreated,
    LocallyDeleted,
    LocallyUpdated,
    LocallyDeletedAndLocallyUpdated,
    MatchesUpstream
}

/**
 * Convenience property for whether the sync state of a record indicates it has been locally created.
 * This exists mainly for declarative use of [SObjectSyncState] in conditional statements.
 */
val SObjectSyncState.isLocallyCreated: Boolean
    get() = when (this) {
        SObjectSyncState.LocallyCreated -> true
        SObjectSyncState.LocallyDeleted -> false
        SObjectSyncState.LocallyUpdated -> false
        SObjectSyncState.LocallyDeletedAndLocallyUpdated -> false
        SObjectSyncState.MatchesUpstream -> false
    }

/**
 * Convenience property for whether the sync state of a record indicates it has been locally deleted.
 * This exists mainly for declarative use of [SObjectSyncState] in conditional statements.
 */
val SObjectSyncState.isLocallyDeleted: Boolean
    get() = when (this) {
        SObjectSyncState.LocallyCreated -> false
        SObjectSyncState.LocallyDeleted -> true
        SObjectSyncState.LocallyUpdated -> false
        SObjectSyncState.LocallyDeletedAndLocallyUpdated -> true
        SObjectSyncState.MatchesUpstream -> false
    }

/**
 * Convenience property for whether the sync state of a record indicates it has been locally updated.
 * This exists mainly for declarative use of [SObjectSyncState] in conditional statements.
 */
val SObjectSyncState.isLocallyUpdated: Boolean
    get() = when (this) {
        SObjectSyncState.LocallyCreated -> false
        SObjectSyncState.LocallyDeleted -> false
        SObjectSyncState.LocallyUpdated -> true
        SObjectSyncState.LocallyDeletedAndLocallyUpdated -> true
        SObjectSyncState.MatchesUpstream -> false
    }
