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
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.*
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.withLockDebug
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.RepoOperationException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SyncDownException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.SyncUpException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.isLocallyDeleted
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.*
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.sync.Mutex
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

interface ContactsActivityUiInteractor {
    val activityUiState: StateFlow<ContactsActivityUiState>
    val detailsUiState: StateFlow<ContactDetailsUiState>
    val listUiState: StateFlow<ContactsListUiState>

    val detailsFieldChangeHandler: ContactDetailsFieldChangeHandler
    val detailsClickHandler: ContactDetailsClickHandler
    val listClickHandler: ContactsListClickHandler
    val searchTermUpdatedHandler: (newSearchTerm: String) -> Unit
}

interface ContactsActivityViewModel : ContactsActivityUiInteractor {
    fun switchUser(newUser: UserAccount)
    fun fullSync()
    suspend fun onBackPressed(): Boolean
}

class DefaultContactsActivityViewModel : ViewModel(), ContactsActivityViewModel {

    private val detailsVm by lazy { DefaultContactDetailsViewModel() }
    private val listVm by lazy { DefaultContactsListViewModel() }

    override val detailsUiState: StateFlow<ContactDetailsUiState> get() = detailsVm.uiState
    override val listUiState: StateFlow<ContactsListUiState> get() = listVm.uiState
    override val detailsClickHandler: ContactDetailsClickHandler get() = detailsVm
    override val detailsFieldChangeHandler: ContactDetailsFieldChangeHandler get() = detailsVm
    override val listClickHandler: ContactsListClickHandler get() = listVm
    override val searchTermUpdatedHandler: (newSearchTerm: String) -> Unit get() = listVm::onSearchTermUpdated

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

    @Volatile
    private var curRecordsByIds: Map<String, ContactRecord> = emptyMap()

    @Volatile
    private var hasInitialAccount = false

    @Volatile
    private lateinit var contactsRepo: ContactsRepo

    private var repoCollectorJob: Job? = null

