//
//  ContactListViewModel.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 4/3/20.
//  Copyright (c) 2020-present, salesforce.com, inc. All rights reserved.
// 
//  Redistribution and use of this software in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials provided
//  with the distribution.
//  * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission of salesforce.com, inc.
// 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import MobileSync
import SwiftUI
import Combine

let openDetailActivityType = "com.salesforce.explorer.openDetail"
let openDetailPath = "openDetail"
let openDetailRecordIdKey = "recordId"

class ContactListViewModel: AlertViewModel {
    @ObservedObject var sObjectDataManager: SObjectDataManager
    @Published var selectedRecord: ContactSObjectData.ID? {
        didSet {
            addRecentContact(selectedRecord)
        }
    }
    @Published var newContact = false
    @Published var searchTerm = ""
    var anyCancellable: AnyCancellable?
    private var recentContacts: Queue<ContactSummary>

    init(sObjectDataManager: SObjectDataManager, presentNewContact: Bool, selectedRecord: String? = nil) {
        self.sObjectDataManager = sObjectDataManager
        recentContacts = Queue(contentsOf: RecentContacts.persistedContacts(), maxSize: 3)
        super.init()

        anyCancellable = sObjectDataManager.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(persistContacts), name: UIScene.willDeactivateNotification, object: nil)
        self.syncUpDown()
    }
    
    deinit {
        anyCancellable?.cancel()
    }
    
    func newContactSelected() {
        newContact = true
    }

    func syncUpDown(completion: ((Bool) -> ())? = nil) {
        if let syncUp = sObjectDataManager.getSync(sObjectDataManager.kSyncUpName), let syncDown = sObjectDataManager.getSync(sObjectDataManager.kSyncDownName), syncUp.isRunning() || syncDown.isRunning() {
            return
        }
        createAlert(title: "Syncing with Salesforce", message: nil, stopButton: false)
        sObjectDataManager.syncUpDown(completion: { [weak self] success in
            if success {
                self?.updateAlert(info: "Sync Complete", okayButton: false)
            } else {
                self?.updateAlert(info: "Sync Failed", okayButton: false)
            }
            completion?(success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.alertContent = nil
            }
        })
    }

    func contactMatchesSearchTerm(contact: ContactSObjectData, searchTerm: String) -> Bool {
        let dataSpec: SObjectDataSpec? = ContactSObjectData.dataSpec()
        if let dataSpec = dataSpec {
            for fieldSpec in dataSpec.objectFieldSpecs where fieldSpec.isSearchable {
                let fieldValue = contact.fieldValue(forFieldName: fieldSpec.fieldName) as? String
                if let fieldValue = fieldValue {
                    if let _ = fieldValue.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive], range: fieldValue.startIndex..<fieldValue.endIndex, locale: nil) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func itemProvider(contact: ContactSObjectData) -> NSItemProvider {
        let userActivity = NSUserActivity(activityType: openDetailActivityType)
        userActivity.title = openDetailPath
        let contactId = contact.id
        userActivity.userInfo = [openDetailRecordIdKey: contactId]
        userActivity.targetContentIdentifier = openDetailPath
        let itemProvider = NSItemProvider(object: contactId as NSString)
        itemProvider.registerObject(userActivity, visibility: .all)
        return itemProvider
    }

    // MARK: Recent contacts
    
    func addRecentContact(_ contactID: ContactSObjectData.ID?) {
        if let contactID {
            if let contact = sObjectDataManager.localRecord(soupID: contactID) {
                recentContacts.append(ContactSummary(id: contact.id, firstName: contact.firstName, lastName: contact.lastName))
            }
        }
    }
    
    @objc private func persistContacts() {
        RecentContacts.persistContacts(recentContacts.array)
    }
}
