//
//  Product.swift
//  Consumer
//
//  Created by David Vieser on 1/30/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public class ProductCategoryAssociation: Record, StoreProtocol {
    public static let objectName: String = "ProductCategoryAssociation__c"
    
    public enum Field: String {
        case name = "Name"
        case categoryId = "Category__c"
        case productId = "Product__c"

        static let allFields = [name.rawValue, categoryId.rawValue, productId.rawValue]
    }
    
    public fileprivate(set) lazy var name: String? = data[Field.name.rawValue] as? String
    public fileprivate(set) lazy var catgoryId: String? = data[Field.categoryId.rawValue] as? String
    public fileprivate(set) lazy var productId: String? = data[Field.productId.rawValue] as? String

    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.name.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.categoryId.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.productId.rawValue, "type" : kSoupIndexTypeString],
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
