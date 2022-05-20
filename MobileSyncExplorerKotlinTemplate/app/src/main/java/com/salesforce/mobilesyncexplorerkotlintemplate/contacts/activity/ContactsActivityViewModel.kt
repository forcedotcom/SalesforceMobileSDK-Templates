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
package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salesforce.androidsdk.accounts.UserAccount
import com.salesforce.androidsdk.analytics.logger.SalesforceLogger
import com.salesforce.mobilesyncexplorerkotlintemplate.R.string.*
import com.salesforce.mobilesyncexplorerkotlintemplate.appContext
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.activity.ContactsActivityMessages.*
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsComponentClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.copy
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.removeNewlineChars
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.removeTabChars
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.withLockDebug
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.RepoOperationException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SyncDownException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SyncUpException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.*
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.sync.Mutex
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

/**
 * The combination of UI state and interaction handling exposed to the Compose framework for the
 * [ContactsActivity].
 */
interface ContactsActivityUiInteractor {
    val activityUiState: StateFlow<ContactsActivityUiState>
    val detailsUiState: StateFlow<ContactDetailsUiState>
    val listUiState: StateFlow<ContactsListUiState>

    /**
     * Flow of alert messages to show to the user. Usually emissions are in response to exceptions.
     */
    val messages: Flow<ContactsActivityMessages>

    val detailsClickHandler: ContactDetailsComponentClickHandler
    val listClickHandler: ContactsListClickHandler
}

/**
 * The ViewModel declaration for [ContactsActivity], exposing functionality specifically for the
 * Activity to use so as to keep certain things unavailable to the Compose UI.
 */
interface ContactsActivityViewModel : ContactsActivityUiInteractor {
    /**
     * [StateFlow] indicating whether UI components in this Activity should handle the back button
     * instead of the system. Used to drive enabling of registered back handlers.
     */
    val isHandlingBackEvents: StateFlow<Boolean>

    /**
     * Used in response to user switched events to recreate all data-layer objects using the new
     * account. Must also be called when the initial user is provided after login.
     */
    fun switchUser(newUser: UserAccount)

    /**
     * Performs a sync up and sync down for contacts.
     */
    fun fullSync()
    fun handleBackClick()
}

/**
 * Default implementation of the [ContactsActivityViewModel]. This is one interpretation for how to
 * implement the user task of, "I want to view and edit the contacts in my Org" by coupling the
 * Contacts List component to the Contact Details component.
 *
 * This implementation is complex, but many of the patterns used could be abstracted to common base
 * classes if similar list-detail tasks are needed.
 *
 * The key pattern used here is the [eventMutex]. The asynchronous nature of Repo operations, record
 * emissions, and UI interactions means concurrent programming must be the primary concern for this
 * View Model. [eventMutex] is the gatekeeper for all asynchronous event handling by locking the
 * entire View Model's state to only handle one event at a time. This effectively serializes the
 * asynchronous events that this View Model handles, thus vastly simplifying internal state mutation
 * logic.
 */
class DefaultContactsActivityViewModel : ViewModel(), ContactsActivityViewModel {

    private val logger = SalesforceLogger.getLogger(ContactsActivity.COMPONENT_NAME, appContext)
    private val detailsVm = DefaultContactDetailsViewModel()
    private val listVm = DefaultContactsListViewModel()

    override val detailsUiState: StateFlow<ContactDetailsUiState> get() = detailsVm.uiState
    override val listUiState: StateFlow<ContactsListUiState> get() = listVm.uiState
    override val detailsClickHandler: ContactDetailsComponentClickHandler get() = detailsVm
    override val listClickHandler: ContactsListClickHandler get() = listVm

    /**
     * Acquire this lock and hold it for the entire time you are handling an event. Events are
     * anything asynchronous like user input events and repo data emissions.
     *
     * Serializing event handling allows the rest of the private implementation to safely mutate
     * internal state as needed without concurrency worries.
     */
    private val eventMutex = Mutex()
    private val mutActivityUiState = MutableStateFlow(
        ContactsActivityUiState(isSyncing = false, dataOpIsActive = false, dialogUiState = null)
    )
    override val activityUiState: StateFlow<ContactsActivityUiState> get() = mutActivityUiState

