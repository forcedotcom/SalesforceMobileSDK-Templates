//
//  User.swift
//  Common
//
//  Created by Nicholas McDonald on 3/23/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation

//
//  Opportunity.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/22/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

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
