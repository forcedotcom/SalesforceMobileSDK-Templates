/*
 Store.swift
 Test
 
 Copyright (c) 2017-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation
import SalesforceSDKCore
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public typealias SyncCompletion = ((SFSyncState?) -> Void)?

public class Store<objectType: StoreProtocol> {

    private final let pageSize: UInt = 100
    
    public init() {
//        self.store.removeAllSoups()
//        store.clearSoup(objectType.objectName)
//        store.removeSoup(objectType.objectName)
    }

    public let sqlQueryString: String = SFRestAPI.soqlQuery(withFields: objectType.createFields, sObject: objectType.objectName, whereClause: nil, groupBy: nil, having: nil, orderBy: [objectType.orderPath], limit: 100)!
    
    public let queryString: String = "SELECT \(objectType.selectFieldsString()) FROM {\(objectType.objectName)} WHERE {\(objectType.objectName):\(Record.Field.locallyDeleted.rawValue)} != 1 ORDER BY {\(objectType.objectName):\(objectType.orderPath)} ASC"
    
    
    public lazy final var smartSync: SFSmartSyncSyncManager = SFSmartSyncSyncManager.sharedInstance(for: store)!
    
    public final var store: SFSmartStore {
        
        let store = SFSmartStore.sharedStore(withName: kDefaultSmartStoreName) as! SFSmartStore
        SFSyncState.setupSyncsSoupIfNeeded(store)
        if (!store.soupExists(objectType.objectName)) {
            let indexSpecs: [AnyObject] = SFSoupIndex.asArraySoupIndexes(objectType.indexes) as [AnyObject]
            do {
                try store.registerSoup(objectType.objectName, withIndexSpecs: indexSpecs, error: ())
            } catch let error as NSError {
                SalesforceSwiftLogger.log(type(of:self), level:.error, message: "\(objectType.objectName) failed to register soup: \(error.localizedDescription)")
            }
        }
        return store
    }
    
    public var count: UInt {
        guard let query: SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: 1) else {
            return 0
        }
        var error: NSError? = nil
        let results: UInt = store.count(with: query, error: &error)
        if let error = error {
            SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"fetch \(objectType.objectName) failed: \(error.localizedDescription)")
            return 0
        }
        return results
    }

    public func upsertEntries(jsonResponse: Any, completion: SyncCompletion = nil) {
        let dataRows = (jsonResponse as! NSDictionary)["records"] as! [NSDictionary]
        SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"request:didLoadResponse: #records: \(dataRows.count)")
        store.upsertEntries(dataRows, toSoup: objectType.objectName)
        completion?(nil)
    }
    
    public func upsertEntries<T:StoreProtocol>(record: T, completion: SyncCompletion = nil) {
        store.upsertEntries([record.data], toSoup: T.objectName)
        completion?(nil)
    }
    
    public func upsertNewEntries<T:StoreProtocol>(entry: T, completion: SyncCompletion = nil) {
        var record: T = entry
        record.local = true
        record.locallyCreated = true
        record.objectType = T.objectName
        store.upsertEntries([record.data], toSoup: T.objectName)
        completion?(nil)
    }
    
    public func deleteEntry<T:StoreProtocol>(entry: T, completion: SyncCompletion = nil) {
        var record: T = entry
        record.locallyDeleted = true
        syncEntry(entry: record, completion: completion)
    }

    public func createEntry<T:StoreProtocol>(entry: T, completion: SyncCompletion = nil) {
        var record: T = entry
        record.local = true
        record.locallyCreated = true
        syncEntry(entry: record, completion: completion)
    }
    
    public func locallyUpdateEntry<T:StoreProtocol>(entry: T) {
        var record: T = entry
        record.local = true
        record.locallyUpdated = true
        self.upsertEntries(record: record)
    }
    
    public func updateEntry<T:StoreProtocol>(entry: T, completion: SyncCompletion = nil) {
        var record: T = entry
        record.local = true
        record.locallyUpdated = true
        syncEntry(entry: record, completion: completion)
    }

    public func syncEntry<T:StoreProtocol>(entry: T, completion: SyncCompletion = nil) {
        var record: T = entry
        record.objectType = T.objectName
        store.upsertEntries([record.data], toSoup: T.objectName)
        syncUp() { syncState in
            if let _ = syncState?.isDone() {
                self.syncDown(completion: completion)
            }
        }
    }

    public func syncDown<T:StoreProtocol>(child: T, completion: SyncCompletion = nil ) {
        let parentInfo = SFParentInfo.new(withSObjectType: objectType.objectName, soupName: objectType.objectName)
        let childInfo = SFChildrenInfo.new(withSObjectType: type(of: child).objectName, soupName: type(of: child).objectName)
        let target: SFParentChildrenSyncDownTarget = SFParentChildrenSyncDownTarget.newSyncTarget(with: parentInfo, parentFieldlist: objectType.createFields, parentSoqlFilter: "", childrenInfo: childInfo, childrenFieldlist: type(of: child).createFields, relationshipType: .relationpshipMasterDetail)
        let options: SFSyncOptions = SFSyncOptions.newSyncOptions(forSyncDown: .leaveIfChanged)
        smartSync.syncDown(with: target, options: options, soupName: objectType.objectName, update: completion ?? { _ in return })
    }
    
    public func syncUp<T:StoreProtocol>(child: T,completion: SyncCompletion = nil) {
        let parentInfo = SFParentInfo.new(withSObjectType: objectType.objectName, soupName: objectType.objectName)
        let childInfo = SFChildrenInfo.new(withSObjectType: type(of: child).objectName, soupName: type(of: child).objectName)
        let options: SFSyncOptions = SFSyncOptions.newSyncOptions(forSyncUp: objectType.readFields, mergeMode: .leaveIfChanged)
        let target = SFParentChildrenSyncUpTarget.newSyncTarget(with: parentInfo, parentCreateFieldlist: [], parentUpdateFieldlist: objectType.updateFields, childrenInfo: childInfo, childrenCreateFieldlist: type(of: child).createFields, childrenUpdateFieldlist: type(of: child).updateFields, relationshipType: .relationpshipMasterDetail)
        self.smartSync.syncUp(with: target, options: options, soupName: objectType.objectName, update: completion ?? { _ in return })
    }
    
    public func syncDown(completion: SyncCompletion = nil) {
        let target: SFSoqlSyncDownTarget = SFSoqlSyncDownTarget.newSyncTarget(sqlQueryString)
        let options: SFSyncOptions = SFSyncOptions.newSyncOptions(forSyncDown: .leaveIfChanged)
        smartSync.syncDown(with: target, options: options, soupName: objectType.objectName, update: completion ?? { _ in return })
    }
    
    public func syncUp(completion: SyncCompletion = nil) {
        let updateBlock: SFSyncSyncManagerUpdateBlock = { [unowned self] (syncState: SFSyncState?) in
            if let syncState = syncState {
                if syncState.isDone() || syncState.hasFailed() {
                    DispatchQueue.main.async {
                        if syncState.hasFailed() {
                            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"syncUp \(objectType.objectName) failed")
                        }
                        else {
//                            SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"syncUp \(objectType.objectName) done")
                        }
                    }
                    completion?(syncState)
                }
            }
        }
        
        DispatchQueue.main.async(execute: {
            let options: SFSyncOptions = SFSyncOptions.newSyncOptions(forSyncUp: objectType.readFields, mergeMode: .overwrite)
            let target = SFSyncUpTarget.init(createFieldlist: objectType.createFields, updateFieldlist: objectType.updateFields)
            self.smartSync.syncUp(with: target, options: options, soupName: objectType.objectName, update: updateBlock)
        })
    }
    
    public func syncUpDownResolvingChildren<P:StoreProtocol, C:StoreProtocol>(parent:P, child: C, completion: SyncCompletion = nil) {
        let parentExternalId = parent.externalId
        self.syncUp { (upState) in
            if let upComplete = upState?.isDone(), upComplete == true {
                self.syncDown(completion: { (downState) in
                    if let downComplete = downState?.isDone(), downComplete == true {
                        if let synced = self.record(forExternalId: parentExternalId) {
                            
                        }
                    }
                })
            }
        }
    }
    
    public func syncUpDown(completion: SyncCompletion) {
        self.syncUp { (upState) in
            if let upComplete = upState?.isDone(), upComplete == true {
                self.syncDown(completion: completion)
            }
        }
    }
 
    public func record(index: Int) -> objectType {
        let query:SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: 1)!
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: UInt(index), error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(objectType.objectName) failed: \(error!.localizedDescription)")
            return objectType()
        }
        return objectType.from(results)
    }
    
    public func record(forExternalId externalId: String?) -> objectType? {
        guard let id = externalId else {return nil}
        let query = SFQuerySpec.newExactQuerySpec(objectType.objectName, withPath: Record.Field.externalId.rawValue, withMatchKey: id, withOrderPath: objectType.orderPath, with: .descending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(objectType.objectName) failed: \(error!.localizedDescription)")
            return objectType()
        }
        return objectType.from(results)
    }
    
    public func records() -> [objectType] {
        let query:SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: pageSize)!
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(objectType.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return objectType.from(results)
    }
}