    override fun switchUser(newUser: UserAccount) {
        viewModelScope.launch {
            eventMutex.withLockDebug {
                repoCollectorJob?.cancelAndJoin()

                contactsRepo = DefaultContactsRepo(account = newUser)

                detailsVm.reset()
                listVm.reset()

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

            try {
                contactsRepo.syncUp()
            } catch (ex: SyncUpException) {
                TODO("syncUp() - ex = $ex")
            }

            try {
                contactsRepo.syncDown()
            } catch (ex: SyncDownException) {
                TODO("syncDown() - ex = $ex")
            } catch (ex: RepoOperationException) {
                TODO("syncDown() - ex = $ex")
            }

            eventMutex.withLockDebug {
                mutActivityUiState.value = activityUiState.value.copy(isSyncing = false)
            }
        }
    }

    override suspend fun onBackPressed(): Boolean = eventMutex.withLockDebug {
        detailsVm.onBackPressed() || listVm.onBackPressed()
    }

    private suspend fun setContactWithConfirmation(contactId: String?, editing: Boolean) {
        // TODO check for data operations
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
        // TODO toast to user that the data operation couldn't be done b/c there is another already active
        if (activityUiState.value.dataOpIsActive)
            return

        withDataOpActiveUiState {
            try {
                val updatedRecord = contactsRepo.locallyUpdate(id = idToUpdate, so = so)
                if (detailsVm.uiState.value.recordId == idToUpdate) {
                    detailsVm.clobberRecord(record = updatedRecord, editing = false)
                }
            } catch (ex: RepoOperationException) {
                throw ex
            }
        }
    }

    private suspend fun runCreateOp(so: ContactObject) {
        // TODO toast to user that the data operation couldn't be done b/c there is another already active
        if (activityUiState.value.dataOpIsActive)
            return

        withDataOpActiveUiState {
            try {
                val newRecord = contactsRepo.locallyCreate(so = so)
                if (detailsVm.uiState.value.recordId == null && detailsVm.uiState.value !is ContactDetailsUiState.NoContactSelected) {
                    detailsVm.clobberRecord(record = newRecord, editing = false)
                }
            } catch (ex: RepoOperationException) {
                throw ex
            }
        }
    }

    private suspend fun runDeleteOpWithConfirmation(idToDelete: String) {
        // TODO toast to user that the data operation couldn't be done b/c there is another already active
        if (activityUiState.value.dataOpIsActive)
            return

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
                    throw ex
                }
            }
        }
    }

    private suspend fun runUndeleteOpWithConfirmation(idToUndelete: String) {
        // TODO toast to user that the data operation couldn't be done b/c there is another already active
        if (activityUiState.value.dataOpIsActive)
            return

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
                    throw ex
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

        fun reset() {
            mutDetailsUiState.value = initialState
        }

        fun onRecordsEmitted() {
            if (uiState.value.doingInitialLoad) {
                mutDetailsUiState.value = uiState.value.copy(doingInitialLoad = false)
            }

            val curId = uiState.value.recordId ?: return
            val matchingRecord = curRecordsByIds[curId]

            // TODO This whole onNewRecords is buggy. I think a refactor is necessary, maybe having an internal state which includes the corresponding UI state so that the [curRecordId] doesn't get out of sync with the ui state?
            if (matchingRecord == null) {
                mutDetailsUiState.value = ContactDetailsUiState.NoContactSelected()
                return
            }

            mutDetailsUiState.value = when (val curState = uiState.value) {
                is ContactDetailsUiState.NoContactSelected -> {
                    matchingRecord.buildViewingContactUiState(
                        uiSyncState = matchingRecord.localStatus.toUiSyncState(),
                        isEditingEnabled = false,
                        shouldScrollToErrorField = false,
                    )
                }

                is ContactDetailsUiState.ViewingContactDetails -> {
                    when {
                        // not editing, so simply update all fields to match upstream emission:
                        !curState.isEditingEnabled -> curState.copy(
                            firstNameField = matchingRecord.sObject.buildFirstNameField(),
                            lastNameField = matchingRecord.sObject.buildLastNameField(),
                            titleField = matchingRecord.sObject.buildTitleField(),
                            departmentField = matchingRecord.sObject.buildDepartmentField(),
                        )

                        /* TODO figure out how to reconcile when upstream was locally deleted but the user has
                            unsaved changes. Also applies to if upstream is permanently deleted. Reminder,
                            showing dialogs from data events is not allowed.
                            Idea: create a "snapshot" of the SO as soon as they begin editing, and only
                            prompt for choice upon clicking save. */
                        matchingRecord.localStatus.isLocallyDeleted && hasUnsavedChanges -> TODO()

                        // user is editing and there is no incompatible state, so no changes to state:
                        else -> curState
                    }
                }
            }
        }

        fun onBackPressed(): Boolean {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return false

            if (curState.isEditingEnabled) {
                exitEditClick()
            } else {
                deselectContactClick()
            }

            return true
        }

        fun clobberRecord(record: ContactRecord?, editing: Boolean) {
            if (record == null) {
                if (editing) {
                    // Creating new contact
                    mutDetailsUiState.value = ContactDetailsUiState.ViewingContactDetails(
                        recordId = null,
                        firstNameField = ContactDetailsField.FirstName(
                            fieldValue = null,
                            onValueChange = ::onFirstNameChange
                        ),
                        lastNameField = ContactDetailsField.LastName(
                            fieldValue = null,
                            onValueChange = ::onLastNameChange
                        ),
                        titleField = ContactDetailsField.Title(
                            fieldValue = null,
                            onValueChange = ::onTitleChange
                        ),
                        departmentField = ContactDetailsField.Department(
                            fieldValue = null,
                            onValueChange = ::onDepartmentChange
                        ),

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
                firstNameField = sObject.buildFirstNameField(),
                lastNameField = sObject.buildLastNameField(),
                titleField = sObject.buildTitleField(),
                departmentField = sObject.buildDepartmentField(),
                uiSyncState = uiSyncState,
                isEditingEnabled = isEditingEnabled,
                shouldScrollToErrorField = shouldScrollToErrorField,
            )
        }

        private fun ContactObject.buildFirstNameField() = ContactDetailsField.FirstName(
            fieldValue = firstName,
            onValueChange = this@DefaultContactDetailsViewModel::onFirstNameChange
        )

        private fun ContactObject.buildLastNameField() = ContactDetailsField.LastName(
            fieldValue = lastName,
            onValueChange = this@DefaultContactDetailsViewModel::onLastNameChange
        )

        private fun ContactObject.buildTitleField() = ContactDetailsField.Title(
            fieldValue = title,
            onValueChange = this@DefaultContactDetailsViewModel::onTitleChange
        )

        private fun ContactObject.buildDepartmentField() = ContactDetailsField.Department(
            fieldValue = department,
            onValueChange = this@DefaultContactDetailsViewModel::onDepartmentChange
        )
    }

    private inner class DefaultContactsListViewModel : ContactsListClickHandler {

        private val initialState: ContactsListUiState
            get() = ContactsListUiState(
                contacts = emptyList(),
                curSelectedContactId = null,
                isDoingInitialLoad = true,
                isDoingDataAction = false,
                isSearchJobRunning = false
            )

        private val mutListUiState = MutableStateFlow(initialState)
        val uiState: StateFlow<ContactsListUiState> get() = mutListUiState

        fun reset() {
            curSearchJob?.cancel()
            mutListUiState.value = initialState
        }

        fun onRecordsEmitted() {
            if (uiState.value.isDoingInitialLoad) {
                mutListUiState.value = uiState.value.copy(isDoingInitialLoad = false)
            }

            restartSearch(searchTerm = uiState.value.curSearchTerm) { filteredResults ->
                mutListUiState.value = uiState.value.copy(contacts = filteredResults)
            }
            // TODO handle when selected contact is no longer in the records list
        }

        fun onBackPressed(): Boolean = false // this component does not handle back press

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
            mutListUiState.value = uiState.value.copy(curSearchTerm = newSearchTerm)

            restartSearch(searchTerm = newSearchTerm) { filteredList ->
                eventMutex.withLockDebug {
                    mutListUiState.value = uiState.value.copy(contacts = filteredList)
                }
            }
        }

        @Volatile
        private var curSearchJob: Job? = null

        private fun restartSearch(
            searchTerm: String,
            block: suspend (filteredList: List<ContactRecord>) -> Unit
        ) {
            // TODO this is not optimized. it would be cool to successively refine the search, but for now just search the entire list every time
            val contacts = curRecordsByIds.values.toList()

            curSearchJob?.cancel()
            curSearchJob = viewModelScope.launch(Dispatchers.Default) {
                try {
                    mutListUiState.value = uiState.value.copy(isSearchJobRunning = true)

                    val filteredResults =
                        if (searchTerm.isEmpty()) {
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
    }
}
