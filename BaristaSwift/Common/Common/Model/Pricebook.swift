/*
  Pricebook.swift
  Consumer

  Created by Nicholas McDonald on 3/3/18.

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

public class Pricebook: Record, StoreProtocol {
    
    public enum Field: String {
        case createdById = "CreatedById"
        case description = "Description"
        case pricebookId = "Id"
        case isActive = "IsActive"
        case isArchived = "IsArchived"
        case isDeleted = "IsDeleted"
        case isStandard = "IsStandard"
        case name = "Name"
        
        static let allFields = [createdById.rawValue, description.rawValue, pricebookId.rawValue, isActive.rawValue, isArchived.rawValue, isDeleted.rawValue, isStandard.rawValue, name.rawValue]
    }
    
    public fileprivate(set) lazy var createdById: String? = data[Field.createdById.rawValue] as? String
    public fileprivate(set) lazy var description: String? = data[Field.description.rawValue] as? String
    public fileprivate(set) lazy var pricebookId: String? = data[Field.pricebookId.rawValue] as? String
    public fileprivate(set) lazy var isActive: String? = data[Field.isActive.rawValue] as? String
    public fileprivate(set) lazy var isArchived: String? = data[Field.isArchived.rawValue] as? String
    public fileprivate(set) lazy var isDeleted: String? = data[Field.isDeleted.rawValue] as? String
    public fileprivate(set) lazy var isStandard: String? = data[Field.isStandard.rawValue] as? String
    public fileprivate(set) lazy var name: String? = data[Field.name.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.createdById.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.pricebookId.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public static var objectName: String = "Pricebook2"
    
    public static var orderPath: String = Field.pricebookId.rawValue
    
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
