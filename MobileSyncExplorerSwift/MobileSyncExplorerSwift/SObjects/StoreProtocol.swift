//
//  StoreProtocol.swift
//  MobileSyncExplorerSwift
//
//  Created by keith siilats on 4/19/20.
//  Copyright © 2020 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
public protocol StoreProtocol {
    init()
    //    init(data: [Any])
    //    var data: Dictionary<String,Any> {get}
    var soupDict: [String: Any]{get}
    init(soupDict: [String: Any]?)
    static func dataSpec() -> SObjectDataSpec?
    
    static var objectName: String {get}
    var objectType: String? {get set}
    var local: Bool {get set}
    var locallyCreated: Bool {get set}
    var locallyUpdated: Bool {get set}
    var locallyDeleted: Bool {get set}
    var soupEntryId: Int? {get}
    //var externalId: String? {get set}
    static var indexes: [[String:String]] {get}
    static var orderPath: String {get}
    static var readFields: [String] {get}
    static var createFields: [String] {get}
    static var updateFields: [String] {get}
    static func from<T:StoreProtocol>(_ records: [Any]) -> T
    static func from<T:StoreProtocol>(_ records: [Any]) -> [T]
    static func from<T:StoreProtocol>(_ records: Dictionary<String, Any>) -> T
}
public enum SFField: String {
    case id = "Id"
    //case externalId = "MobileExternalId__c"
    case soupEntryId = "_soupEntryId"
    case soupLastModifiedDate = "_soupLastModifiedDate"
    case soupCreatedDate = "_soupCreatedDate"
    case local = "__local__"
    case locallyCreated = "__locally_created__"
    case locallyUpdated = "__locally_updated__"
    case locallyDeleted = "__locally_deleted__"
    case modificationDate = "LastModifiedDate"
    case attributes = "attributes"
    case objectType = "type"
    
    static let allFields = [id.rawValue, modificationDate.rawValue]
}

public class SFRecord {
    //    public required init(data: [Any]) {
    //        self.data = (data as! [Dictionary]).first!
    //    }
    
    public required init() {
        // self.externalId = UUID().uuidString
    }
    var soupDict = [String: Any]()
    
    //  public var data: Dictionary = Dictionary<String,Any>()
    
    
    //    public var externalId: String? {
    //        get { return self.soupDict[SFField.externalId.rawValue] as? String }
    //        set { soupDict[SFField.externalId.rawValue] = newValue }
    //    }
    public private(set) lazy var soupEntryId: Int? = self.soupDict[SFField.soupEntryId.rawValue] as? Int
    public private(set) lazy var id: String? = self.soupDict[SFField.id.rawValue] as? String
    public var objectType: String? {
        get { return (soupDict[SFField.attributes.rawValue] as! Dictionary<String, Any>)[SFField.objectType.rawValue] as? String }
        set {
            if var attributes = soupDict[SFField.attributes.rawValue] as? Dictionary<String, String> {
                attributes[SFField.objectType.rawValue] = newValue
            } else {
                soupDict[SFField.attributes.rawValue] = [SFField.objectType.rawValue : newValue]
            }
        }
    }
    public var local: Bool {
        get { return (soupDict[SFField.local.rawValue] as! String) == "1" }
        set { soupDict[SFField.local.rawValue] = newValue ? "1" : "0" }
    }
    public var locallyCreated: Bool {
        get { return (soupDict[SFField.locallyCreated.rawValue] as! String) == "1" }
        set {
            soupDict[SFField.locallyCreated.rawValue] = newValue ? "1" : "0"
            soupDict[SFField.local.rawValue] = newValue ? "1" : "0"
        }
    }
    public var locallyUpdated: Bool {
        get { return (soupDict[SFField.locallyUpdated.rawValue] as! String) == "1" }
        set {
            soupDict[SFField.locallyUpdated.rawValue] = newValue ? "1" : "0"
            soupDict[SFField.local.rawValue] = newValue ? "1" : "0"
        }
        
    }
    public var locallyDeleted: Bool {
        get { return (soupDict[SFField.locallyDeleted.rawValue] as! String) == "1" }
        set {
            soupDict[SFField.locallyDeleted.rawValue] = newValue ? "1" : "0"
            soupDict[SFField.local.rawValue] = newValue ? "1" : "0"
        }
        
    }
    public class var indexes: [[String:String]] {
        return [["path" : SFField.id.rawValue, "type" : "string"],
                ["path" : SFField.modificationDate.rawValue, "type" : "integer"],
                //                ["path" : SFField.externalId.rawValue, "type" : "string"],
            ["path" : SFField.soupEntryId.rawValue, "type" : "string"],
            ["path" : SFField.local.rawValue, "type" : "integer"],
            ["path" : SFField.locallyCreated.rawValue, "type" : "integer"],
            ["path" : SFField.locallyUpdated.rawValue, "type" : "integer"],
            ["path" : SFField.locallyDeleted.rawValue, "type" : "integer"],
        ]
    }
    public class var readFields: [String] {
        return SFField.allFields + [SFField.soupEntryId.rawValue]
    }
    public class var createFields: [String] {
        return SFField.allFields
    }
    public class var updateFields: [String] {
        return []
    }
    public class var orderPath: String {
        return SFField.id.rawValue
    }
    
}

public extension StoreProtocol {
    func description() -> String {
        return "\(type(of: self).objectName)"
    }
    
    static func from<T:StoreProtocol>(_ records: [Any]) -> T {
        var resultsDictionary = Dictionary<String, Any>()
        if let results = records.first as? [Any] {
            zip(T.readFields, results).forEach { resultsDictionary[$0.0] = $0.1 }
        } else if let results = records.first as? Dictionary<String, Any> {
            return T.from(results)
        }
        return T(soupDict: resultsDictionary)
    }
    
    static func from<T:StoreProtocol>(_ records: Dictionary<String, Any>) -> T {
        return T(soupDict: records)
    }
    
    static func from<T:StoreProtocol>(_ records: [Any]) -> [T] {
        return records.map {
            if let record = $0 as? Dictionary<String, Any> {
                return T.from(record)
            } else if let record = $0 as? [Any] {
                var resultsDictionary = Dictionary<String, Any>()
                zip(T.readFields, record).forEach { resultsDictionary[$0.0] = $0.1 }
                return T.from(resultsDictionary)
            } else {
                return T()
            }
        }
    }
    
    static func selectFieldsString() -> String {
        return readFields.map { return "{\(objectName):\($0)}" }.joined(separator: ", ")
    }
}
