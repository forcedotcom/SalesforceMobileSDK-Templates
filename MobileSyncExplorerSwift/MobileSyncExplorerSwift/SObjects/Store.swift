//
//  Store.swift
//  MobileSyncExplorerSwift
//
//  Created by keith siilats on 4/19/20.
//  Copyright © 2020 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
import SmartStore
import MobileSync
import Combine

class Store<objectType: StoreProtocol>: ObservableObject {
    @Published var items: [objectType] = []
    private var cancellableSet: Set<AnyCancellable> = []
    private let kMaxQueryPageSize: UInt = 1000
    
    var syncMgr: SyncManager
    var dataSpec: SObjectDataSpec
    
    public let sqlQueryString: String = RestClient.soqlQuery(withFields: objectType.createFields, sObject: objectType.objectName, whereClause: nil, groupBy: nil, having: nil, orderBy: [objectType.orderPath], limit: 100)!
    
    
    var store: SmartStore {
        get {
            let store = SmartStore.shared(withName: SmartStore.defaultStoreName)!
            SyncState.setupSyncsSoupIfNeeded(store)
            if (!store.soupExists(forName: objectType.objectName)) {
                let indexSpecs  = SoupIndex.asArraySoupIndexes(objectType.indexes)
                do {
                    try store.registerSoup(withName: objectType.objectName, withIndices: indexSpecs)
                } catch let error as NSError {
                    SalesforceLogger.log(type(of:self), level:.error, message: "\(objectType.objectName) failed to register soup: \(error.localizedDescription)")
                }
            }
            return store
            //return SmartStore.shared(withName: SmartStore.defaultStoreName)!
        }
    }
    init() {
        let dataSpec = objectType.dataSpec()
        syncMgr = SyncManager.sharedInstance(forUserAccount: UserAccountManager.shared.currentUserAccount!)
        self.dataSpec = dataSpec! //TODO: this could be better
        // Setup store and syncs if needed
        MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
        MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()
    }
    init(dataSpec: SObjectDataSpec) {
        syncMgr = SyncManager.sharedInstance(forUserAccount: UserAccountManager.shared.currentUserAccount!)
        self.dataSpec = dataSpec
        // Setup store and syncs if needed
        MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
        MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()
    }

