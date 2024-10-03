//
//  SettingsViewModel.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 9/30/24.
//  Copyright © 2024 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import SwiftUI
import MobileSync

class SettingsViewModel: AlertViewModel {
    @ObservedObject var sObjectDataManager: SObjectDataManager

    init(sObjectDataManager: SObjectDataManager)  {
        self.sObjectDataManager = sObjectDataManager
    }
    
    // MARK: User Actions
    override func alertStopTapped() {
        stopSyncManager()
        updateAlert(info: "\nRequesting sync manager stop")
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
    
    func showInfo() {
        let syncManagerState = sObjectDataManager.isSyncManagerStopping() ? "stopping" : (sObjectDataManager.isSyncManagerStopped() ? "stopped" : "accepting_syncs")
        let info = ""
           + "syncManager:\(syncManagerState)\n"
            + "numberOfContacts=\(sObjectDataManager.countContacts())\n"
            + "syncDownContacts=\(infoForSyncState(sObjectDataManager.getSync("syncDownContacts")))\n"
            + "syncUpContacts=\(infoForSyncState(sObjectDataManager.getSync("syncUpContacts")))"
       
        createAlert(title: "Sync Info", message: info, stopButton: false, okayButton: true)
    }
    
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

    private func infoForSyncState(_ syncState: SyncState?) -> String {
        guard let syncState = syncState else {
            return "No sync provided"
        }
        return "\(syncState.progress)% \(SyncState.syncStatus(toString:syncState.status)) totalSize: \(syncState.totalSize) maxTs: \(syncState.maxTimeStamp)"
    }
}
