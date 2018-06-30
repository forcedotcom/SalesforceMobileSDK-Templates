//
//  QuoteLineItem.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/22/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class QuoteLineItem: Record, StoreProtocol {
    public static let objectName: String = "SBQQ__QuoteLine__c"
    
    public enum Field: String {
        case createdById = "CreatedById"
        case description = "SBQQ__Description__c"
        case favorite = "SBQQ__Favorite__c"
        case group = "SBQQ__Group__c"
        case lineNumber = "SBQQ__Number__c"
        case product = "SBQQ__Product__c"
        case quantity = "SBQQ__Quantity__c"
        case quote = "SBQQ__Quote__c"
        case netTotal = "SBQQ__NetTotal__c"
        
        static let allFields = [createdById.rawValue, description.rawValue, favorite.rawValue, group.rawValue, lineNumber.rawValue, product.rawValue, quantity.rawValue, quote.rawValue, netTotal.rawValue]
    }
    
    public init(withLineGroup lineGroup:QuoteLineGroup, forProduct productId:String, quantity:Int, lineNumber:Int?) {
        super.init()
        self.group = lineGroup.externalId
        self.lineNumber = lineNumber
        self.product = productId
        self.quantity = quantity
        self.quote = lineGroup.quote
    }
    
    public required init() {
        super.init()
    }
    
    public required init(data: [Any]) {
        super.init(data: data)
    }
    
    public var description: String? {
        get { return self.data[Field.description.rawValue] as? String}
        set { self.data[Field.description.rawValue] = newValue}
    }
    public var group: String? {
        get { return self.data[Field.group.rawValue] as? String}
        set { self.data[Field.group.rawValue] = newValue}
    }
    public var lineNumber: Int? {
        get { return self.data[Field.lineNumber.rawValue] as? Int}
        set { self.data[Field.lineNumber.rawValue] = newValue}
    }
    public var product: String? {
        get { return self.data[Field.product.rawValue] as? String}
        set { self.data[Field.product.rawValue] = newValue}
    }
    public var quantity: Int? {
        get { return self.data[Field.quantity.rawValue] as? Int}
        set { self.data[Field.quantity.rawValue] = newValue}
    }
    public var quote: String? {
        get { return self.data[Field.quote.rawValue] as? String}
        set { self.data[Field.quote.rawValue] = newValue}
    }
    public fileprivate(set) lazy var createdById: String? = self.data[Field.createdById.rawValue] as? String
    public fileprivate(set) lazy var netTotal: String? = self.data[Field.netTotal.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.favorite.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.group.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.lineNumber.rawValue, "type" : kSoupIndexTypeInteger],
            ["path" : Field.product.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.quote.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + Field.allFields //[Field.description.rawValue, Field.favorite.rawValue, Field.group.rawValue, Field.product.rawValue, Field.quantity.rawValue, Field.quote.rawValue]
    }
    public override static var updateFields: [String] {
        return super.updateFields + Field.allFields
    }
    
    public static var orderPath: String = Field.lineNumber.rawValue
}