    func syncUpDown(completion: @escaping (Bool) -> ()) {
        syncMgr.publishUp(objectType: objectType.self)
            .flatMap { _ in
                self.syncMgr.publishDown(objectType: objectType.self, sqlQueryString: self.sqlQueryString)
        }
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { [weak self] result in
            switch result {
            case .failure(let mobileSyncError):
                MobileSyncLogger.e(Store.self, message: "Sync failed: \(mobileSyncError.localizedDescription)")
                completion(false)
            case .finished:
                self?.loadLocalData()
                completion(true)
            }
            }, receiveValue: { _ in })
            .store(in: &cancellableSet)
        loadLocalData()
    }
    
    func loadLocalData() {
        let sobjectsQuerySpec = QuerySpec.buildAllQuerySpec(soupName: dataSpec.soupName, orderPath: dataSpec.orderByFieldName, order: .ascending, pageSize: kMaxQueryPageSize)
        store.publisher(for: sobjectsQuerySpec.smartSql)
            .receive(on: RunLoop.main)
            .tryMap {
                $0.map { (data) -> objectType in
                    let record = data as! [Any]
                    return objectType(soupDict: record[0] as? [String : Any])
                }
        }
        .catch { error -> Just<[objectType]> in
            MobileSyncLogger.e(Store.self, message: "Query failed: \(error)")
            return Just([objectType]())
        }
        .assign(to: \.items, on: self)
        .store(in: &cancellableSet)
    }
    
    public func upsertEntries(jsonResponse: Any, completion: SyncCompletion = nil) {
        let dataRows = (jsonResponse as! NSDictionary)["records"] as! [String:Any]
        SalesforceLogger.log(type(of:self), level:.debug, message:"request:didLoadResponse: #records: \(dataRows.count)")
        store.upsert(entries: [dataRows], forSoupNamed: objectType.objectName)
        completion?(nil)
    }
    
    public func upsertEntries<T:StoreProtocol>(record: T, completion: SyncCompletion = nil) {
        store.upsert(entries: [record.soupDict], forSoupNamed: T.objectName)
        completion?(nil)
    }
    
    public func upsertNewEntries<T:StoreProtocol>(entry: T, completion: SyncCompletion = nil) {
        var record: T = entry
        record.local = true
        record.locallyCreated = true
        record.objectType = T.objectName
        store.upsert(entries: [record.soupDict], forSoupNamed: T.objectName)
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
        store.upsert(entries: [record.soupDict], forSoupNamed: T.objectName)
        
        syncUp() { syncState in
            if let _ = syncState?.isDone() {
                self.syncDown(completion: completion)
            }
        }
    }
    public func syncDown(completion: SyncCompletion = nil) {
        let target: SoqlSyncDownTarget = SoqlSyncDownTarget.newSyncTarget(sqlQueryString)
        let options: SyncOptions = SyncOptions.newSyncOptions(forSyncDown: .overwrite)
        self.syncMgr.syncDown(target: target, options: options, soupName: objectType.objectName, onUpdate: completion ?? { _ in return })
    }
    public func syncUp(completion: SyncCompletion = nil) {
        let updateBlock = { [unowned self] (syncState: SyncState?) in
            if let syncState = syncState {
                if syncState.isDone() || syncState.hasFailed() {
                    DispatchQueue.main.async {
                        if syncState.hasFailed() {
                            SalesforceLogger.log(type(of:self), level:.error, message:"syncUp \(objectType.objectName) failed")
                        }
                        else {
                            //                            SalesforceLogger.log(type(of:self), level:.debug, message:"syncUp \(objectType.objectName) done")
                        }
                    }
                    completion?(syncState)
                }
            }
        }
        
        DispatchQueue.main.async(execute: {
            let options: SyncOptions = SyncOptions.newSyncOptions(forSyncUp: objectType.readFields, mergeMode: .leaveIfChanged)
            let target = SyncUpTarget.init(createFieldlist: objectType.createFields, updateFieldlist: objectType.updateFields)
            self.syncMgr.syncUp(target: target, options: options, soupName: objectType.objectName, onUpdate: updateBlock)
        })
    }
    
    public func record(index: Int) -> objectType {
        //TODO: this should have a where
        let query = QuerySpec.buildAllQuerySpec(soupName: dataSpec.soupName, orderPath: dataSpec.orderByFieldName, order: .ascending, pageSize: kMaxQueryPageSize)
        
        // let query:QuerySpec = QuerySpec.buildSmartQuerySpec(smartSql: queryString, pageSize: 1)!
        let results = store.query(query.smartSql)
        do {
            let results = try results.get()
            return objectType.from(results)
        } catch {
            SalesforceLogger.log(type(of:self), level:.error, message:"fetch \(objectType.objectName) failed:")
            return objectType()
        }
    }
    
    
    public func records() -> [objectType] {
        let query = QuerySpec.buildAllQuerySpec(soupName: dataSpec.soupName, orderPath: dataSpec.orderByFieldName, order: .ascending, pageSize: kMaxQueryPageSize)
        let results = store.query(query.smartSql)
        do {
            let results = try results.get()
            return objectType.from(results)
        } catch {
            SalesforceLogger.log(type(of:self), level:.error, message:"fetch \(objectType.objectName) failed:")
            return []
        }
    }
    
    func createLocalData(_ newData: SFRecord?) {
        guard let newData = newData else {
            return
        }
        newData.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        newData.updateSoup(forFieldName: kSyncTargetLocallyCreated, fieldValue: true)
        let sobjectSpec = type(of: newData).dataSpec()
        
        store.upsert(entries: [newData.soupDict], forSoupNamed: (sobjectSpec?.soupName)!)
        loadLocalData()
    }
    
    func updateLocalData(_ updatedData: SFRecord?) {
        guard let updatedData = updatedData else {
            return
        }
        updatedData.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        updatedData.updateSoup(forFieldName: kSyncTargetLocallyUpdated, fieldValue: true)
        let sobjectSpec = type(of: updatedData).dataSpec()
        
        store.upsert(entries: [updatedData.soupDict], forSoupNamed: (sobjectSpec?.soupName)!)
        loadLocalData()
    }
    
    func deleteLocalData(_ dataToDelete: SFRecord?) {
        guard let dataToDelete = dataToDelete else {
            return
        }
        dataToDelete.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        dataToDelete.updateSoup(forFieldName: kSyncTargetLocallyDeleted, fieldValue: true)
        let sobjectSpec = type(of: dataToDelete).dataSpec()
        
        store.upsert(entries: [dataToDelete.soupDict], forSoupNamed: (sobjectSpec?.soupName)!)
        loadLocalData()
    }
    
    func undeleteLocalData(_ dataToUnDelete: SFRecord?) {
        guard let dataToUnDelete = dataToUnDelete else {
            return
        }
        dataToUnDelete.updateSoup(forFieldName: kSyncTargetLocallyDeleted, fieldValue: false)
        let locallyCreatedOrUpdated = Store.dataLocallyCreated(dataToUnDelete) || Store.dataLocallyUpdated(dataToUnDelete) ? 1 : 0
        dataToUnDelete.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: locallyCreatedOrUpdated)
        let sobjectSpec = type(of: dataToUnDelete).dataSpec()
        
        do {
            _ = try store.upsert(entries: [dataToUnDelete.soupDict], forSoupNamed: (sobjectSpec?.soupName)!, withExternalIdPath: SObjectConstants.kSObjectIdField)
            loadLocalData()
        } catch let error as NSError {
            MobileSyncLogger.e(Store.self, message: "Undelete local data failed \(error)")
        }
    }
    
    static func dataLocallyCreated(_ data: SFRecord?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyCreated) as? Bool
        return value ?? false
    }
    
    func hasChanged() -> Bool {
        var changed = false
        for item in self.items {
            changed = changed || item.local
        }
        return changed
    }
    
    static func dataLocallyUpdated(_ data: SFRecord?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyUpdated) as? Bool
        return value ?? false
    }
    
    static func dataLocallyDeleted(_ data: SFRecord?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyDeleted) as? Bool
        return value ?? false
    }
    
    func clearLocalData() {
        store.clearSoup(dataSpec.soupName)
        //resetSync(kSyncDownName)
        //resetSync(kSyncUpName)
        loadLocalData()
    }
    
    func stopSyncManager() {
        syncMgr.stop()
    }
    
    func resumeSyncManager(_ completion: @escaping (SyncState) -> Void) throws -> Void {
        try self.syncMgr.restart(restartStoppedSyncs:true, onUpdate:{ [weak self] (syncState) in
            if (syncState.status == .done) {
                self?.loadLocalData()
            }
            completion(syncState)
        })
    }
    
    func cleanGhosts(onError: @escaping (MobileSyncError) -> (), onValue: @escaping (UInt) -> ()) {
        syncMgr.cleanGhostsPublisher(for: "NOT IMPLEMENTED")
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { result in
                if case .failure(let mobileSyncError) = result {
                    onError(mobileSyncError)
                }
            }, receiveValue: { numRecords in
                onValue(numRecords)
            })
            .store(in: &cancellableSet)
    }
    
    func syncUp(onError: @escaping (MobileSyncError) -> (), onValue: @escaping (SyncState) -> ()) {
        syncMgr.publishUp(objectType: objectType.self)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { result in
                if case .failure(let mobileSyncError) = result {
                    onError(mobileSyncError)
                }
                
            }, receiveValue: { syncState in
                onValue(syncState)
            })
            .store(in: &cancellableSet)
    }
    
    func syncDown(onError: @escaping (MobileSyncError) -> (), onValue: @escaping (SyncState) -> ()) {
        syncMgr.publishDown(objectType: objectType.self, sqlQueryString: sqlQueryString)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { result in
                if case .failure(let mobileSyncError) = result {
                    onError(mobileSyncError)
                }
                
            }, receiveValue: { syncState in
                onValue(syncState)
            })
            .store(in: &cancellableSet)
    }
    
    
    func getSync(_ syncName: String) -> SyncState {
        return syncMgr.syncStatus(forName: syncName)!
    }
    
    func isSyncManagerStopping() -> Bool {
        return syncMgr.isStopping()
    }
    
    func isSyncManagerStopped() -> Bool {
        return syncMgr.isStopped()
    }
    
    func count() -> Int {
        var count = -1
        if let querySpec = QuerySpec.buildSmartQuerySpec(smartSql: "select * from {\(dataSpec.soupName)}", pageSize: UInt.max) {
            do {
                count = try store.count(using:querySpec).intValue
            } catch {
                MobileSyncLogger.e(Store.self, message: "count \(error)" )
            }
        }
        return count
    }
    
    private func resetSync(_ syncName: String) {
        let sync = syncMgr.syncStatus(forName:syncName)
        sync?.maxTimeStamp = -1
        sync?.progress = 0
        sync?.status = .new
        sync?.totalSize = -1
        sync?.save(store)
    }
}
public class SObjectDataSpec  {
    
