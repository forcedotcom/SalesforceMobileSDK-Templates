/*
  Order.swift
  Consumer

  Created by Nicholas McDonald on 2/7/18.

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
