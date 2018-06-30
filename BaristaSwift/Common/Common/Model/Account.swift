//
//  Account.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/1/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class Account: Record, StoreProtocol {
    
    public enum Field: String {
        case accountNumber = "AccountNumber"
        case billingAddress = "BillingAddress"
        case createdById = "CreatedById"
        case createdDate = "CreatedDate"
        case description = "Description"
        case accountId = "Id"
        case name = "Name"
        case ownerId = "OwnerId"
        case parentId = "ParentId"
        case phone = "Phone"
        
        static let allFields = [accountNumber.rawValue, billingAddress.rawValue, createdById.rawValue, description.rawValue, accountId.rawValue, name.rawValue, ownerId.rawValue, parentId.rawValue, phone.rawValue]
    }
    
    public fileprivate(set) lazy var accountId: String? = data[Field.accountId.rawValue] as? String
    public var accountNumber: String? {
        get { return self.data[Field.accountNumber.rawValue] as? String}
        set { self.data[Field.accountNumber.rawValue] = newValue}
    }
    public var description: String? {
        get { return self.data[Field.description.rawValue] as? String}
        set { self.data[Field.description.rawValue] = newValue}
    }
    public var name: String? {
        get { return self.data[Field.name.rawValue] as? String}
        set { self.data[Field.name.rawValue] = newValue}
    }
    public var ownerId: String? {
        get { return self.data[Field.ownerId.rawValue] as? String}
        set { self.data[Field.ownerId.rawValue] = newValue}
    }
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.ownerId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.parentId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.accountNumber.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public static var objectName: String = "Account"
    
    public static var orderPath: String = Field.accountId.rawValue
    
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
