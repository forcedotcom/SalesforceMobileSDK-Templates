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
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.detailscomponent.*
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListClickHandler
import com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent.ContactsListUiState
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.requireIsLocked
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.withLockDebug
import com.salesforce.mobilesyncexplorerkotlintemplate.core.repos.RepoOperationException
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.isLocallyDeleted
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.*
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactValidationException
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactsRepo
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.sync.Mutex

interface ContactsActivityViewModel {
    val activityUiState: StateFlow<ContactsActivityUiState>
    val detailsUiState: StateFlow<ContactDetailsUiState>
    val listUiState: StateFlow<ContactsListUiState>

    val detailsFieldChangeHandler: ContactDetailsFieldChangeHandler
    val detailsClickHandler: ContactDetailsClickHandler
    val listClickHandler: ContactsListClickHandler
    val searchTermUpdatedHandler: (newSearchTerm: String) -> Unit

    fun sync(syncDownOnly: Boolean = false)
}

class DefaultContactsActivityViewModel(
    private val contactsRepo: ContactsRepo
) : ViewModel(), ContactsActivityViewModel {

    private val detailsVm by lazy { DefaultContactDetailsViewModel() }
    private val listVm by lazy { DefaultContactsListViewModel() }

    override val detailsUiState: StateFlow<ContactDetailsUiState> get() = detailsVm.uiState
    override val listUiState: StateFlow<ContactsListUiState> get() = listVm.uiState
    override val detailsClickHandler: ContactDetailsClickHandler get() = detailsVm
    override val detailsFieldChangeHandler: ContactDetailsFieldChangeHandler get() = detailsVm
    override val listClickHandler: ContactsListClickHandler get() = listVm
    override val searchTermUpdatedHandler: (newSearchTerm: String) -> Unit get() = listVm::onSearchTermUpdated

    private val stateMutex = Mutex()
    private val mutActivityUiState = MutableStateFlow(
        ContactsActivityUiState(isSyncing = false, dataOpIsActive = false, dialogUiState = null)
    )

    override val activityUiState: StateFlow<ContactsActivityUiState> get() = mutActivityUiState

    @Volatile
    private var curRecordsByIds: Map<String, ContactRecord> = emptyMap()

    init {
        viewModelScope.launch {
            contactsRepo.recordsById.collect { records ->
                stateMutex.withLockDebug {
                    curRecordsByIds = records
                    detailsVm.onRecordsEmitted(records)
                    listVm.onRecordsEmitted(records)
                }
            }
        }
    }

    override fun sync(syncDownOnly: Boolean) {
        viewModelScope.launch {
            stateMutex.withLockDebug {
                mutActivityUiState.value = activityUiState.value.copy(isSyncing = true)
            }
            if (syncDownOnly) {
                contactsRepo.syncDownOnly()
            } else {
                contactsRepo.syncUpAndDown()
            }
            stateMutex.withLockDebug {
                mutActivityUiState.value = activityUiState.value.copy(isSyncing = false)
            }
        }
    }

    /* If you look closely, you will see that this class' click handlers are running suspending setter
     * methods _within_ the state locks. This should be alarming because this can lead to unresponsive
     * UI, but in this case it is necessary.
     *
     * The user expects atomic operations when they perform a UI action that would change the state
     * of multiple coupled components. If we allow more than one action to contend for the components'
     * setters, it opens up the possibility of inconsistent state, which is deemed here to be worse
     * than "dropping clicks."
     *
     * Note that the UI _thread_ is not locked up during this. All suspending APIs are main-safe, so
     * the UI thread can continue to render and there will be no ANRs. The fact of the matter is:
     * if a component is locked up and cannot finish the set operation, the user must wait until
     * that component cooperates with the setter until they are allowed to take another action.
     *
     * In almost all cases, this will not even be an issue. */
    private val listClickDelegate = ListClickDelegate()

    private inner class ListClickDelegate : ContactsListClickHandler {
        override fun contactClick(contactId: String) {
            doSetContact(contactId = contactId, editing = false)
        }

        override fun editClick(contactId: String) {
            doSetContact(contactId = contactId, editing = true)
        }

        override fun deleteClick(contactId: String) {
            launchDeleteOpWithConfirmation(idToDelete = contactId)
        }

        override fun undeleteClick(contactId: String) {
            launchUndeleteOpWithConfirmation(idToUndelete = contactId)
        }

        override fun createClick() = launchWithStateLock {
            // TODO check for data operations
            if (!detailsVm.hasUnsavedChanges) {
                detailsVm.clobberRecord(record = null, editing = true)
                listVm.setSelectedContact(null)
            } else {
                val discardChangesDialog = DiscardChangesDialogUiState(
                    onDiscardChanges = {
                        launchWithStateLock {
                            detailsVm.clobberRecord(record = null, editing = true)
                            dismissCurDialog()
                        }
                    },
                    onKeepChanges = { launchWithStateLock { dismissCurDialog() } }
                )

                mutActivityUiState.value =
                    activityUiState.value.copy(dialogUiState = discardChangesDialog)
            }
        }

        private fun doSetContact(contactId: String, editing: Boolean) = launchWithStateLock {
            // TODO check for data operations
            val record = curRecordsByIds[contactId] ?: return@launchWithStateLock
            if (!detailsVm.hasUnsavedChanges) {
                detailsVm.clobberRecord(record = record, editing = editing)
                listVm.setSelectedContact(id = contactId)
            } else {
                val discardChangesDialog = DiscardChangesDialogUiState(
                    onDiscardChanges = {
                        launchWithStateLock inner@{
                            val futureRecord = curRecordsByIds[contactId] ?: return@inner
                            detailsVm.clobberRecord(record = futureRecord, editing = editing)
                            listVm.setSelectedContact(id = contactId)
                            dismissCurDialog()
                        }
                    },
                    onKeepChanges = { launchWithStateLock { dismissCurDialog() } }
                )

                mutActivityUiState.value =
                    activityUiState.value.copy(dialogUiState = discardChangesDialog)
            }
        }
    }

    private fun launchUpdateOp(idToUpdate: String, so: ContactObject) =
        launchWithinDataOperationActiveState {
            try {
                val updatedRecord = contactsRepo.locallyUpdate(id = idToUpdate, so = so)
                stateMutex.withLockDebug {
                    if (detailsVm.curRecordId == idToUpdate) {
                        detailsVm.clobberRecord(record = updatedRecord, editing = false)
                    }
                }
            } catch (ex: RepoOperationException) {
                throw ex
            }
        }

    private fun launchCreateOp(so: ContactObject) =
        launchWithinDataOperationActiveState {
            try {
                val newRecord = contactsRepo.locallyCreate(so = so)
                stateMutex.withLockDebug {
                    if (detailsVm.curRecordId == null && detailsVm.uiState.value !is ContactDetailsUiState.NoContactSelected) {
                        detailsVm.clobberRecord(record = newRecord, editing = false)
                    }
                }
            } catch (ex: RepoOperationException) {
                throw ex
            }
        }

    private fun launchDeleteOpWithConfirmation(idToDelete: String) = launchWithStateLock {
        suspend fun doDelete() {
            try {
                val updatedRecord = contactsRepo.locallyDelete(id = idToDelete)
                stateMutex.withLockDebug {
                    if (detailsVm.curRecordId == idToDelete) {
                        detailsVm.clobberRecord(record = updatedRecord, editing = false)
                    }
                }
            } catch (ex: RepoOperationException) {
                throw ex
            }
        }

        val deleteDialog = DeleteConfirmationDialogUiState(
            objIdToDelete = idToDelete,
            objName = when (val detailsState = detailsVm.uiState.value) {
                is ContactDetailsUiState.NoContactSelected -> null
                is ContactDetailsUiState.ViewingContactDetails -> detailsState.fullName
            },
            onCancelDelete = { launchWithStateLock { dismissCurDialog() } },
            onDeleteConfirm = {
                launchWithStateLock { dismissCurDialog() }
                launchWithinDataOperationActiveState { doDelete() }
            }
        )

        mutActivityUiState.value = activityUiState.value.copy(dialogUiState = deleteDialog)
    }

    private fun launchUndeleteOpWithConfirmation(idToUndelete: String) = viewModelScope.launch {
        suspend fun doUndelete() {
            try {
                val updatedRecord = contactsRepo.locallyUndelete(id = idToUndelete)
                stateMutex.withLockDebug {
                    if (detailsVm.curRecordId == idToUndelete) {
                        detailsVm.clobberRecord(record = updatedRecord, editing = false)
                    }
                }
            } catch (ex: RepoOperationException) {
                throw ex
            }
        }

        val undeleteDialog = UndeleteConfirmationDialogUiState(
            objIdToUndelete = idToUndelete,
            objName = when (val detailsState = detailsVm.uiState.value) {
                is ContactDetailsUiState.NoContactSelected -> null
                is ContactDetailsUiState.ViewingContactDetails -> detailsState.fullName
            },
            onCancelUndelete = { launchWithStateLock { dismissCurDialog() } },
            onUndeleteConfirm = {
                launchWithStateLock { dismissCurDialog() }
                launchWithinDataOperationActiveState { doUndelete() }
            }
        )

        mutActivityUiState.value = activityUiState.value.copy(dialogUiState = undeleteDialog)
    }

    private fun launchWithinDataOperationActiveState(block: suspend () -> Unit) =
        viewModelScope.launch {
            stateMutex.withLockDebug {
                if (activityUiState.value.dataOpIsActive) {
                    // TODO toast to user that the data operation couldn't be done b/c there is another already active
                    return@launch
                } else {
                    mutActivityUiState.value = activityUiState.value.copy(dataOpIsActive = true)
                }
            }

            try {
                block()
            } finally {
                withContext(NonCancellable) {
                    stateMutex.withLockDebug {
                        mutActivityUiState.value =
                            activityUiState.value.copy(dataOpIsActive = false)
                    }
                }
            }
        }


    // region Utilities


    /**
     * Convenience method to wrap a method body in a coroutine which acquires the event mutex lock
     * before executing the [block]. Because this launches a new coroutine, it is okay to nest
     * invocations of this method within other [launchWithStateLock] blocks without worrying about
     * deadlocks.
     *
     * Note! If you nest [launchWithStateLock] calls, the outer [launchWithStateLock] [block]
     * will run to completion _before_ the nested [block] is invoked since the outer [block] already
     * has the event lock.
     */
    private fun launchWithStateLock(block: suspend CoroutineScope.() -> Unit) {
        viewModelScope.launch { stateMutex.withLockDebug { block() } }
    }

    private fun dismissCurDialog() {
        stateMutex.requireIsLocked()
        mutActivityUiState.value = mutActivityUiState.value.copy(dialogUiState = null)
    }

    private companion object {
        private const val TAG = "DefaultContactsActivityViewModel"
    }


    // endregion


    private inner class DefaultContactDetailsViewModel
        : ContactDetailsFieldChangeHandler,
        ContactDetailsClickHandler {

        private val mutDetailsUiState: MutableStateFlow<ContactDetailsUiState> = MutableStateFlow(
            ContactDetailsUiState.NoContactSelected(doingInitialLoad = true)
        )

        val uiState: StateFlow<ContactDetailsUiState> get() = mutDetailsUiState

        @Volatile
        var curRecordId: String? = null
            get() {
                stateMutex.requireIsLocked()
                return field
            }
            private set(value) {
                stateMutex.requireIsLocked()
                field = value
            }

        suspend fun onRecordsEmitted(records: Map<String, ContactRecord>) {
            stateMutex.requireIsLocked()

            if (uiState.value.doingInitialLoad) {
                mutDetailsUiState.value = uiState.value.copy(doingInitialLoad = false)
            }

            val curId = curRecordId ?: return
            val matchingRecord = curRecordsByIds[curId]

            // TODO This whole onNewRecords is buggy. I think a refactor is necessary, maybe having an internal state which includes the corresponding UI state so that the [curRecordId] doesn't get out of sync with the ui state?
            if (matchingRecord == null) {
                mutDetailsUiState.value = ContactDetailsUiState.NoContactSelected()
                return
            }

            mutDetailsUiState.value = when (val curState = uiState.value) {
                is ContactDetailsUiState.NoContactSelected -> {
                    matchingRecord.sObject.buildViewingContactUiState(
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

        fun clobberRecord(record: ContactRecord?, editing: Boolean) {
            stateMutex.requireIsLocked()

            curRecordId = record?.id

            if (record == null) {
                if (editing) {
                    setStateForCreateNew()
                } else {
                    mutDetailsUiState.value = ContactDetailsUiState.NoContactSelected()
                }
            } else {
                mutDetailsUiState.value = when (val curState = uiState.value) {
                    is ContactDetailsUiState.NoContactSelected -> record.sObject.buildViewingContactUiState(
                        uiSyncState = record.localStatus.toUiSyncState(),
                        isEditingEnabled = editing,
                        shouldScrollToErrorField = false,
                    )
                    is ContactDetailsUiState.ViewingContactDetails -> curState.copy(
                        firstNameField = record.sObject.buildFirstNameField(),
                        lastNameField = record.sObject.buildLastNameField(),
                        titleField = record.sObject.buildTitleField(),
                        departmentField = record.sObject.buildDepartmentField(),
                        uiSyncState = record.localStatus.toUiSyncState(),
                        isEditingEnabled = editing,
                        shouldScrollToErrorField = false,
                    )
                }
            }
        }

        val hasUnsavedChanges: Boolean
            get() {
                stateMutex.requireIsLocked()
                return when (val curState = uiState.value) {
                    is ContactDetailsUiState.ViewingContactDetails -> curRecordId?.let {
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

        override fun createClick() = launchWithStateLock {
            if (!hasUnsavedChanges) {
                setStateForCreateNew()
                return@launchWithStateLock
            }

            val discardChangesDialog = DiscardChangesDialogUiState(
                onDiscardChanges = {
                    launchWithStateLock {
                        setStateForCreateNew()
                        dismissCurDialog()
                    }
                },
                onKeepChanges = { launchWithStateLock { dismissCurDialog() } }
            )

            mutActivityUiState.value = activityUiState.value.copy(
                dialogUiState = discardChangesDialog
            )
        }

        private fun setStateForCreateNew() {
            stateMutex.requireIsLocked()

            curRecordId = null

            mutDetailsUiState.value = ContactDetailsUiState.ViewingContactDetails(
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
        }

        override fun deleteClick() = launchWithStateLock {
            val targetRecordId = curRecordId ?: return@launchWithStateLock // no id => nothing to do
            launchDeleteOpWithConfirmation(idToDelete = targetRecordId)
        }

        override fun undeleteClick() = launchWithStateLock {
            val targetRecordId = curRecordId ?: return@launchWithStateLock // no id => nothing to do
            launchUndeleteOpWithConfirmation(idToUndelete = targetRecordId)
        }

        override fun editClick() = launchWithStateLock {
            mutDetailsUiState.value = when (val curState = uiState.value) {
                is ContactDetailsUiState.NoContactSelected -> curState
                is ContactDetailsUiState.ViewingContactDetails -> curState.copy(isEditingEnabled = true)
            }
        }

        override fun deselectContactClick() = launchWithStateLock {
            if (detailsUiState.value is ContactDetailsUiState.NoContactSelected)
                return@launchWithStateLock

            if (!hasUnsavedChanges) {
                mutDetailsUiState.value = ContactDetailsUiState.NoContactSelected()
                return@launchWithStateLock
            }

            mutActivityUiState.value = activityUiState.value.copy(
                dialogUiState = DiscardChangesDialogUiState(
                    onDiscardChanges = {
                        launchWithStateLock {
                            mutDetailsUiState.value = ContactDetailsUiState.NoContactSelected()
                            dismissCurDialog()
                        }
                    },
                    onKeepChanges = { launchWithStateLock { dismissCurDialog() } }
                )
            )
        }

        override fun exitEditClick() = launchWithStateLock {
            val viewingContactDetails =
                uiState.value as? ContactDetailsUiState.ViewingContactDetails
                    ?: return@launchWithStateLock // not editing, so nothing to do

            if (!hasUnsavedChanges) {
                mutDetailsUiState.value = viewingContactDetails.copy(isEditingEnabled = false)
                return@launchWithStateLock
            }

            val discardChangesDialog = DiscardChangesDialogUiState(
                onDiscardChanges = {
                    launchWithStateLock {
                        val record = curRecordId?.let { curRecordsByIds[it] }
                        mutDetailsUiState.value = record
                            ?.sObject
                            ?.buildViewingContactUiState(
                                uiSyncState = record.localStatus.toUiSyncState(),
                                isEditingEnabled = false,
                                shouldScrollToErrorField = false
                            )
                            ?: ContactDetailsUiState.NoContactSelected()

                        dismissCurDialog()
                    }
                },
                onKeepChanges = { launchWithStateLock { dismissCurDialog() } }
            )

            mutActivityUiState.value = activityUiState.value.copy(
                dialogUiState = discardChangesDialog
            )
        }

        override fun saveClick() = launchWithStateLock {
            // If not viewing details, we cannot build the SObject, so there is nothing to do
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@launchWithStateLock

            val so = try {
                curState.toSObjectOrThrow()
            } catch (ex: Exception) {
                mutDetailsUiState.value = curState.copy(shouldScrollToErrorField = true)
                return@launchWithStateLock
            }

            curRecordId.also {
                if (it == null) {
                    launchCreateOp(so = so)
                } else {
                    launchUpdateOp(idToUpdate = it, so = so)
                }
            }
        }

        override fun onFirstNameChange(newFirstName: String) = launchWithStateLock {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@launchWithStateLock

            mutDetailsUiState.value = curState.copy(
                firstNameField = curState.firstNameField.copy(fieldValue = newFirstName)
            )
        }

        override fun onLastNameChange(newLastName: String) = launchWithStateLock {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@launchWithStateLock

            mutDetailsUiState.value = curState.copy(
                lastNameField = curState.lastNameField.copy(fieldValue = newLastName)
            )
        }

        override fun onTitleChange(newTitle: String) = launchWithStateLock {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@launchWithStateLock

            mutDetailsUiState.value = curState.copy(
                titleField = curState.titleField.copy(fieldValue = newTitle)
            )
        }

        override fun onDepartmentChange(newDepartment: String) = launchWithStateLock {
            val curState = uiState.value as? ContactDetailsUiState.ViewingContactDetails
                ?: return@launchWithStateLock

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

        private fun ContactObject.buildViewingContactUiState(
            uiSyncState: SObjectUiSyncState,
            isEditingEnabled: Boolean,
            shouldScrollToErrorField: Boolean,
        ): ContactDetailsUiState.ViewingContactDetails {
            stateMutex.requireIsLocked()

            return ContactDetailsUiState.ViewingContactDetails(
                firstNameField = buildFirstNameField(),
                lastNameField = buildLastNameField(),
                titleField = buildTitleField(),
                departmentField = buildDepartmentField(),
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

        private val mutListUiState = MutableStateFlow(
            ContactsListUiState(
                contacts = emptyList(),
                curSelectedContactId = null,
                isDoingInitialLoad = true,
                isDoingDataAction = false,
                isSearchJobRunning = false
            )
        )
        val uiState: StateFlow<ContactsListUiState> get() = mutListUiState

        suspend fun onRecordsEmitted(records: Map<String, ContactRecord>) {
            launchWithStateLock {
                // always launch the search with new records and only update the ui list with the search results
                restartSearch(searchTerm = uiState.value.curSearchTerm) { filteredList ->
                    stateMutex.withLockDebug {
                        mutListUiState.value = uiState.value.copy(
                            contacts = filteredList,
                            isDoingInitialLoad = false
                        )
                    }
                }
                // TODO handle when selected contact is no longer in the records list
            }
        }

        fun setSelectedContact(id: String?) {
            stateMutex.requireIsLocked()
            mutListUiState.value = uiState.value.copy(curSelectedContactId = id)
        }

        override fun contactClick(contactId: String) {
            listClickDelegate.contactClick(contactId = contactId)
        }

        override fun createClick() {
            listClickDelegate.createClick()
        }

        override fun deleteClick(contactId: String) {
            listClickDelegate.deleteClick(contactId = contactId)
        }

        override fun editClick(contactId: String) {
            listClickDelegate.editClick(contactId = contactId)
        }

        override fun undeleteClick(contactId: String) {
            listClickDelegate.undeleteClick(contactId = contactId)
        }

        fun onSearchTermUpdated(newSearchTerm: String) = launchWithStateLock {
            mutListUiState.value = uiState.value.copy(curSearchTerm = newSearchTerm)

            restartSearch(searchTerm = newSearchTerm) { filteredList ->
                stateMutex.withLockDebug {
                    mutListUiState.value = uiState.value.copy(contacts = filteredList)
                }
            }
        }

        @Volatile
        private var curSearchJob: Job? = null

        private suspend fun restartSearch(
            searchTerm: String,
            block: suspend (filteredList: List<ContactRecord>) -> Unit
        ) {
            stateMutex.requireIsLocked()

            // TODO this is not optimized. it would be cool to successively refine the search, but for now just search the entire list every time
            val contacts = curRecordsByIds.values.toList()

            curSearchJob?.cancel()
            curSearchJob = viewModelScope.launch(Dispatchers.Default) {
                try {
                    stateMutex.withLockDebug {
                        mutListUiState.value = uiState.value.copy(isSearchJobRunning = true)
                    }

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
                        stateMutex.withLockDebug {
                            mutListUiState.value = uiState.value.copy(isSearchJobRunning = false)
                        }
                    }
                }
            }
        }
    }
}
