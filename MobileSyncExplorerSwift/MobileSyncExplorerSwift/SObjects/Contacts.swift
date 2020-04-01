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

enum ContactConstants {
    static let kContactFirstNameField    = "FirstName"
    static let kContactLastNameField     = "LastName"
    static let kContactTitleField        = "Title"
    static let kContactMobilePhoneField  = "MobilePhone"
    static let kContactEmailField        = "Email"
    static let kContactDepartmentField   = "Department"
    static let kContactHomePhoneField    = "HomePhone"
}

class ContactSObjectData: SObjectData, Identifiable {
    var firstName: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactFirstNameField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactFirstNameField, fieldValue: newValue)
        }
    }
    
    var lastName: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactLastNameField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactLastNameField, fieldValue: newValue)
        }
    }
    
    var title: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactTitleField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactTitleField, fieldValue: newValue)
        }
    }
    
    var mobilePhone: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactMobilePhoneField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactMobilePhoneField, fieldValue: newValue)
        }
    }
    
    var email: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactEmailField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactEmailField, fieldValue: newValue)
        }
    }
    
    var department: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactDepartmentField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactDepartmentField, fieldValue: newValue)
        }
    }
    
    var homePhone: String? {
        get {
            return super.nonNullFieldValue(ContactConstants.kContactHomePhoneField) as? String
        }
        set {
            super.updateSoup(forFieldName: ContactConstants.kContactHomePhoneField, fieldValue: newValue)
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
    
    override init(soupDict: [String: Any]?) {
        super.init(soupDict: soupDict)
    }
    
    override init() {
        super.init()
    }
    
    override class func dataSpec() -> SObjectDataSpec? {
        var sDataSpec: ContactSObjectDataSpec? = nil
        if sDataSpec == nil {
            sDataSpec = ContactSObjectDataSpec()
        }
        return sDataSpec
    }
}

class ContactSObjectDataSpec: SObjectDataSpec {
    
    convenience init() {
        let objectType = "Contact"
        let objectFieldSpecs = [
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactFirstNameField, searchable: true),
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactLastNameField, searchable: true),
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactTitleField, searchable: true),
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactMobilePhoneField, searchable: false),
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactEmailField, searchable: false),
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactDepartmentField, searchable: false),
            SObjectDataFieldSpec(fieldName: ContactConstants.kContactHomePhoneField, searchable: false)
        ]
        let soupName = "contacts"
        let orderByFieldName: String  = ContactConstants.kContactLastNameField
        self.init(objectType: objectType, objectFieldSpecs: objectFieldSpecs, soupName: soupName, orderByFieldName: orderByFieldName)
    }
    
    override class func createSObjectData(_ soupDict: [String : Any]?) throws -> SObjectData? {
        return ContactSObjectData(soupDict: soupDict)
    }
}
