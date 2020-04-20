//
//  SyncManager.swift
//  MobileSyncExplorerSwift
//
//  Created by keith siilats on 4/19/20.
//  Copyright © 2020 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
import SmartStore
import MobileSync
import Combine

extension SyncManager {
    
    /// Runs or reruns a sync. Does not send progress updates like reSync(named, updateBlock).
    /// - Parameter objectType: StoreProtocol.Type
    /// - Parameter completionBlock: block invoked when sync completes or fails with Result<SyncState, MobileSyncError>)
    public func upSyncWithoutUpdates(objectType: StoreProtocol.Type, _ completionBlock: @escaping (Result<SyncState, MobileSyncError>) -> Void) {
        let updateBlock = { (state: SyncState) in
            switch state.status {
            case .done: completionBlock(.success(state))
            case .stopped: completionBlock(.failure(.stopped))
            case .failed: completionBlock(.failure(.failed(state)))
            default: break
            }
        }
        let options: SyncOptions = SyncOptions.newSyncOptions(forSyncUp: objectType.readFields, mergeMode: .leaveIfChanged)
        let target = SyncUpTarget.init(createFieldlist: objectType.createFields, updateFieldlist: objectType.updateFields)
        self.syncUp(target: target, options: options, soupName: objectType.objectName, onUpdate: updateBlock)
    }
    
    /// Runs or reruns a sync. Does not send progress updates like reSync(named, updateBlock).
    /// - Parameter objectType: StoreProtocol.Type
    /// - Parameter completionBlock: block invoked when sync completes or fails with Result<SyncState, MobileSyncError>)
    public func downSyncWithoutUpdates(objectType: StoreProtocol.Type, sqlQueryString: String, _ completionBlock: @escaping (Result<SyncState, MobileSyncError>) -> Void) {
        let updateBlock = { (state: SyncState) in
            switch state.status {
            case .done: completionBlock(.success(state))
            case .stopped: completionBlock(.failure(.stopped))
            case .failed: completionBlock(.failure(.failed(state)))
            default: break
            }
        }
        let target: SoqlSyncDownTarget = SoqlSyncDownTarget.newSyncTarget(sqlQueryString)
        let options: SyncOptions = SyncOptions.newSyncOptions(forSyncDown: .overwrite)
        self.syncDown(target: target, options: options, soupName: objectType.objectName, onUpdate: updateBlock)
    }
    
}

@available(iOS 13.0, watchOS 6.0, *)
extension SyncManager {
    /// Runs or reruns a sync.
    /// - Parameter objectType: StoreProtocol.Type
    /// - Returns: a Future<SyncState, MobileSyncError> publisher.
    public func publishUp(objectType: StoreProtocol.Type) -> Future<SyncState, MobileSyncError> {
        Future<SyncState, MobileSyncError> { promise in
            self.upSyncWithoutUpdates(objectType: objectType) { (result) in
                switch result {
                case .success(let state):
                    promise(.success(state))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    
    public func publishDown(objectType: StoreProtocol.Type, sqlQueryString: String) -> Future<SyncState, MobileSyncError> {
        Future<SyncState, MobileSyncError> { promise in
            self.downSyncWithoutUpdates(objectType: objectType, sqlQueryString: sqlQueryString) { (result) in
                switch result {
                case .success(let state):
                    promise(.success(state))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
}
