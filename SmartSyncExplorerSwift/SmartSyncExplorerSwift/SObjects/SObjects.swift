/*
 ViewController.swift
 SmartSyncExplorerSwift
 
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
import SmartSync
import PromiseKit
import SalesforceSwiftSDK

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
    
    func buildSoupIndexSpecs(_ origIndexSpecs: [SFSoupIndex]?) -> [SFSoupIndex]? {
        
        var mutableIndexSpecs: [SFSoupIndex] = []
        guard let origIndexSpecs = origIndexSpecs else {
            return mutableIndexSpecs
        }
        
        let isLocalDataIndexSpec = SFSoupIndex(path: kSyncTargetLocal, indexType: kSoupIndexTypeString, columnName: kSyncTargetLocal)
        mutableIndexSpecs.insert(isLocalDataIndexSpec!, at: 0)
        
        let foundIdSpec:[SFSoupIndex]? = origIndexSpecs.filter { (index) -> Bool in
            return index.path == SObjectConstants.kSObjectIdField
        }
        
        if (foundIdSpec==nil || (foundIdSpec?.count)! < 1) {
            let dataIndexSpec = SFSoupIndex(path: SObjectConstants.kSObjectIdField, indexType: kSoupIndexTypeString, columnName: SObjectConstants.kSObjectIdField)
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


class SObjectDataManager {

    //Constants
    private let kSearchFilterQueueName = "com.salesforce.smartSyncExplorer.searchFilterQueue"
    private let kSyncDownName = "syncDownContacts";
    private let kSyncUpName = "syncUpContacts";
    private let kMaxQueryPageSize: UInt = 1000;
    
    private var searchFilterQueue: DispatchQueue?
    
    var syncMgr: SFSmartSyncSyncManager?
    var dataSpec: SObjectDataSpec
    var fullDataRowList = [SObjectData]()
    var dataRows = [SObjectData]()
    
    var store: SFSmartStore {
        get {
            return SFSmartStore.sharedStore(withName: kDefaultSmartStoreName) as! SFSmartStore
        }
    }

    init(dataSpec: SObjectDataSpec) {

        syncMgr = SFSmartSyncSyncManager.sharedInstance(SFUserAccountManager.sharedInstance().currentUser!)
        self.dataSpec = dataSpec
        searchFilterQueue = DispatchQueue(label: kSearchFilterQueueName)
        // Setup store and syncs if needed
        SmartSyncSDKManager.shared().setupUserStoreFromDefaultConfig()
        SmartSyncSDKManager.shared().setupUserSyncsFromDefaultConfig()
    }

    func queryLocalData() -> Promise<[Any]>  {
        let sobjectsQuerySpec = SFQuerySpec.newAllQuerySpec(self.dataSpec.soupName, withOrderPath: dataSpec.orderByFieldName, with: .ascending, withPageSize: kMaxQueryPageSize)
        return store.Promises.query(querySpec: sobjectsQuerySpec, pageIndex: 0)
    }
    
    func populateDataRows(_ queryResults: [Any]?) -> [SObjectData] {
        var mutableDataRows: [SObjectData] = [SObjectData]()
        queryResults?.forEach({ (record) in
            let sObject = ContactSObjectData(soupDict: record as? [String : Any])
            mutableDataRows.append(sObject)
        })
        return mutableDataRows
    }

    func createLocalData(_ newData: SObjectData?) -> Promise<[SObjectData]> {
        guard let newData = newData else {
            return Promise(value: [SObjectData]())
        }
        newData.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        newData.updateSoup(forFieldName: kSyncTargetLocallyCreated, fieldValue: true)
        let sobjectSpec = type(of: newData).dataSpec()
        return store.Promises.upsertEntries(entries: [newData.soupDict], soupName: (sobjectSpec?.soupName)!)
        .then { result -> Promise<[Any]> in
            self.queryLocalData()
         }.then { sObjects -> Promise<[SObjectData]>  in
            self.fullDataRowList = self.populateDataRows(sObjects)
            return Promise(value: self.fullDataRowList)
        }
    }

    func updateLocalData(_ updatedData: SObjectData?) -> Promise<[SObjectData]> {
        guard let updatedData = updatedData else {
            return Promise(value: [SObjectData]())
        }
        updatedData.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        updatedData.updateSoup(forFieldName: kSyncTargetLocallyUpdated, fieldValue: true)
        let sobjectSpec = type(of: updatedData).dataSpec()
        return store.Promises.upsertEntries(entries: [updatedData.soupDict], soupName: (sobjectSpec?.soupName)!)
            .then { result -> Promise<[Any]> in
                self.queryLocalData()
            }.then { sObjects -> Promise<[SObjectData]>  in
                self.fullDataRowList = self.populateDataRows(sObjects)
                return Promise(value: self.fullDataRowList)
            }
    }

    func deleteLocalData(_ dataToDelete: SObjectData?) -> Promise<[SObjectData]> {
        guard let dataToDelete = dataToDelete else {
            return Promise(value: [SObjectData]())
        }
        dataToDelete.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: true)
        dataToDelete.updateSoup(forFieldName: kSyncTargetLocallyDeleted, fieldValue: true)
        let sobjectSpec = type(of: dataToDelete).dataSpec()
        return store.Promises.upsertEntries(entries: [dataToDelete.soupDict], soupName: (sobjectSpec?.soupName)!)
            .then { result -> Promise<[Any]> in
                self.queryLocalData()
            }.then { sObjects -> Promise<[SObjectData]>  in
                self.fullDataRowList = self.populateDataRows(sObjects)
                return Promise(value: self.fullDataRowList)
            }
    }

    func undeleteLocalData(_ dataToUnDelete: SObjectData?) -> Promise<[SObjectData]> {
        guard let dataToUnDelete = dataToUnDelete else {
            return Promise(value: [SObjectData]())
        }
        dataToUnDelete.updateSoup(forFieldName: kSyncTargetLocallyDeleted, fieldValue: false)
        let locallyCreatedOrUpdated = dataLocallyCreated(dataToUnDelete) || dataLocallyUpdated(dataToUnDelete) ? 1 : 0
        dataToUnDelete.updateSoup(forFieldName: kSyncTargetLocal, fieldValue: locallyCreatedOrUpdated)
        let sobjectSpec = type(of: dataToUnDelete).dataSpec()
        return store.Promises.upsertEntries(entries: [dataToUnDelete.soupDict], soupName: (sobjectSpec?.soupName)!, externalIdPath: SObjectConstants.kSObjectIdField)
            .then { result -> Promise<[Any]> in
                self.queryLocalData()
            }.then { sObjects -> Promise<[SObjectData]>  in
                self.fullDataRowList = self.populateDataRows(sObjects)
                return Promise(value: self.fullDataRowList)
            }
    }

    func dataHasLocalChanges(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value = data.fieldValue(forFieldName: kSyncTargetLocal) as? Bool
        return value ?? false
    }

    func dataLocallyCreated(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyCreated) as? Bool
        return value ?? false
    }

    func dataLocallyUpdated(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyUpdated) as? Bool
        return value ?? false
    }

    func dataLocallyDeleted(_ data: SObjectData?) -> Bool {
        guard let data = data else {
            return false
        }
        let value =  data.fieldValue(forFieldName: kSyncTargetLocallyDeleted) as? Bool
        return value ?? false
    }
 
   func refreshRemoteData() -> Promise<[SObjectData]>  {
     return when(fulfilled: [self.syncMgr!.Promises.reSync(syncName: kSyncDownName)])
           .then { _ -> Promise<[Any]> in
              self.queryLocalData()
           }
           .then { result -> Promise<[SObjectData]> in
               return Promise(value:self.populateDataRows(result))
           }
    }

    func updateRemoteData() -> Promise<[SObjectData]> {
        return  when(fulfilled: [self.syncMgr!.Promises.reSync(syncName: kSyncUpName)])
                .then { _ in
                    return self.queryLocalData()
                }
                .then { result -> Promise<Void> in
                    self.fullDataRowList = self.populateDataRows(result)
                    return Promise().asVoid()
                }
                .then { _ in
                    return self.refreshRemoteData()
                }
                .then { result -> Promise<[SObjectData]>  in
                    self.fullDataRowList = result
                    return Promise(value : self.fullDataRowList)
                }
        
    }

    func filter(onSearchTerm searchTerm: String?, completion completionBlock: @escaping ([SObjectData]) -> Void) {
        
        guard let searchTerm = searchTerm else {
            return
        }

        searchFilterQueue?.async(execute: {[unowned self] () -> Void in
            self.dataRows = self.fullDataRowList
            if self.dataRows.count < 1 {
                // No data yet.
                return
            }
            var matchingDataRows = [SObjectData]()
            if searchTerm.count > 0 {
                self.fullDataRowList.forEach({ (sDataObject) in
                    let dataSpec: SObjectDataSpec? = ContactSObjectData.dataSpec()
                    
                    if let dataSpec = dataSpec {
                        dataSpec.objectFieldSpecs.forEach({ (fieldSpec) in
                            if fieldSpec.isSearchable {
                                let fieldValue = sDataObject.fieldValue(forFieldName: fieldSpec.fieldName) as? String
                                if let fieldValue = fieldValue {
                                    if let _ = fieldValue.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive], range: fieldValue.startIndex..<fieldValue.endIndex, locale: nil) {
                                        matchingDataRows.append(sDataObject)
                                    }
                                }
                                
                            }
                        })
                    }
                    self.dataRows = matchingDataRows
                })
            }
            completionBlock(self.dataRows)
        })
    }
}


