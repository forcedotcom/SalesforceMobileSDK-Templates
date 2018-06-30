//
//  Product.swift
//  Consumer
//
//  Created by David Vieser on 1/30/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class Product: Record, StoreProtocol {
    public static let objectName: String = "Product2"
    
    public enum Field: String {
        case productId = "Id"
        case name = "Name"
        case featuredImageLeftURL = "FeaturedImageLeftURL__c"
        case featuredImageRightURL = "FeaturedImageRightURL__c"
        case iconImageURL = "IconImageURL__c"
        case isFeaturedItem = "FeaturedItem__c"
        case productDescription = "Description"
        case featuredItemPriority = "FeaturedItemPriority__c"
        
        static let allFields = [productId.rawValue, name.rawValue, featuredImageLeftURL.rawValue, featuredImageRightURL.rawValue, iconImageURL.rawValue, isFeaturedItem.rawValue, productDescription.rawValue, featuredItemPriority.rawValue]
    }

    public fileprivate(set) lazy var productId: String? = data[Field.productId.rawValue] as? String
    public fileprivate(set) lazy var name: String? = data[Field.name.rawValue] as? String
    public fileprivate(set) lazy var featuredImageLeftURL: String? = data[Field.featuredImageLeftURL.rawValue] as? String
    public fileprivate(set) lazy var featuredImageRightURL: String? = data[Field.featuredImageRightURL.rawValue] as? String
    public fileprivate(set) lazy var iconImageURL: String? = data[Field.iconImageURL.rawValue] as? String
    public fileprivate(set) lazy var isFeaturedItem: String? = data[Field.isFeaturedItem.rawValue] as? String
    public fileprivate(set) lazy var productDescription: String? = data[Field.productDescription.rawValue] as? String
    public fileprivate(set) lazy var featuredItemPriority: String? = data[Field.featuredItemPriority.rawValue] as? String

    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.productId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.featuredImageLeftURL.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.featuredImageRightURL.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.iconImageURL.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.isFeaturedItem.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.featuredItemPriority.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.productDescription.rawValue, "type" : kSoupIndexTypeString],
        ]
    }
    
    public override static var readFields: [String] {
        return super.readFields + Field.allFields
    }
    public override static var createFields: [String] {
        return super.createFields + Field.allFields
    }
    public override static var updateFields: [String] {
        return super.updateFields + Field.allFields
    }
    
    public static var orderPath: String = Field.name.rawValue
}
