//
//  Order.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/7/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class Order: Record, StoreProtocol {
    
    public enum Field: String {
        case accountId = "AccountId"
        case accountNumber = "AccountNumber"
        case orderAmount = "TotalAmount"
        case orderName = "Name"
        case orderNumber = "OrderNumber"
        case orderOwner = "OwnerId"
        case status = "Status"
        case orderId = "Id"
        case createdById = "CreatedById"
        
        static let allFields = [accountId.rawValue, orderName.rawValue, orderNumber.rawValue, orderOwner.rawValue, status.rawValue, createdById.rawValue]
    }
    
    public enum OrderStatus {
        case unknown
        case pending
        case submitted
        case complete
    }
    
    public fileprivate(set) lazy var accountId: String? = data[Field.accountId.rawValue] as? String
    public fileprivate(set) lazy var accountNumber: String? = data[Field.accountNumber.rawValue] as? String
    public fileprivate(set) lazy var amount: Float? = data[Field.orderAmount.rawValue] as? Float
    public fileprivate(set) lazy var name: String? = data[Field.orderName.rawValue] as? String
    public fileprivate(set) lazy var number: Int? = data[Field.orderNumber.rawValue] as? Int
    public fileprivate(set) lazy var owner: String? = data[Field.orderOwner.rawValue] as? String
    public fileprivate(set) lazy var status: String? = data[Field.status.rawValue] as? String
    public fileprivate(set) lazy var orderId: String? = data[Field.orderId.rawValue] as? String
    public fileprivate(set) lazy var createdById: String? = data[Field.createdById.rawValue] as? String
    
    public func orderStatus() -> OrderStatus {
        if let s = self.status {
            if s == "Draft" { return OrderStatus.pending }
            else if s == "Activated" { return OrderStatus.submitted }
            else if s == "Completed" { return OrderStatus.complete }
            else { return OrderStatus.unknown }
        } else { return OrderStatus.unknown }
    }
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.accountId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.orderName.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.orderNumber.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.orderOwner.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.status.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public static var objectName: String = "Order"
    
    public static var orderPath: String = Field.orderNumber.rawValue
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields + [Field.status.rawValue]
    }
    public override static var createFields: [String] {
        return super.createFields + Field.allFields
    }
    public override static var updateFields: [String] {
        return super.updateFields + Field.allFields
    }
    
    public static func selectFieldsString() -> String {
        return Field.allFields.map { return "{\(objectName):\($0)}" }.joined(separator: ", ")
    }
}
