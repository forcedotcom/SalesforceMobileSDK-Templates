/*
  OrderItem.swift
  Consumer

  Created by Nicholas McDonald on 2/9/18.

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

public class OrderItem: Record, StoreProtocol {
    public enum Field: String {
        case itemId = "Id"
        case orderId = "OrderId"
        case orderItemNumber = "OrderItemNumber"
        case quantity = "Quantity"
        case unitPrice = "UnitPrice"
        case pricebookEntry = "PricebookEntryId"
        case productId = "Product2Id"
        
        
        static let allFields = [itemId.rawValue, orderId.rawValue, orderItemNumber.rawValue, quantity.rawValue, unitPrice.rawValue, pricebookEntry.rawValue, productId.rawValue]
    }
    
    public fileprivate(set) lazy var itemId: String? = data[Field.itemId.rawValue] as? String
    public fileprivate(set) lazy var orderId: String? = data[Field.orderId.rawValue] as? String
    public fileprivate(set) lazy var orderItemNumber: String? = data[Field.orderItemNumber.rawValue] as? String
    public fileprivate(set) lazy var quantity: Int? = data[Field.quantity.rawValue] as? Int
    public fileprivate(set) lazy var unitPrice: Float? = data[Field.unitPrice.rawValue] as? Float
    public fileprivate(set) lazy var pricebookEntry: String? = data[Field.pricebookEntry.rawValue] as? String
    public fileprivate(set) lazy var productId: String? = data[Field.productId.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.itemId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.orderId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.orderItemNumber.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.quantity.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.unitPrice.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.pricebookEntry.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.productId.rawValue, "type" : kSoupIndexTypeString]
            
        ]
    }
    
    public static var objectName: String = "OrderItem"
    
    public static var orderPath: String = Field.itemId.rawValue
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
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
