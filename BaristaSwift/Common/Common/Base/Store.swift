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

    private final let syncDownName: String = "syncDown_\(objectType.objectName)";
    
    private final let syncUpName: String = "syncUp_\(objectType.objectName)";
    
    public let sqlQueryString: String = SFRestAPI.soqlQuery(withFields: objectType.createFields, sObject: objectType.objectName, whereClause: nil, groupBy: nil, having: nil, orderBy: [objectType.orderPath], limit: 100)!
    
    public let queryString: String = "SELECT \(objectType.selectFieldsString()) FROM {\(objectType.objectName)} WHERE {\(objectType.objectName):\(Record.Field.locallyDeleted.rawValue)} != 1 ORDER BY {\(objectType.objectName):\(objectType.orderPath)} ASC"
    
    public init() {
        let soupName = objectType.objectName
        
        // Create soup if needed
        if (!store.soupExists(soupName)) {
            let indexSpecs: [AnyObject] = SFSoupIndex.asArraySoupIndexes(objectType.indexes) as [AnyObject]
            do {
                try store.registerSoup(soupName, withIndexSpecs: indexSpecs, error: ())
            } catch let error as NSError {
                SalesforceSwiftLogger.log(type(of:self), level:.error, message: "\(soupName) failed to register soup: \(error.localizedDescription)")
            }
        }
        
        // Create sync down if needed
        if (!smartSync.hasSync(withName: syncDownName)) {
            let target: SFSoqlSyncDownTarget = SFSoqlSyncDownTarget.newSyncTarget(sqlQueryString)
            let options: SFSyncOptions = SFSyncOptions.newSyncOptions(forSyncDown: .leaveIfChanged)
            smartSync.createSyncDown(target, options: options, soupName: soupName, syncName: syncDownName)
        }
        
        // Create sync up if needed
        if (!smartSync.hasSync(withName: syncUpName)) {
            let target = SFSyncUpTarget.init(createFieldlist: objectType.createFields, updateFieldlist: objectType.updateFields)
            let options: SFSyncOptions = SFSyncOptions.newSyncOptions(forSyncUp: objectType.readFields, mergeMode: .overwrite)
            smartSync.createSyncUp(target, options: options, soupName: soupName, syncName: syncUpName)
        }
    }
    
    public lazy final var smartSync: SFSmartSyncSyncManager = SFSmartSyncSyncManager.sharedInstance(for: store)!
    
    public lazy final var store: SFSmartStore = SFSmartStore.sharedStore(withName: kDefaultSmartStoreName) as! SFSmartStore
    
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

    public func syncDown(completion: SyncCompletion = nil) {
        smartSync.reSync(byName: syncDownName, update: completion ?? { _ in return })
    }
    
    public func syncUp(completion: SyncCompletion = nil) {
        let updateBlock: SFSyncSyncManagerUpdateBlock = { [unowned self] (syncState: SFSyncState?) in
            if let syncState = syncState {
                if syncState.isDone() || syncState.hasFailed() {
                    DispatchQueue.main.async {
                        if syncState.hasFailed() {
                            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"syncUp \(objectType.objectName) failed")
                        }
                    }
                    completion?(syncState)
                }
            }
        }
        
        DispatchQueue.main.async(execute: {
            self.smartSync.reSync(byName: self.syncUpName, update: updateBlock)
        })
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
