/*
  UserFavorite.swift
  Common

  Created by Nicholas McDonald on 3/18/18.

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
