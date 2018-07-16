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
import PromiseKit

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
                SalesforceSwiftLogger.log(type(of:self), level:.error, message: "\(objectType.objectName) failed to register soup: \(error.localizedDescription)")
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
    
    public func locallyCreateEntry(entry: objectType) -> objectType {
        var record: objectType = entry
        record.local = true
        record.locallyCreated = true
        record.objectType = objectType.objectName
        return objectType.from(upsertEntries([record.data]))
    }
    
    public func locallyUpdateEntry(entry: objectType) -> objectType {
        var record: objectType = entry
        record.local = true
        record.locallyUpdated = true
        return objectType.from(upsertEntries([record.data]))
    }

    public func locallyDeleteEntry(entry: objectType) {
        var record: objectType = entry
        record.local = true
        record.locallyDeleted = true
        _ =  upsertEntries([record.data])
    }

    public func createEntry(entry: objectType) -> Promise<objectType> {
        _ = locallyCreateEntry(entry: entry)
        return syncUpDown()
            .then { _ -> Promise<objectType> in
                if let record = self.record(forExternalId: entry.externalId) {
                    return Promise.value(record)
                } else {
                    return Promise(error:StoreErrors.recordNotFound)
                }
        }
    }
    
    public func updateEntry(entry: objectType) -> Promise<objectType> {
        _ = locallyUpdateEntry(entry: entry)
        return syncUpDown()
            .then { _ -> Promise<objectType> in
                if let record = self.record(forExternalId: entry.externalId) {
                    return Promise.value(record)
                } else {
                    return Promise(error:StoreErrors.recordNotFound)
                }
        }
    }
    
    public func deleteEntry(entry: objectType) -> Promise<Void> {
        locallyDeleteEntry(entry: entry)
        return syncUpDown()
    }

    public func syncEntry(entry: objectType) -> Promise<Void> {
        var record: objectType = entry
        record.objectType = objectType.objectName
        _ = upsertEntries([record.data])
        return syncUpDown()
    }

    private func reSync(syncName: String) -> Promise<Void> {
        let startDate = Date()
        return smartSync.Promises.reSync(syncName: syncName)
            .then { syncState -> Promise<Void> in
                self.printTiming(startDate, operation:"SYNCHING  \(syncName)")
                if syncState.hasFailed() {
                    SalesforceSwiftLogger.log(type(of:self), level:.error, message:"sync \(syncName) failed")
                    return Promise(error:StoreErrors.syncFailed)
                }
                SalesforceSwiftLogger.log(type(of:self), level:.error, message:"sync \(syncName) completed")
                return Promise.value(())
        }
    }
    
    public func syncDown() -> Promise<Void> {
        return reSync(syncName: syncDownName)
    }
    
    public func syncUp() -> Promise<Void> {
        return reSync(syncName: syncUpName)
    }
    
    public func syncUpDown() -> Promise<Void> {
        return self.syncUp().then { self.syncDown() }
    }
    
    internal func printTiming(_ startDate:Date, operation:String) {
        let diff = String(format:"%10.3f", Date().timeIntervalSince(startDate) * 1000)
        SalesforceSwiftLogger.log(type(of:self), level:.debug, message:"Took \(diff) ms \(operation)")
    }
    
    internal func upsertEntries(_ entries:[Any]) -> [Any] {
        let startDate = Date()
        let results = store.upsertEntries(entries, toSoup: objectType.objectName)
        printTiming(startDate, operation:"UPSERTING \(objectType.objectName)")
        return results
    }


    internal func runQuery(query:SFQuerySpec, pageIndex:UInt = 0) -> [Any]? {
        var error: NSError? = nil
        let startDate = Date()
        let results: [Any] = store.query(with: query, pageIndex: pageIndex, error: &error)
        printTiming(startDate, operation:"QUERYING  \(objectType.objectName)")
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"query \(query.smartSql) failed: \(error!.localizedDescription)")
            return nil
        }
        return results
    }
 
    public func record(index: Int) -> objectType {
        let query:SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: 1)!
        if let results = runQuery(query: query, pageIndex: UInt(index)) {
            return objectType.from(results)
        } else {
            return objectType()
        }
    }
    
    public func record(forExternalId externalId: String?) -> objectType? {
        guard let id = externalId else {return nil}
        let query = SFQuerySpec.newExactQuerySpec(objectType.objectName, withPath: Record.Field.externalId.rawValue, withMatchKey: id, withOrderPath: objectType.orderPath, with: .descending, withPageSize: 1)
        if let results = runQuery(query: query) {
            return objectType.from(results)
        } else {
            return objectType()
        }
    }
    
    public func records() -> [objectType] {
        let query:SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: pageSize)!
        if let results = runQuery(query: query) {
            return objectType.from(results)
        } else {
            return []
        }
    }
    
    enum StoreErrors : Error {
        case syncFailed
        case noExternalId
        case recordNotFound
    }
}
