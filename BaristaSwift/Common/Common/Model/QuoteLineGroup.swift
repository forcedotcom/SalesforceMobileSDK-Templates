/*
  QuoteLineGroup.swift
  Consumer

  Created by Nicholas McDonald on 2/22/18.

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
