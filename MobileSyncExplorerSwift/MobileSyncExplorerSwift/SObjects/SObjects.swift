/*
 ViewController.swift
 MobileSyncExplorerSwift
 
 Created by Raj Rao on 05/16/18.
 
 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
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
import SmartStore
import MobileSync
import Combine

enum SObjectConstants {
    static let kSObjectIdField    = "Id"
}

extension Dictionary {
    
    func nonNullObject(forKey key: Key) -> Any? {
        let result = self[key]
        if (result as? NSNull) == NSNull() {
            return nil
        }
        
        if (result is String) {
            let res = result as! String
            if ((res == "<nil>") || (res == "<null>")) {
                return nil
            }
        }
        return result
    }
 
}

extension Optional where Wrapped == String {
    var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}

class SObjectData  {
    
    var soupDict = [String: Any]()
    
    init(soupDict: [String: Any]?) {
        if soupDict != nil {
            self.updateSoup(soupDict)
        }
    }

    init() {
        soupDict = [:]
        let spec = type(of: self).dataSpec()
        self.initSoupValues(spec?.fieldNames)
        updateSoup(forFieldName: "attributes", fieldValue: ["type": spec?.objectType])
    }
    
    class func dataSpec() -> SObjectDataSpec? {
        return nil
    }
    
    func initSoupValues(_ fieldNames: [Any]?) {
        self.soupDict.forEach { (key,value) in
            self.soupDict[key] = nil
        }
    }
    
    func fieldValue(forFieldName fieldName: String) -> Any? {
        return self.soupDict[fieldName]
    }
    
    func updateSoup(forFieldName fieldName: String, fieldValue: Any?) {
        self.soupDict[fieldName] = fieldValue
    }
    
    func updateSoup(_ soupDict: [String: Any]?) -> Void  {
        guard let soupDict = soupDict else {
            return;
        }
        soupDict.forEach({ (key, value) in
            self.soupDict[key] = value
        })
    }
    
    func nonNullFieldValue(_ fieldName: String?) -> Any? {
        return self.soupDict.nonNullObject(forKey: fieldName!)
    }
}

class SObjectDataSpec  {
    
    var objectType = ""
    var objectFieldSpecs = [SObjectDataFieldSpec]()
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
    
    class func createSObjectData(_ soupDict: [String : Any]?) throws -> SObjectData? {
       return nil
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

class SObjectDataManager: ObservableObject {
    static let shared = SObjectDataManager(dataSpec: ContactSObjectData.dataSpec()!)
    @Published var contacts: [ContactSObjectData] = []
    private var cancellableSet: Set<AnyCancellable> = []

    //Constants
    let kSyncDownName = "syncDownContacts"
    let kSyncUpName = "syncUpContacts"
    private let kMaxQueryPageSize: UInt = 1000
    
    var syncMgr: SyncManager
    var dataSpec: SObjectDataSpec
    
    var store: SmartStore {
        get {
            return SmartStore.shared(withName: SmartStore.defaultStoreName)!
        }
    }

    init(dataSpec: SObjectDataSpec) {
        syncMgr = SyncManager.sharedInstance(forUserAccount: UserAccountManager.shared.currentUserAccount!)
        self.dataSpec = dataSpec
        // Setup store and syncs if needed
        MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
        MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()
    }

    func syncUpDown(completion: @escaping (Bool) -> ()) {
        syncMgr.publisher(for: kSyncUpName)
            .flatMap { _ in
                self.syncMgr.publisher(for: self.kSyncDownName)
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let mobileSyncError):
                    MobileSyncLogger.e(SObjectDataManager.self, message: "Sync failed: \(mobileSyncError.localizedDescription)")
                    completion(false)
                case .finished:
                    self?.loadLocalData()
                    completion(true)
                }
            }, receiveValue: { _ in })
            .store(in: &cancellableSet)
        loadLocalData()
    }

    func fetchContact(id: String, completion: @escaping (ContactSObjectData?) -> ()) {
        let request = RestClient.shared.request(forQuery: "SELECT Id, FirstName, LastName, Title, MobilePhone, Email, Department, HomePhone FROM Contact WHERE Id = '\(id)'", apiVersion: nil)
        RestClient.shared.publisher(for: request)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { [weak self] response in
                do {
                    guard let json = try response.asJson() as? [String: Any],
                    let records = json["records"] as? [[String: Any]],
                    records.count > 0 else {
                        completion(nil)
                        return
                    }
                    try self?.store.upsert(entries: records, forSoupNamed: "contacts", withExternalIdPath: "Id")
                    self?.loadLocalData() // Keep list in sync
                } catch {
                    MobileSyncLogger.e(SObjectDataManager.self, message: "Contact error: \(error)")
                    completion(ContactSObjectData.init(soupDict: self?.localRecord(id: id)))
                }
                let localRecord = ContactSObjectData.init(soupDict: self?.localRecord(id: id))
                completion(localRecord)
            })
             .store(in: &cancellableSet)
    }

    func loadLocalData() {
        let sobjectsQuerySpec = QuerySpec.buildAllQuerySpec(soupName: dataSpec.soupName, orderPath: dataSpec.orderByFieldName, order: .ascending, pageSize: kMaxQueryPageSize)
        store.publisher(for: sobjectsQuerySpec.smartSql)
            .receive(on: RunLoop.main)
            .tryMap {
                $0.map { (data) -> ContactSObjectData in
                    let record = data as! [Any]
                    return ContactSObjectData(soupDict: record[0] as? [String : Any])
                }
            }
            .catch { error -> Just<[ContactSObjectData]> in
                MobileSyncLogger.e(SObjectDataManager.self, message: "Query failed: \(error)")
                return Just([ContactSObjectData]())
            }
            .assign(to: \.contacts, on: self)
            .store(in: &cancellableSet)
    }

    func createLocalData(_ newData: SObjectData?) {
        guard let newData = newData else {
            return
        }
        newData.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        newData.updateSoup(forFieldName: kSyncTargetLocallyCreated, fieldValue: true)
        let sobjectSpec = type(of: newData).dataSpec()

        store.upsert(entries: [newData.soupDict], forSoupNamed: (sobjectSpec?.soupName)!)
        loadLocalData()
    }

    func updateLocalData(_ updatedData: SObjectData?) {
        guard let updatedData = updatedData else {
            return
        }
        updatedData.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        updatedData.updateSoup(forFieldName: kSyncTargetLocallyUpdated, fieldValue: true)
        let sobjectSpec = type(of: updatedData).dataSpec()

        store.upsert(entries: [updatedData.soupDict], forSoupNamed: (sobjectSpec?.soupName)!)
        loadLocalData()
    }

    func deleteLocalData(_ dataToDelete: SObjectData?) {
        guard let dataToDelete = dataToDelete else {
            return
        }
        dataToDelete.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        dataToDelete.updateSoup(forFieldName: kSyncTargetLocallyDeleted, fieldValue: true)
        let sobjectSpec = type(of: dataToDelete).dataSpec()

        store.upsert(entries: [dataToDelete.soupDict], forSoupNamed: (sobjectSpec?.soupName)!)
        loadLocalData()
    }

    func undeleteLocalData(_ dataToUnDelete: SObjectData?) {
        guard let dataToUnDelete = dataToUnDelete else {
            return
        }
        dataToUnDelete.updateSoup(forFieldName: kSyncTargetLocallyDeleted, fieldValue: false)
        let locallyCreatedOrUpdated = SObjectDataManager.dataLocallyCreated(dataToUnDelete) || SObjectDataManager.dataLocallyUpdated(dataToUnDelete) ? 1 : 0
        dataToUnDelete.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: locallyCreatedOrUpdated)
        let sobjectSpec = type(of: dataToUnDelete).dataSpec()

        do {
            _ = try store.upsert(entries: [dataToUnDelete.soupDict], forSoupNamed: (sobjectSpec?.soupName)!, withExternalIdPath: SObjectConstants.kSObjectIdField)
            loadLocalData()
        } catch let error as NSError {
            MobileSyncLogger.e(SObjectDataManager.self, message: "Undelete local data failed \(error)")
        }
    }

    static func dataLocallyCreated(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyCreated) as? Bool
        return value ?? false
    }

    static func dataLocallyUpdated(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyUpdated) as? Bool
        return value ?? false
    }

    static func dataLocallyDeleted(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyDeleted) as? Bool
        return value ?? false
    }

    func clearLocalData() {
        store.clearSoup(dataSpec.soupName)
        resetSync(kSyncDownName)
        resetSync(kSyncUpName)
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
        syncMgr.cleanGhostsPublisher(for: kSyncDownName)
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

    func sync(syncName: String, onError: @escaping (MobileSyncError) -> (), onValue: @escaping (SyncState) -> ()) {
        syncMgr.publisher(for: kSyncDownName)
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

    func getSync(_ syncName: String) -> SyncState? {
        return syncMgr.syncStatus(forName: syncName)
    }

    func isSyncManagerStopping() -> Bool {
        return syncMgr.isStopping()
    }

    func isSyncManagerStopped() -> Bool {
       return syncMgr.isStopped()
    }

    func countContacts() -> Int {
       var count = -1
       if let querySpec = QuerySpec.buildSmartQuerySpec(smartSql: "select * from {\(dataSpec.soupName)}", pageSize: UInt.max) {
           do {
               count = try store.count(using:querySpec).intValue
           } catch {
               MobileSyncLogger.e(SObjectDataManager.self, message: "countContacts \(error)" )
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

    private func localRecord(id: String) -> [String: Any]? {
        let queryResult = store.query("select {\(dataSpec.soupName):_soup} from {\(dataSpec.soupName)} where {\(dataSpec.soupName):Id} = '\(id)'")
        switch queryResult {
        case .success(let results):
            guard let arr = results as? [[Any]], let soup = arr.first?.first as? [String: Any] else {
                MobileSyncLogger.e(SObjectDataManager.self, message: "Unable to parse local record")
                return nil
            }
            return soup
        case .failure(let error):
            MobileSyncLogger.e(SObjectDataManager.self, message: "Error getting local record: \(error)")
            return nil
        }
    }
}
