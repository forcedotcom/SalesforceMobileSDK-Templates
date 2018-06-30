//
//  UserFavorite.swift
//  Common
//
//  Created by Nicholas McDonald on 3/18/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class UserFavorite: Record, StoreProtocol {
    public static let objectName:String = "UserFavorite__c"
    
    public enum Field: String {
        case name = "Name"
        case productId = "Product__c"
        case ownerId = "OwnerId"
        case accountId = "Account__c"
        
        static let allFields = [name.rawValue, productId.rawValue, ownerId.rawValue, accountId.rawValue]
    }

    public var name: String? {
        get { return data[Field.name.rawValue] as? String}
        set { self.data[Field.name.rawValue] = newValue}
    }
    public var productId: String? {
        get { return data[Field.productId.rawValue] as? String}
        set {self.data[Field.productId.rawValue] = newValue}
    }
    public var accountId: String? {
        get { return data[Field.accountId.rawValue] as? String}
        set {self.data[Field.accountId.rawValue] = newValue}
    }
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.productId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.ownerId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.accountId.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + Field.allFields
    }
    public override static var updateFields: [String] {
        return super.updateFields + [Field.name.rawValue, Field.productId.rawValue, Field.accountId.rawValue]
    }
    
    public static var orderPath: String = Field.name.rawValue
    
}
