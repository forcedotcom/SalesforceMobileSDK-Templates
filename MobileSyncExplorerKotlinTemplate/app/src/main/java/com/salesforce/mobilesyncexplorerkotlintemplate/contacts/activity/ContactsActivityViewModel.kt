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
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.ContactDetailsFieldChangeHandler
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
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

interface ContactsActivityUiInteractor {
    val activityUiState: StateFlow<ContactsActivityUiState>
    val detailsUiState: StateFlow<ContactDetailsUiState>
    val listUiState: StateFlow<ContactsListUiState>

    val messages: Flow<ContactsActivityMessages>

    val detailsFieldChangeHandler: ContactDetailsFieldChangeHandler
    val detailsClickHandler: ContactDetailsClickHandler
    val listClickHandler: ContactsListClickHandler
}

interface ContactsActivityViewModel : ContactsActivityUiInteractor {
    val isHandlingBackEvents: StateFlow<Boolean>

    fun switchUser(newUser: UserAccount)
    fun fullSync()
    fun handleBackClick()
}

class DefaultContactsActivityViewModel : ViewModel(), ContactsActivityViewModel {

    private val logger = SalesforceLogger.getLogger(ContactsActivity.COMPONENT_NAME, appContext)
    private val detailsVm = DefaultContactDetailsViewModel()
    private val listVm = DefaultContactsListViewModel()

    override val detailsUiState: StateFlow<ContactDetailsUiState> get() = detailsVm.uiState
    override val listUiState: StateFlow<ContactsListUiState> get() = listVm.uiState
    override val detailsClickHandler: ContactDetailsClickHandler get() = detailsVm
    override val detailsFieldChangeHandler: ContactDetailsFieldChangeHandler get() = detailsVm
    override val listClickHandler: ContactsListClickHandler get() = listVm

    /**
     * Acquire this lock and hold it for the entire time you are handling an event. Events are
     * anything asynchronous like user input events and repo data emissions.
     *
     * Serializing event handling ensures the rest of the private implementation to safely mutate
     * internal state as needed without concurrency worries.
     */
    private val eventMutex = Mutex()
    private val mutActivityUiState = MutableStateFlow(
        ContactsActivityUiState(isSyncing = false, dataOpIsActive = false, dialogUiState = null)
    )
    override val activityUiState: StateFlow<ContactsActivityUiState> get() = mutActivityUiState

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

    @Volatile
    private var curRecordsByIds: Map<String, ContactRecord> = emptyMap()

    @Volatile
    private var hasInitialAccount = false

    @Volatile
    private lateinit var contactsRepo: ContactsRepo

    @Volatile
    private var curUser: UserAccount? = null

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

                fullSync()
            }
        }
    }

    override fun fullSync() {
        viewModelScope.launch {
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

    private val isBackBeingHandled = AtomicBoolean(false)

    override fun handleBackClick() {
        if (isBackBeingHandled.compareAndSet(false, true)) {
            safeHandleUiEvent {
                detailsVm.onBackPressed() // list does not handle back click
                isBackBeingHandled.set(false)
            }
        }
    }

    private suspend fun setContactWithConfirmation(contactId: String?, editing: Boolean) {
        if (activityUiState.value.dataOpIsActive) {
            mutMessages.tryEmit(WaitForDataOpToFinish)
            return
        }

        val record = contactId?.let { curRecordsByIds[contactId] }

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

    private fun dismissCurDialog() {
        mutActivityUiState.value = mutActivityUiState.value.copy(dialogUiState = null)
    }

    private companion object {
        private const val TAG = "DefaultContactsActivityViewModel"
    }


    // endregion


    private inner class DefaultContactDetailsViewModel
        : ContactDetailsFieldChangeHandler,
        ContactDetailsClickHandler {

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

            // TODO Corner case: If user is editing a contact and the upstream gets modified/deleted
            // TODO Actually figure out how we want to reconcile locally-created contacts after sync with its ID changing
        }

        suspend fun onBackPressed() {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return

            if (curState.isEditingEnabled) {
                setContactWithConfirmation(contactId = uiState.value.recordId, editing = false)
            } else {
                setContactWithConfirmation(contactId = null, editing = false)
            }
        }

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
                    uiSyncState = record.localStatus.toUiSyncState(),
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

        override fun onFirstNameChange(newFirstName: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                firstNameField = curState.firstNameField.copy(fieldValue = newFirstName)
            )
        }

        override fun onLastNameChange(newLastName: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                lastNameField = curState.lastNameField.copy(fieldValue = newLastName)
            )
        }

        override fun onTitleChange(newTitle: String) = safeHandleUiEvent {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@safeHandleUiEvent

            mutDetailsUiState.value = curState.copy(
                titleField = curState.titleField.copy(fieldValue = newTitle)
            )
        }

        override fun onDepartmentChange(newDepartment: String) = safeHandleUiEvent {
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
            // TODO handle when selected contact is no longer in the records list
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
