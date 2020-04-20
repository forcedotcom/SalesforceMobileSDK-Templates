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

class ContactListViewModel: ObservableObject {
    @Published var alertContent: AlertContent?
    @ObservedObject var store: Store = Store<ContactRecord>()
    var anyCancellable: AnyCancellable?

    init() {
        anyCancellable = store.objectWillChange.sink { _ in
            self.objectWillChange.send()
        }
        self.syncUpDown()
    }

    func syncUpDown() {
        createAlert(title: "Syncing with Salesforce", message: nil, stopButton: false)
        store.syncUpDown(completion: { [weak self] success in
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

    func contactMatchesSearchTerm(contact: ContactRecord, searchTerm: String) -> Bool {
        let dataSpec: SObjectDataSpec? = ContactRecord.dataSpec()
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
        let syncManagerState = store.isSyncManagerStopping() ? "stopping" : (store.isSyncManagerStopped() ? "stopped" : "accepting_syncs")
        let info = ""
           + "syncManager:\(syncManagerState)\n"
            + "numberOfContacts=\(store.count())\n"
            + "syncDownContacts=\(infoForSyncState(store.getSync("syncDownContacts")))\n"
            + "syncUpContacts=\(infoForSyncState(store.getSync("syncUpContacts")))"
       
        createAlert(title: "Sync Info", message: info, stopButton: false)
    }

    func cleanGhosts() {
        createAlert(title: "Cleaning Sync Ghosts", message: nil, stopButton: true)
        store.cleanGhosts(onError: { [weak self] mobileSyncError in
            self?.updateAlert(info: "Failed with error \(mobileSyncError)")
        }, onValue: { [weak self] numRecords in
            self?.updateAlert(info: "Clean ghosts: \(numRecords) records")
        })
    }

    func clearLocalData() {
        store.clearLocalData()
    }

    func refreshLocalData() {
        store.loadLocalData()
    }

    func resumeSyncManager() {
        createAlert(title: "Resuming Sync Manager", message: nil, stopButton: true)
        do {
            try store.resumeSyncManager { [weak self] syncState in
                let isLast = syncState.status != .running
                self?.updateAlert(info: self?.infoForSyncState(syncState), okayButton: isLast)
            }
        } catch {
            self.updateAlert(info: "Failed with error \(error)")
        }
    }

    func stopSyncManager() {
        store.stopSyncManager()
    }

    func stopAction() {
        store.stopSyncManager()
        updateAlert(info: "\nRequesting sync manager stop")
    }

    func syncDown() {
        createAlert(title: "Running Down", message: nil, stopButton: true)
        store.syncDown( onError: { [weak self] mobileSyncError in
            self?.updateAlert(info: "Failed with error: \(mobileSyncError)")
        }, onValue: { [weak self] syncState in
        let info = self?.infoForSyncState(syncState)
            let isLast = syncState.status != .running
            self?.updateAlert(info: info, okayButton: isLast)
       })
    }
    
    func syncUp() {
        createAlert(title: "Running Up", message: nil, stopButton: true)
        store.syncUp( onError: { [weak self] mobileSyncError in
            self?.updateAlert(info: "Failed with error: \(mobileSyncError)")
        }, onValue: { [weak self] syncState in
        let info = self?.infoForSyncState(syncState)
            let isLast = syncState.status != .running
            self?.updateAlert(info: info, okayButton: isLast)
       })
    }
    // MARK: Private

    private func createAlert(title: String, message: String?, stopButton: Bool) {
        alertContent = AlertContent(title: title, message: message, stopButton: stopButton)
    }

    private func updateAlert(info: String?, okayButton: Bool = true) {
        if alertContent != nil {
            alertContent!.message = info
            alertContent!.okayButton = okayButton
        }
    }

    private func infoForSyncState(_ syncState:SyncState) -> String {
        return "\(syncState.progress)% \(SyncState.syncStatus(toString:syncState.status)) totalSize:\(syncState.totalSize) maxTs:\(syncState.maxTimeStamp)"
    }
}
