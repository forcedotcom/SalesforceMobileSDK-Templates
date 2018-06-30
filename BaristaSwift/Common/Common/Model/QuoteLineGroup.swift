//
//  QuoteLineGroup.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/22/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class QuoteLineGroup: Record, StoreProtocol {
    public static let objectName: String = "SBQQ__QuoteLineGroup__c"
    
    public enum Field: String {
        case createdById = "CreatedById"
        case account = "SBQQ__Account__c"
        case groupName = "Name"
        case number = "SBQQ__Number__c"
        case quote = "SBQQ__Quote__c"
        case netTotal = "SBQQ__NetTotal__c"
        
        static let allFields = [createdById.rawValue, account.rawValue, groupName.rawValue, number.rawValue, quote.rawValue, netTotal.rawValue]
    }
    
    public var account: String? {
        get { return self.data[Field.account.rawValue] as? String}
        set { self.data[Field.account.rawValue] = newValue}
    }
    public var groupName: String? {
        get { return self.data[Field.groupName.rawValue] as? String}
        set { self.data[Field.groupName.rawValue] = newValue}
    }
    public var number: String? {
        get { return self.data[Field.number.rawValue] as? String}
        set { self.data[Field.number.rawValue] = newValue}
    }
    public var quote: String? {
        get { return self.data[Field.quote.rawValue] as? String}
        set { self.data[Field.quote.rawValue] = newValue}
    }
    public var netTotal: String? {
        get { return self.data[Field.netTotal.rawValue] as? String}
        set { self.data[Field.netTotal.rawValue] = newValue}
    }
    public fileprivate(set) lazy var createdById: String? = self.data[Field.createdById.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.account.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.groupName.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.quote.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + [Field.account.rawValue, Field.groupName.rawValue, Field.quote.rawValue]
    }
    public override static var updateFields: [String] {
        return super.updateFields + [Field.groupName.rawValue, Field.number.rawValue, Field.netTotal.rawValue]
    }
    
    public static var orderPath: String = Field.quote.rawValue
}