    var objectType = ""
    var objectFieldSpecs = [SObjectDataFieldSpec]()
    var indexSpecs = [AnyObject]()
    
    var soupName = ""
    var orderByFieldName = ""
    
    var fieldNames :[String]  {
        get {
            var mutableFieldNames = [String]()
            objectFieldSpecs.forEach { (spec) in
                if (spec.fieldName != "") {
                    mutableFieldNames.append(spec.fieldName)
                }
            }
            return mutableFieldNames
        }
    }
    
    var soupFieldNames :[String] {
        get {
            var retNames = [String]()
            objectFieldSpecs.forEach { (spec) in
                if (spec.fieldName != "") {
                    retNames.append(spec.fieldName)
                }
            }
            return retNames
        }
    }
    
    init(objectType: String?, objectFieldSpecs: [SObjectDataFieldSpec], soupName: String, orderByFieldName: String) {
        self.objectType = objectType ?? ""
        self.objectFieldSpecs = buildObjectFieldSpecs(objectFieldSpecs)
        
        
        if let idx = SoupIndex(path: orderByFieldName, indexType: kSoupIndexTypeString, columnName: orderByFieldName) {
            if let idx2 = buildSoupIndexSpecs([idx]) {
                self.indexSpecs = idx2
            }
        }
        self.soupName = soupName
        self.orderByFieldName = orderByFieldName
    }
    
