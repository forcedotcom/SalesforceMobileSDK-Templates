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

struct AlertContent: Identifiable {
     var id = UUID()
    
    var title: String?
    var message: String?
    var stopButton = false
    var okayButton = false
}

let openDetailActivityType = "com.salesforce.explorer.openDetail"
let openDetailPath = "openDetail"
let openDetailRecordIdKey = "recordId"

class ContactListViewModel: ObservableObject {
    @Published var alertContent: AlertContent?
    @ObservedObject var sObjectDataManager: SObjectDataManager
    var anyCancellable: AnyCancellable?

    init(sObjectDataManager: SObjectDataManager) {
        self.sObjectDataManager = sObjectDataManager
        anyCancellable = sObjectDataManager.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        self.syncUpDown()
    }
    
    deinit {
        anyCancellable?.cancel()
    }

    func syncUpDown() {
        if let syncUp = sObjectDataManager.getSync(sObjectDataManager.kSyncUpName), let syncDown = sObjectDataManager.getSync(sObjectDataManager.kSyncDownName), syncUp.isRunning() || syncDown.isRunning() {
            return
        }
        createAlert(title: "Syncing with Salesforce", message: nil, stopButton: false)
        sObjectDataManager.syncUpDown(completion: { [weak self] success in
            if success {
                self?.updateAlert(info: "Sync Complete!", okayButton: false)
            } else {
                self?.updateAlert(info: "Sync Failed!", okayButton: false)
            }
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

    // MARK: User Actions
    func alertOkTapped() {
        withAnimation {
            alertContent = nil
        }
    }

    func alertStopTapped() {
        stopSyncManager()
        updateAlert(info: "\nRequesting sync manager stop")
    }

    func showInfo() {
        let syncManagerState = sObjectDataManager.isSyncManagerStopping() ? "stopping" : (sObjectDataManager.isSyncManagerStopped() ? "stopped" : "accepting_syncs")
        let info = ""
           + "syncManager:\(syncManagerState)\n"
            + "numberOfContacts=\(sObjectDataManager.countContacts())\n"
            + "syncDownContacts=\(infoForSyncState(sObjectDataManager.getSync("syncDownContacts")))\n"
            + "syncUpContacts=\(infoForSyncState(sObjectDataManager.getSync("syncUpContacts")))"
       
        createAlert(title: "Sync Info", message: info, stopButton: false, okayButton: true)
    }

    func cleanGhosts() {
        createAlert(title: "Cleaning Sync Ghosts", message: nil, stopButton: true)
        sObjectDataManager.cleanGhosts(onError: { [weak self] mobileSyncError in
            self?.updateAlert(info: "Failed with error \(mobileSyncError)")
        }, onValue: { [weak self] numRecords in
            self?.updateAlert(info: "Clean ghosts: \(numRecords) records")
        })
    }

    func clearLocalData() {
        sObjectDataManager.clearLocalData()
    }

    func refreshLocalData() {
        sObjectDataManager.loadLocalData()
    }

    func syncDown() {
        sync(syncName: sObjectDataManager.kSyncDownName)
    }

    func syncUp() {
        sync(syncName: sObjectDataManager.kSyncUpName)
    }

    func resumeSyncManager() {
        createAlert(title: "Resuming Sync Manager", message: nil, stopButton: true)
        do {
            try sObjectDataManager.resumeSyncManager { [weak self] syncState in
                let isLast = syncState.status != .running
                self?.updateAlert(info: self?.infoForSyncState(syncState), okayButton: isLast)
            }
        } catch {
            self.updateAlert(info: "Failed with error \(error)")
        }
    }

    func stopSyncManager() {
        sObjectDataManager.stopSyncManager()
    }

    func stopAction() {
        sObjectDataManager.stopSyncManager()
        updateAlert(info: "\nRequesting sync manager stop")
    }
    
    func itemProvider(contact: ContactSObjectData) -> NSItemProvider {
        let userActivity = NSUserActivity(activityType: openDetailActivityType)
        userActivity.title = openDetailPath
        let contactId = contact.id.stringValue
        userActivity.userInfo = [openDetailRecordIdKey: contactId]
        let itemProvider = NSItemProvider(object: contactId as NSString)
        itemProvider.registerObject(userActivity, visibility: .all)
        return itemProvider
    }

    // MARK: Private
    private func sync(syncName: String) {
        createAlert(title: "Running \(syncName)", message: nil, stopButton: true)
        sObjectDataManager.sync(syncName: syncName, onError: { [weak self] mobileSyncError in
            self?.updateAlert(info: "Failed with error: \(mobileSyncError)")
        }, onValue: { [weak self] syncState in
        let info = self?.infoForSyncState(syncState)
            let isLast = syncState.status != .running
            self?.updateAlert(info: info, okayButton: isLast)
       })
    }

    private func createAlert(title: String, message: String?, stopButton: Bool, okayButton: Bool = false) {
        alertContent = AlertContent(title: title, message: message, stopButton: stopButton, okayButton: okayButton)
    }

    private func updateAlert(info: String?, okayButton: Bool = true) {
        if alertContent != nil {
            alertContent!.message = info
            alertContent!.okayButton = okayButton
        }
    }

    private func infoForSyncState(_ syncState: SyncState?) -> String {
        guard let syncState = syncState else {
            return "No sync provided"
        }
        return "\(syncState.progress)% \(SyncState.syncStatus(toString:syncState.status)) totalSize: \(syncState.totalSize) maxTs: \(syncState.maxTimeStamp)"
    }
}