    // This checks the status of the back handlers each time the components' UI state changes:
    override val isHandlingBackEvents: StateFlow<Boolean> =
        detailsVm.uiState
            .combine(listVm.uiState) { _, _ -> detailsVm.willHandleBack || listVm.willHandleBack }
            .stateIn(
                scope = viewModelScope,
                started = SharingStarted.Lazily,
                initialValue = detailsVm.willHandleBack || listVm.willHandleBack
            )

    private val mutMessages = MutableSharedFlow<ContactsActivityMessages>(
        extraBufferCapacity = 1,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    override val messages: Flow<ContactsActivityMessages> get() = mutMessages

    /**
     * The Repo record emissions captured by reference. It is faster to simply set the variable by
     * reference than to replace all the content in a mutable map.
     */
    @Volatile
    private var curRecordsByIds: Map<String, ContactRecord> = emptyMap()

    /**
     * Flag preventing handling of events until the first user account is provided after initial
     * login.
     */
    @Volatile
    private var hasInitialAccount = false

    /**
     * This can only be initialized once we have a [UserAccount], so it is lateinit.
     */
    @Volatile
    private lateinit var contactsRepo: ContactsRepo

    @Volatile
    private var curUser: UserAccount? = null

    @Volatile
    private var repoCollectorJob: Job? = null

    override fun switchUser(newUser: UserAccount) {
        viewModelScope.launch {
            eventMutex.withLockDebug {
                if (curUser == newUser)
                    return@launch

                repoCollectorJob?.cancelAndJoin()

                curUser = newUser
                contactsRepo = DefaultContactsRepo(account = newUser)

                detailsVm.reset()
                listVm.reset()

                contactsRepo.refreshRecordsListFromSmartStore()

                repoCollectorJob = viewModelScope.launch {
                    contactsRepo.recordsById.collect { records ->
                        eventMutex.withLockDebug {
                            curRecordsByIds = records
                            detailsVm.onRecordsEmitted()
                            listVm.onRecordsEmitted()
                        }
                    }
                }

                hasInitialAccount = true

                // Always do a full sync when the user changes to ensure all data is up-to-date:
                fullSync()
            }
        }
    }

    override fun fullSync() {
        viewModelScope.launch {
            /* Only perform the UI state update within the event lock. Otherwise the user input will
             * be unresponsive during the long-running sync operations. This is okay because the user
             * can continue to interact with the current list of records without affecting the sync
             * operation. */
            eventMutex.withLockDebug {
                mutActivityUiState.value = activityUiState.value.copy(isSyncing = true)
            }

            val syncUpSuccess = try {
                contactsRepo.syncUp()
                true
            } catch (ex: SyncUpException) {
                logger.e(TAG, ex.toString())

                when (ex) {
                    is SyncUpException.FailedToFinish -> SyncUpFinishFailed
                    is SyncUpException.FailedToStart -> SyncUpStartFailed
                }.also {
                    mutMessages.tryEmit(it)
                }

                false
            }

            if (syncUpSuccess) {
                try {
                    contactsRepo.syncDown()
                } catch (ex: SyncDownException) {
                    logger.e(TAG, ex.toString())

                    when (ex) {
                        is SyncDownException.CleaningUpstreamRecordsFailed -> CleanGhostsFailed
                        is SyncDownException.FailedToFinish -> SyncDownFinishFailed
                        is SyncDownException.FailedToStart -> SyncDownStartFailed
                    }.also {
                        mutMessages.tryEmit(it)
                    }
                } catch (ex: RepoOperationException.SmartStoreOperationFailed) {
                    logger.e(TAG, ex.toString())
                    mutMessages.tryEmit(RepoRefreshFailed)
                }
            }

            eventMutex.withLockDebug {
                mutActivityUiState.value = activityUiState.value.copy(isSyncing = false)
            }
        }
    }

    override fun handleBackClick() = safeHandleUiEvent {
        if (isHandlingBackEvents.value) {
            detailsVm.onBackPressed() // list does not handle back click
        }
    }

    private suspend fun setContactWithConfirmation(contactId: String?, editing: Boolean) {
        if (activityUiState.value.dataOpIsActive) {
            mutMessages.tryEmit(WaitForDataOpToFinish)
            return
        }

        val record = contactId?.let { curRecordsByIds[contactId] }

        /* This wraps the discard changes dialog in a coroutine so that the method only continues
         * once the user has made a selection. THIS KEEPS THE EVENT MUTEX LOCKED UNTIL THE USER
         * MAKES A CHOICE. It is okay to do this because the dialog will take over the screen, not
         * allowing any other user interaction until they make a decision.
         *
         * It also prevents the VM from reacting to any record emissions from the data layer until
         * the user makes a choice, and this too is a good thing. Changing the data displayed in the
         * UI while there is an alert dialog present may lead to the user's choice having unintended
         * side-effects. */
        val mayContinue = !detailsVm.hasUnsavedChanges || suspendCoroutine { cont ->
            val discardChangesDialog = DiscardChangesDialogUiState(
                onCancelDiscardChanges = { cont.resume(value = false) },
                onConfirmDiscardChanges = { cont.resume(value = true) },
            )

            mutActivityUiState.value = activityUiState.value.copy(
                dialogUiState = discardChangesDialog
            )
        }

        dismissCurDialog()

        if (mayContinue) {
            detailsVm.clobberRecord(record = record, editing = editing)
            listVm.setSelectedContact(id = contactId)
        }
    }

    private suspend fun runUpdateOp(idToUpdate: String, so: ContactObject) {
        if (activityUiState.value.dataOpIsActive) {
            mutMessages.tryEmit(WaitForDataOpToFinish)
            return
        }

        withDataOpActiveUiState {
            try {
                val updatedRecord = contactsRepo.locallyUpdate(id = idToUpdate, so = so)
                if (detailsVm.uiState.value.recordId == idToUpdate) {
                    detailsVm.clobberRecord(record = updatedRecord, editing = false)
                }
            } catch (ex: RepoOperationException) {
                logger.e(TAG, ex.toString())

                when (ex) {
                    is RepoOperationException.InvalidResultObject,
                    is RepoOperationException.RecordNotFound,
                    is RepoOperationException.SmartStoreOperationFailed -> UpdateOperationFailed
                }.also {
                    mutMessages.tryEmit(it)
                }
            }
        }
    }

    private suspend fun runCreateOp(so: ContactObject) {
        if (activityUiState.value.dataOpIsActive) {
            mutMessages.tryEmit(WaitForDataOpToFinish)
            return
        }

        withDataOpActiveUiState {
            try {
                val newRecord = contactsRepo.locallyCreate(so = so)
                if (detailsVm.uiState.value.recordId == null && detailsVm.uiState.value !is ContactDetailsUiState.NoContactSelected) {
                    detailsVm.clobberRecord(record = newRecord, editing = false)
                }
            } catch (ex: RepoOperationException) {
                logger.e(TAG, ex.toString())

                when (ex) {
                    is RepoOperationException.InvalidResultObject,
                    is RepoOperationException.RecordNotFound,
                    is RepoOperationException.SmartStoreOperationFailed -> UpdateOperationFailed
                }.also {
                    mutMessages.tryEmit(it)
                }
            }
        }
    }

    private suspend fun runDeleteOpWithConfirmation(idToDelete: String) {
        if (activityUiState.value.dataOpIsActive) {
            mutMessages.tryEmit(WaitForDataOpToFinish)
            return
        }

        /* This wraps the delete dialog in a coroutine so that the method only continues once the
         * user has made a selection. THIS KEEPS THE EVENT MUTEX LOCKED UNTIL THE USER MAKES A CHOICE.
         * It is okay to do this because the dialog will take over the screen, not allowing any other
         * user interaction until they make a decision.
         *
         * It also prevents the VM from reacting to any record emissions from the data layer until
         * the user makes a choice, and this too is a good thing. Changing the data displayed in the
         * UI while there is an alert dialog present may lead to the user's choice having unintended
         * side-effects. */
        val confirmed = suspendCoroutine<Boolean> { cont ->
            val deleteDialog = DeleteConfirmationDialogUiState(
                objIdToDelete = idToDelete,
                objName = curRecordsByIds[idToDelete]?.sObject?.fullName,
                onCancelDelete = { cont.resume(value = false) },
                onConfirmDelete = { cont.resume(value = true) }
            )

            mutActivityUiState.value = activityUiState.value.copy(dialogUiState = deleteDialog)
        }

        dismissCurDialog()

        if (confirmed) {
            withDataOpActiveUiState {
                try {
                    val updatedRecord = contactsRepo.locallyDelete(id = idToDelete)
                    if (detailsVm.uiState.value.recordId == idToDelete) {
                        detailsVm.clobberRecord(record = updatedRecord, editing = false)
                    }
                } catch (ex: RepoOperationException) {
                    logger.e(TAG, ex.toString())

                    when (ex) {
                        is RepoOperationException.InvalidResultObject,
                        is RepoOperationException.RecordNotFound,
                        is RepoOperationException.SmartStoreOperationFailed -> DeleteOperationFailed
                    }.also {
                        mutMessages.tryEmit(it)
                    }
                }
            }
        }
    }

    private suspend fun runUndeleteOpWithConfirmation(idToUndelete: String) {
        if (activityUiState.value.dataOpIsActive) {
            mutMessages.tryEmit(WaitForDataOpToFinish)
            return
        }

        /* This wraps the undelete dialog in a coroutine so that the method only continues once the
         * user has made a selection. THIS KEEPS THE EVENT MUTEX LOCKED UNTIL THE USER MAKES A CHOICE.
         * It is okay to do this because the dialog will take over the screen, not allowing any other
         * user interaction until they make a decision.
         *
         * It also prevents the VM from reacting to any record emissions from the data layer until
         * the user makes a choice, and this too is a good thing. Changing the data displayed in the
         * UI while there is an alert dialog present may lead to the user's choice having unintended
         * side-effects. */
        val confirmed = suspendCoroutine<Boolean> { cont ->
            val undeleteDialog = UndeleteConfirmationDialogUiState(
                objIdToUndelete = idToUndelete,
                objName = curRecordsByIds[idToUndelete]?.sObject?.fullName,
                onCancelUndelete = { cont.resume(value = false) },
                onConfirmUndelete = { cont.resume(value = true) }
            )

            mutActivityUiState.value = activityUiState.value.copy(dialogUiState = undeleteDialog)
        }

        dismissCurDialog()

        if (confirmed) {
            withDataOpActiveUiState {
                try {
                    detailsVm.clobberRecord(
                        record = contactsRepo.locallyUndelete(id = idToUndelete),
                        editing = false
                    )
                } catch (ex: RepoOperationException) {
                    logger.e(TAG, ex.toString())

                    when (ex) {
                        is RepoOperationException.InvalidResultObject,
                        is RepoOperationException.RecordNotFound,
                        is RepoOperationException.SmartStoreOperationFailed -> UndeleteOperationFailed
                    }.also {
                        mutMessages.tryEmit(it)
                    }
                }
            }
        }
    }

    /**
     * Convenience method for the common case of performing an action while the UI is updated to
     * indicate that a data operation is active (e.g. showing a loading overlay).
     */
    private suspend fun withDataOpActiveUiState(block: suspend () -> Unit) {
        try {
            mutActivityUiState.value = activityUiState.value.copy(dataOpIsActive = true)
            block()
        } finally {
            withContext(NonCancellable) {
                mutActivityUiState.value = activityUiState.value.copy(dataOpIsActive = false)
            }
        }
    }


    // region Utilities


    /**
     * Convenience method to wrap a method body in a coroutine which acquires the event mutex lock
     * before executing the [block].
     */
    private fun safeHandleUiEvent(block: suspend CoroutineScope.() -> Unit) {
        viewModelScope.launch {
            eventMutex.withLockDebug {
                if (!hasInitialAccount) return@withLockDebug
                block()
            }
        }
    }

    /**
     * Convenience method for dismissing the currently-shown alert dialog.
     */
    private fun dismissCurDialog() {
        mutActivityUiState.value = mutActivityUiState.value.copy(dialogUiState = null)
    }

    private companion object {
        private const val TAG = "DefaultContactsActivityViewModel"
    }


    // endregion


    /**
     * An implementation of the Contact Details Component contract, implementing the details field
     * change handlers and the UI click handlers. Implemented as an inner class to allow access to
     * common [DefaultContactsActivityViewModel] properties such as the shared event lock while
     * keeping implementation details hidden from other components.
     */
    private inner class DefaultContactDetailsViewModel : ContactDetailsComponentClickHandler {

        private val initialState: ContactDetailsUiState
            get() = ContactDetailsUiState.NoContactSelected(doingInitialLoad = true)

        private val mutDetailsUiState = MutableStateFlow(initialState)

        val uiState: StateFlow<ContactDetailsUiState> get() = mutDetailsUiState

        val willHandleBack: Boolean
            get() = uiState.value is ContactDetailsUiState.ViewingContactDetails

        fun reset() {
            mutDetailsUiState.value = initialState
        }

        fun onRecordsEmitted() {
            if (uiState.value.doingInitialLoad) {
                mutDetailsUiState.value = uiState.value.copy(doingInitialLoad = false)
            }

            val viewingState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return

            if (viewingState.recordId == null && viewingState.isEditingEnabled) {
                // creating new contact
                return
            }

            if (!viewingState.isEditingEnabled) {
                clobberRecord(record = curRecordsByIds[viewingState.recordId], editing = false)
            }

            // if editing, let the user keep their changes
        }

        suspend fun onBackPressed() {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return

            // This component's back-stack is implemented as NoContactSelected -> ViewingContactDetails (editing = false) -> ViewingContactDetails (editing = true)
            if (curState.isEditingEnabled) {
                setContactWithConfirmation(contactId = uiState.value.recordId, editing = false)
            } else {
                setContactWithConfirmation(contactId = null, editing = false)
            }
        }

        /**
         * Unconditionally sets the displayed contact details in the Contact Details component to
         * the provided [record] in the provided [editing] mode. There are four modes the component can
         * change to, depending on the combination of arguments provided.
         *
         * ```
         * +===========+============+==================================+
         * | Record    | Editing    | Resulting Mode                   |
         * +===========+============+==================================+
         * | null      | false      | No Contact Selected              |
         * +-----------+------------+----------------------------------+
         * | null      | true       | Creating New Contact             |
         * +-----------+------------+----------------------------------+
         * | non-null  | false      | Viewing Provided Record          |
         * +-----------+------------+----------------------------------+
         * | non-null  | true       | Editing Provided Record          |
         * +-----------+------------+----------------------------------+
         * ```
         */
        fun clobberRecord(record: ContactRecord?, editing: Boolean) {
            if (record == null) {
                if (editing) {
                    // Creating new contact
                    mutDetailsUiState.value = ContactDetailsUiState.ViewingContactDetails(
                        recordId = null,
                        firstNameField = buildFirstNameField(fieldValue = null),
                        lastNameField = buildLastNameField(fieldValue = null),
                        titleField = buildTitleField(fieldValue = null),
                        departmentField = buildDepartmentField(fieldValue = null),

                        uiSyncState = SObjectUiSyncState.NotSaved,

                        isEditingEnabled = true,
                        shouldScrollToErrorField = false,
                    )
                } else {
                    mutDetailsUiState.value = ContactDetailsUiState.NoContactSelected()
                }
            } else {
                mutDetailsUiState.value = record.buildViewingContactUiState(
                    uiSyncState = record.syncState.toUiSyncState(),
                    isEditingEnabled = editing,
                    shouldScrollToErrorField = false,
                )
            }
        }

        val hasUnsavedChanges: Boolean
            get() {
                return when (val curState = uiState.value) {
                    is ContactDetailsUiState.ViewingContactDetails -> curState.recordId?.let {
                        try {
                            curState.toSObjectOrThrow() != curRecordsByIds[it]?.sObject
                        } catch (ex: ContactValidationException) {
                            // invalid field values means there are unsaved changes
                            true
                        }
                    } ?: true // creating new contact, so assume changes are present

                    is ContactDetailsUiState.NoContactSelected -> false
                }
            }

        override fun createClick() = safeHandleUiEvent {
            setContactWithConfirmation(contactId = null, editing = true)
        }

        override fun deleteClick() = safeHandleUiEvent {
            val targetRecordId = uiState.value.recordId ?: return@safeHandleUiEvent
            runDeleteOpWithConfirmation(idToDelete = targetRecordId)
        }

        override fun undeleteClick() = safeHandleUiEvent {
            val targetRecordId = uiState.value.recordId ?: return@safeHandleUiEvent
            runUndeleteOpWithConfirmation(idToUndelete = targetRecordId)
        }

        override fun editClick() = safeHandleUiEvent {
            setContactWithConfirmation(contactId = uiState.value.recordId, editing = true)
        }

        override fun deselectContactClick() = safeHandleUiEvent {
            setContactWithConfirmation(contactId = null, editing = false)
        }

        override fun exitEditClick() = safeHandleUiEvent {
            setContactWithConfirmation(contactId = uiState.value.recordId, editing = false)
        }

        override fun saveClick() = safeHandleUiEvent {
            // If not viewing details, we cannot build the SObject, so there is nothing to do
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            val so = try {
                curState.toSObjectOrThrow()
            } catch (ex: Exception) {
                mutDetailsUiState.value = curState.copy(shouldScrollToErrorField = true)
                return@safeHandleUiEvent
            }

            curState.recordId.also {
                if (it == null) {
                    runCreateOp(so = so)
                } else {
                    runUpdateOp(idToUpdate = it, so = so)
                }
            }
        }

        private fun onFirstNameChange(newFirstName: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                firstNameField = curState.firstNameField.copy(fieldValue = newFirstName)
            )
        }

        private fun onLastNameChange(newLastName: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                lastNameField = curState.lastNameField.copy(fieldValue = newLastName)
            )
        }