    func buildObjectFieldSpecs(_ origObjectFieldSpecs: [SObjectDataFieldSpec]) -> [SObjectDataFieldSpec] {
        
        let spec: [SObjectDataFieldSpec] = origObjectFieldSpecs.filter({ (fieldSpec) -> Bool in
            return fieldSpec.fieldName == SObjectConstants.kSObjectIdField
        })
        
        if (spec.count > 0) {
            var objectFieldSpecsWithId: [SObjectDataFieldSpec] = [SObjectDataFieldSpec]()
            let idSpec = SObjectDataFieldSpec(fieldName: SObjectConstants.kSObjectIdField, searchable: false)
            objectFieldSpecsWithId.insert(idSpec, at: 0)
            return objectFieldSpecsWithId
        } else {
            return origObjectFieldSpecs
        }
    }
    
    func buildSoupIndexSpecs(_ origIndexSpecs: [SoupIndex]?) -> [SoupIndex]? {
        
        var mutableIndexSpecs: [SoupIndex] = []
        guard let origIndexSpecs = origIndexSpecs else {
            return mutableIndexSpecs
        }
        
        let isLocalDataIndexSpec = SoupIndex(path: kSyncTargetLocal, indexType: kSoupIndexTypeString, columnName: kSyncTargetLocal)
        mutableIndexSpecs.insert(isLocalDataIndexSpec!, at: 0)
        
        let foundIdSpec:[SoupIndex]? = origIndexSpecs.filter { (index) -> Bool in
            return index.path == SObjectConstants.kSObjectIdField
        }
        
        if (foundIdSpec == nil || (foundIdSpec?.count)! < 1) {
            let dataIndexSpec = SoupIndex(path: SObjectConstants.kSObjectIdField, indexType: kSoupIndexTypeString, columnName: SObjectConstants.kSObjectIdField)
            mutableIndexSpecs.insert(dataIndexSpec!, at: 0)
        }
        
        return mutableIndexSpecs
    }
    
}

class SObjectDataFieldSpec  {
    
    var fieldName: String = ""
    var isSearchable = false
    
    init(fieldName: String?, searchable isSearchable: Bool) {
        self.fieldName = fieldName ?? ""
        self.isSearchable = isSearchable
    }
}

class CodedSObjectDataSpec: SObjectDataSpec {
    
    convenience init(allCases: [String], name: String) {
        var objectFieldSpecs: [SObjectDataFieldSpec] = []
        
        for value in allCases {
            objectFieldSpecs.append(
                SObjectDataFieldSpec(fieldName: value, searchable: true))
        }
        
        let objectType = name
        let soupName = name
        let orderByFieldName: String  = allCases[0]
        self.init(objectType: objectType, objectFieldSpecs: objectFieldSpecs, soupName: soupName, orderByFieldName: orderByFieldName)
    }
}
