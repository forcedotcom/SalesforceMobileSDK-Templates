package com.salesforce.mobilesyncexplorerkotlintemplate.contacts.listcomponent

import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.requireIsLocked
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.withLockDebug
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.SObjectRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactObject
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactRecord
import com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts.ContactsRepo
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.sync.Mutex

interface ContactsListViewModel : ContactsListUiClickHandler, ContactsListDataActionClickHandler {
    val uiState: StateFlow<ContactsListUiState>

    fun setSelectedContact(id: String?)
    fun setSearchTerm(newSearchTerm: String)
    fun onSearchTermUpdated(newSearchTerm: String)
}

class DefaultContactsListViewModel(
    private val contactsRepo: ContactsRepo,
    private val parentScope: CoroutineScope,
    private val itemClickDelegate: ContactsListUiClickHandler?,
    private val dataActionClickDelegate: ContactsListDataActionClickHandler?,
    private val searchTermUpdatedDelegate: ((newSearchTerm: String) -> Unit)?
) : ContactsListViewModel {
    private val stateMutex = Mutex()

    private val mutUiState = MutableStateFlow(
        ContactsListUiState(
            contacts = emptyList(),
            curSelectedContactId = null,
            isDoingInitialLoad = true,
            isDoingDataAction = false,
            isSearchJobRunning = false
        )
    )
    override val uiState: StateFlow<ContactsListUiState> get() = mutUiState

    @Volatile
    private lateinit var curRecords: Map<String, ContactRecord>

    init {
        parentScope.launch(Dispatchers.Default) {
            contactsRepo.recordsById.collect {
                onContactListUpdate(it)
            }
        }
    }

    override fun setSelectedContact(id: String?) = launchWithStateMutex {
        mutUiState.value = uiState.value.copy(curSelectedContactId = id)
    }

    private fun onContactListUpdate(newRecords: Map<String, SObjectRecord<ContactObject>>) =
        launchWithStateMutex {
            curRecords = newRecords

            // always launch the search with new records and only update the ui list with the search results
            restartSearch(searchTerm = uiState.value.curSearchTerm) { filteredList ->
                stateMutex.withLockDebug {
                    mutUiState.value = uiState.value.copy(
                        contacts = filteredList,
                        isDoingInitialLoad = false
                    )
                }
            }
            // TODO handle when selected contact is no longer in the records list
        }

    override fun contactClick(contactId: String) {
        itemClickDelegate?.contactClick(contactId = contactId)
    }

    override fun createClick() {
        itemClickDelegate?.createClick()
    }

    override fun deleteClick(contactId: String) {
        if (dataActionClickDelegate != null) {
            dataActionClickDelegate.deleteClick(contactId = contactId)
            return
        }
        TODO("Not yet implemented")
    }

    override fun editClick(contactId: String) {
        itemClickDelegate?.editClick(contactId = contactId)
    }

    override fun undeleteClick(contactId: String) {
        if (dataActionClickDelegate != null) {
            dataActionClickDelegate.undeleteClick(contactId = contactId)
            return
        }
        TODO("Not yet implemented")
    }

    override fun setSearchTerm(newSearchTerm: String) = launchWithStateMutex {
        mutUiState.value = uiState.value.copy(curSearchTerm = newSearchTerm)

        restartSearch(searchTerm = newSearchTerm) { filteredList ->
            stateMutex.withLockDebug {
                mutUiState.value = uiState.value.copy(contacts = filteredList)
            }
        }
    }

    override fun onSearchTermUpdated(newSearchTerm: String) {
        if (searchTermUpdatedDelegate != null) {
            searchTermUpdatedDelegate.invoke(newSearchTerm)
            return
        }

        setSearchTerm(newSearchTerm = newSearchTerm)
    }

    @Volatile
    private var curSearchJob: Job? = null

    private suspend fun restartSearch(
        searchTerm: String,
        block: suspend (filteredList: List<ContactRecord>) -> Unit
    ) {
        stateMutex.requireIsLocked()

        // TODO this is not optimized. it would be cool to successively refine the search, but for now just search the entire list every time
        val contacts = curRecords.values.toList()

        curSearchJob?.cancel()
        curSearchJob = parentScope.launch(Dispatchers.Default) {
            try {
                stateMutex.withLockDebug {
                    mutUiState.value = uiState.value.copy(isSearchJobRunning = true)
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
                        mutUiState.value = uiState.value.copy(isSearchJobRunning = false)
                    }
                }
            }
        }
    }

    private fun launchWithStateMutex(block: suspend CoroutineScope.() -> Unit) {
        parentScope.launch {
            stateMutex.withLockDebug { this.block() }
        }
    }
}
