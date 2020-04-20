/*
 ViewController.swift
 MobileSyncExplorerSwift
 
 Created by Raj Rao on 05/16/18.
 
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
import MobileSync.SFMobileSyncConstants



class ContactRecord: SFRecord, Identifiable, StoreProtocol {
    public static var objectName: String  = "Contact"

    required init() {
        super.init()
        soupDict = [:]
        if let spec = ContactRecord.dataSpec() {
            self.objectName = spec.objectType
            self.initSoupValues(spec.fieldNames)
            updateSoup(forFieldName: "attributes", fieldValue: ["type": spec.objectType])
        }
    }

    class var allFields: [String] {
        if let spec = self.dataSpec() {
            return spec.fieldNames
        } else {
            return []
        }
    }
    public class var readFields: [String] {
        return SFField.allFields + [SFField.soupEntryId.rawValue] + allFields
    }
    public class var createFields: [String] {
        return SFField.allFields + allFields
    }
    public class var updateFields: [String] {
        return  allFields
    }
    public class var orderPath: String {
        return SFField.id.rawValue
    }
    
    //    static var orderPath: String = ""
    
    var firstName: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.firstName.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.firstName.rawValue, fieldValue: newValue)
        }
    }
    
    var lastName: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.lastName.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.lastName.rawValue, fieldValue: newValue)
        }
    }
    
    var title: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.title.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.title.rawValue, fieldValue: newValue)
        }
    }
    
    var mobilePhone: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.mobilePhone.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.mobilePhone.rawValue, fieldValue: newValue)
        }
    }
    
    var email: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.email.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.email.rawValue, fieldValue: newValue)
        }
    }
    
    var department: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.department.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.department.rawValue, fieldValue: newValue)
        }
    }
    
    var homePhone: String? {
        get {
            return super.nonNullFieldValue(CodingKeys.homePhone.rawValue) as? String
        }
        set {
            super.updateSoup(forFieldName: CodingKeys.homePhone.rawValue, fieldValue: newValue)
        }
    }
    
    var lastModifiedDate: String? {
        get {
            return super.nonNullFieldValue(kLastModifiedDate) as? String
        }
        set {
            super.updateSoup(forFieldName: kLastModifiedDate, fieldValue: newValue)
        }
    }
    enum CodingKeys: String, CodingKey, CaseIterable {
        case lastName     = "LastName"
        case firstName    = "FirstName"
        case title        = "Title"
        case mobilePhone  = "MobilePhone"
        case email        = "Email"
        case department   = "Department"
        case homePhone    = "HomePhone"
    }
    required init(soupDict: [String: Any]?) {
        super.init(soupDict: soupDict)
    }
    
    
    override class func dataSpec() -> SObjectDataSpec? {
        var columns: [String] { return CodingKeys.allCases.map { $0.rawValue } }
        return CodedSObjectDataSpec(allCases: columns, name: Self.objectName)
    }
}


