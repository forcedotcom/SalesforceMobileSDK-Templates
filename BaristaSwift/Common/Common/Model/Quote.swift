//
//  Quote.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/21/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public enum QuoteStage: String {
    case draft = "Draft"
    case inReview = "In Review"
    case approved = "Approved"
    case denied = "Denied"
    case presented = "Presented"
    case accepted = "Accepted"
}

public class Quote: Record, StoreProtocol {
    public static let objectName: String = "SBQQ__Quote__c"
    
    public enum Field: String {
        case createdById = "CreatedById"
        case quoteId = "Id"
        case quoteNumber = "Name"
        case ownerId = "OwnerId"
        case account = "SBQQ__Account__c"
        case opportunity = "SBQQ__Opportunity2__c"
        case pricebookId = "SBQQ__PricebookId__c"
        case pricebook = "SBQQ__Pricebook__c"
        case status = "SBQQ__Status__c"
        case key = "SBQQ__Key__c"
        case primaryQuote = "SBQQ__Primary__c"
        case lineItemsGrouped = "SBQQ__LineItemsGrouped__c"
        case netAmount = "SBQQ__NetAmount__c"
        
        static let allFields = [createdById.rawValue, quoteId.rawValue, quoteNumber.rawValue, ownerId.rawValue, account.rawValue, opportunity.rawValue, pricebookId.rawValue, pricebook.rawValue, status.rawValue, key.rawValue, primaryQuote.rawValue, lineItemsGrouped.rawValue, netAmount.rawValue]
    }
    
    public var ownerId: String? {
        get {return  self.data[Field.ownerId.rawValue] as? String}
        set { self.data[Field.ownerId.rawValue] = newValue }
    }
    public var opportunity: String? {
        get {return self.data[Field.opportunity.rawValue] as? String}
        set { self.data[Field.opportunity.rawValue] = newValue }
    }
    public var quoteId: String? {
        get {return self.data[Field.quoteId.rawValue] as? String}
        set { self.data[Field.quoteId.rawValue] = newValue }
    }
    public var status: QuoteStage? {
        get {return QuoteStage(rawValue: (self.data[Field.status.rawValue] as? String)!)}
        set { self.data[Field.status.rawValue] = newValue?.rawValue }
    }
    public var pricebookId: String? {
        get {return self.data[Field.pricebookId.rawValue] as? String}
        set { self.data[Field.pricebookId.rawValue] = newValue }
    }
    public var quoteNumber: String? {
        get {return self.data[Field.quoteNumber.rawValue] as? String}
        set { self.data[Field.quoteNumber.rawValue] = newValue }
    }
    public var account: String? {
        get {return self.data[Field.account.rawValue] as? String}
        set { self.data[Field.account.rawValue] = newValue }
    }
    public var createdById: String? {
        get {return self.data[Field.createdById.rawValue] as? String}
        set { self.data[Field.createdById.rawValue] = newValue }
    }
    public var key: String? {
        get {return self.data[Field.key.rawValue] as? String}
        set { self.data[Field.key.rawValue] = newValue }
    }
    public var primaryQuote: Bool? {
        get {return self.data[Field.primaryQuote.rawValue] as? Bool}
        set { self.data[Field.primaryQuote.rawValue] = newValue }
    }
    public var lineItemsGrouped: Bool? {
        get {return self.data[Field.lineItemsGrouped.rawValue] as? Bool}
        set { self.data[Field.lineItemsGrouped.rawValue] = newValue }
    }
    public var netAmount: Float? {
        get {return self.data[Field.netAmount.rawValue] as? Float}
        set { self.data[Field.netAmount.rawValue] = newValue }
    }
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.opportunity.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.ownerId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.pricebook.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.quoteNumber.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.account.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.key.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + [Field.ownerId.rawValue, Field.account.rawValue, Field.opportunity.rawValue, Field.pricebookId.rawValue, Field.status.rawValue, Field.primaryQuote.rawValue, Field.lineItemsGrouped.rawValue]
    }
    public override static var updateFields: [String] {
        return super.updateFields + Field.allFields
    }
    
    public static var orderPath: String = Field.key.rawValue
}
