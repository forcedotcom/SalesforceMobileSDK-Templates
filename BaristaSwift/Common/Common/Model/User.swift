/*
  User.swift
  Common

  Created by Nicholas McDonald on 3/23/18.

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

public class User: Record, StoreProtocol {
    public static let objectName: String = "User"
    
    public enum Field: String {
        case email = "Email"
        case firstName = "FirstName"
        case lastName = "LastName"
        case photoURL = "FullPhotoUrl"
        case isActive = "IsActive"
        case mobilePhone = "MobilePhone"
        case name = "Name"
        case phone = "Phone"
        case profileId = "ProfileId"
        case username = "username"
        case appPhoto = "App_Photo_URL__c"
        
        static let allFields = [email.rawValue, firstName.rawValue, lastName.rawValue, photoURL.rawValue, isActive.rawValue, mobilePhone.rawValue, name.rawValue, phone.rawValue, profileId.rawValue, username.rawValue, appPhoto.rawValue]
    }
    
    public fileprivate(set) lazy var email: String? = data[Field.email.rawValue] as? String
    public fileprivate(set) lazy var firstName: String? = data[Field.firstName.rawValue] as? String
    public fileprivate(set) lazy var lastName: String? = data[Field.lastName.rawValue] as? String
    public fileprivate(set) lazy var photoURL: String? = data[Field.photoURL.rawValue] as? String
    public fileprivate(set) lazy var isActive: Bool? = data[Field.isActive.rawValue] as? Bool
    public fileprivate(set) lazy var mobilePhone: String? = data[Field.mobilePhone.rawValue] as? String
    public fileprivate(set) lazy var name: String? = data[Field.name.rawValue] as? String
    public fileprivate(set) lazy var phone: String? = data[Field.phone.rawValue] as? String
    public fileprivate(set) lazy var profileId: String? = data[Field.profileId.rawValue] as? String
    public fileprivate(set) lazy var username: String? = data[Field.username.rawValue] as? String
    public fileprivate(set) lazy var appPhoto: String? = data[Field.appPhoto.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.profileId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.username.rawValue, "type" : kSoupIndexTypeString]
        ]
    }
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + Field.allFields
    }
    public override static var updateFields: [String] {
        return super.updateFields + [Field.email.rawValue, Field.firstName.rawValue, Field.lastName.rawValue, Field.photoURL.rawValue, Field.mobilePhone.rawValue]
    }
    
    public static var orderPath: String = Field.username.rawValue
}
