//
//  Pricebook.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/3/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class Pricebook: Record, StoreProtocol {
    
    public enum Field: String {
        case createdById = "CreatedById"
        case description = "Description"
        case pricebookId = "Id"
        case isActive = "IsActive"
        case isArchived = "IsArchived"
        case isDeleted = "IsDeleted"
        case isStandard = "IsStandard"
        case name = "Name"
        
        static let allFields = [createdById.rawValue, description.rawValue, pricebookId.rawValue, isActive.rawValue, isArchived.rawValue, isDeleted.rawValue, isStandard.rawValue, name.rawValue]
    }
    
    public fileprivate(set) lazy var createdById: String? = data[Field.createdById.rawValue] as? String
    public fileprivate(set) lazy var description: String? = data[Field.description.rawValue] as? String
    public fileprivate(set) lazy var pricebookId: String? = data[Field.pricebookId.rawValue] as? String
    public fileprivate(set) lazy var isActive: String? = data[Field.isActive.rawValue] as? String
    public fileprivate(set) lazy var isArchived: String? = data[Field.isArchived.rawValue] as? String
    public fileprivate(set) lazy var isDeleted: String? = data[Field.isDeleted.rawValue] as? String
    public fileprivate(set) lazy var isStandard: String? = data[Field.isStandard.rawValue] as? String
    public fileprivate(set) lazy var name: String? = data[Field.name.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.createdById.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.pricebookId.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public static var objectName: String = "Pricebook2"
    
    public static var orderPath: String = Field.pricebookId.rawValue
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + Field.allFields
    }
    public override static var updateFields: [String] {
        return super.updateFields + Field.allFields
    }
}