        private fun onTitleChange(newTitle: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                titleField = curState.titleField.copy(fieldValue = newTitle)
            )
        }

        private fun onDepartmentChange(newDepartment: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                departmentField = curState.departmentField.copy(fieldValue = newDepartment)
            )
        }

        @Throws(ContactValidationException::class)
        private fun ContactDetailsUiState.ViewingContactDetails.toSObjectOrThrow() = ContactObject(
            firstName = firstNameField.fieldValue,
            lastName = lastNameField.fieldValue ?: "",
            title = titleField.fieldValue,
            department = departmentField.fieldValue
        )

        private fun ContactRecord.buildViewingContactUiState(
            uiSyncState: SObjectUiSyncState,
            isEditingEnabled: Boolean,
            shouldScrollToErrorField: Boolean,
        ): ContactDetailsUiState.ViewingContactDetails {
            return ContactDetailsUiState.ViewingContactDetails(
                recordId = id,
                firstNameField = buildFirstNameField(sObject.firstName),
                lastNameField = buildLastNameField(sObject.lastName),
                titleField = buildTitleField(sObject.title),
                departmentField = buildDepartmentField(sObject.department),
                uiSyncState = uiSyncState,
                isEditingEnabled = isEditingEnabled,
                shouldScrollToErrorField = shouldScrollToErrorField,
            )
        }

        private fun buildFirstNameField(fieldValue: String?): EditableTextFieldUiState {
            val isInErrorState: Boolean
            val helper: FormattedStringRes?

            val validateException = runCatching { ContactObject.validateFirstName(fieldValue) }
                .exceptionOrNull() as ContactValidationException.FieldContainsIllegalText?

            if (validateException == null) {
                isInErrorState = false
                helper = null
            } else {
                isInErrorState = true
                helper = FormattedStringRes(help_illegal_characters)
            }

            return EditableTextFieldUiState(
                fieldValue = fieldValue,
                onValueChange = ::onFirstNameChange,
                isInErrorState = isInErrorState,
                label = FormattedStringRes(label_contact_first_name),
                placeholder = FormattedStringRes(label_contact_first_name),
                helper = helper,
                sanitizer = ::sanitizeName
            )
        }

        private fun buildLastNameField(fieldValue: String?): EditableTextFieldUiState {
            val isInErrorState: Boolean
            val helper: FormattedStringRes?

            val validateException = runCatching { ContactObject.validateLastName(fieldValue) }
                .exceptionOrNull() as ContactValidationException?

            if (validateException == null) {
                isInErrorState = false
                helper = null
            } else {
                isInErrorState = true
                helper = when (validateException) {
                    ContactValidationException.LastNameCannotBeBlank ->
                        FormattedStringRes(help_cannot_be_blank)

                    is ContactValidationException.FieldContainsIllegalText ->
                        FormattedStringRes(help_illegal_characters)
                }
            }

            return EditableTextFieldUiState(
                fieldValue = fieldValue,
                onValueChange = ::onLastNameChange,
                isInErrorState = isInErrorState,
                label = FormattedStringRes(label_contact_last_name),
                placeholder = FormattedStringRes(label_contact_last_name),
                helper = helper,
                sanitizer = ::sanitizeName
            )
        }

        private fun buildTitleField(fieldValue: String?) = EditableTextFieldUiState(
            fieldValue = fieldValue,
            onValueChange = ::onTitleChange,
            isInErrorState = false,
            label = FormattedStringRes(label_contact_title),
            placeholder = FormattedStringRes(label_contact_title),
            helper = null,
            maxLines = UInt.MAX_VALUE,
        )

        private fun buildDepartmentField(fieldValue: String?) = EditableTextFieldUiState(
            fieldValue = fieldValue,
            onValueChange = ::onDepartmentChange,
            isInErrorState = false,
            label = FormattedStringRes(label_contact_department),
            placeholder = FormattedStringRes(label_contact_department),
            helper = null,
            maxLines = UInt.MAX_VALUE
        )

        private fun sanitizeName(name: String): String = name.removeNewlineChars().removeTabChars()
    }

    /**
     * An implementation of the Contacts List Component contract, implementing the list click handlers.
     * Implemented as an inner class to allow access to common * [DefaultContactsActivityViewModel]
     * properties such as the shared event lock while keeping implementation details hidden from other
     * components.
     */
    private inner class DefaultContactsListViewModel : ContactsListClickHandler {

        private val initialState: ContactsListUiState
            get() = ContactsListUiState(
                contacts = emptyList(),
                curSelectedContactId = null,
                isDoingInitialLoad = true,
                isDoingDataAction = false,
                isSearchJobRunning = false,
                searchField = EditableTextFieldUiState(
                    fieldValue = null,
                    onValueChange = ::onSearchTermUpdated,
                    isInErrorState = false,
                    label = null,
                    placeholder = FormattedStringRes(cta_search),
                    helper = null,
                    maxLines = 1u,
                    sanitizer = ::sanitizeSearch
                )
            )

        private val mutListUiState = MutableStateFlow(initialState)
        val uiState: StateFlow<ContactsListUiState> get() = mutListUiState

        val willHandleBack: Boolean = false

        fun reset() {
            curSearchJob?.cancel()
            mutListUiState.value = initialState
        }

        fun onRecordsEmitted() {
            if (uiState.value.isDoingInitialLoad) {
                mutListUiState.value = uiState.value.copy(isDoingInitialLoad = false)
            }

            restartSearch(searchTerm = uiState.value.searchField.fieldValue) { filteredResults ->
                mutListUiState.value = uiState.value.copy(contacts = filteredResults)
            }
        }

        fun setSelectedContact(id: String?) {
            mutListUiState.value = uiState.value.copy(curSelectedContactId = id)
        }

        override fun contactClick(contactId: String) = safeHandleUiEvent {
            setContactWithConfirmation(contactId = contactId, editing = false)
        }

        override fun createClick() = safeHandleUiEvent {
            setContactWithConfirmation(contactId = null, editing = true)
        }

        override fun deleteClick(contactId: String) = safeHandleUiEvent {
            runDeleteOpWithConfirmation(idToDelete = contactId)
        }

        override fun editClick(contactId: String) = safeHandleUiEvent {
            setContactWithConfirmation(contactId = contactId, editing = true)
        }

        override fun undeleteClick(contactId: String) = safeHandleUiEvent {
            runUndeleteOpWithConfirmation(idToUndelete = contactId)
        }

        fun onSearchTermUpdated(newSearchTerm: String) = safeHandleUiEvent {
            mutListUiState.value = uiState.value.copy(
                searchField = uiState.value.searchField.copy(fieldValue = newSearchTerm)
            )

            restartSearch(searchTerm = newSearchTerm) { filteredList ->
                eventMutex.withLockDebug {
                    mutListUiState.value = uiState.value.copy(contacts = filteredList)
                }
            }
        }

        @Volatile
        private var curSearchJob: Job? = null

        /**
         * Starts or restarts the [Job] for searching through the current list of contacts for the
         * user's entered search term. This [Job] runs on [Dispatchers.Default].
         *
         * @param searchTerm The string to locate in the names of contacts.
         * @param block The code to be run with the filtered results of the completed search.
         */
        private fun restartSearch(
            searchTerm: String?,
            block: suspend (filteredList: List<ContactRecord>) -> Unit
        ) {
            val contacts = curRecordsByIds.values.toList()

            curSearchJob?.cancel()
            curSearchJob = viewModelScope.launch(Dispatchers.Default) {
                try {
                    mutListUiState.value = uiState.value.copy(isSearchJobRunning = true)

                    val filteredResults =
                        if (searchTerm.isNullOrEmpty()) {
                            contacts
                        } else {
                            contacts.filter {
                                ensureActive()
                                it.sObject.fullName.contains(searchTerm, ignoreCase = true)
                            }
                        }

                    ensureActive()

                    block(filteredResults)
                } finally {
                    withContext(NonCancellable) {
                        mutListUiState.value = uiState.value.copy(isSearchJobRunning = false)
                    }
                }
            }
        }

        private fun sanitizeSearch(searchTerm: String): String =
            searchTerm.removeTabChars().removeNewlineChars()
    }
}
