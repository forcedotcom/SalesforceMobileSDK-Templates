/*
  Account.swift
  Consumer

  Created by Nicholas McDonald on 3/1/18.

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
