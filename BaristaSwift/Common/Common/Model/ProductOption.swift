//
//  ProductOption.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/24/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SmartStore

public enum ProductionOptionType: String {
    case slider = "Slider"
    case picklist = "Picklist"
    case multiselect = "Multiselect"
    case integer = "Integer"
}

public class ProductOption: Record, StoreProtocol {
    public static let objectName: String = "SBQQ__ProductOption__c"
    
    public enum Field: String {
        case configuredProduct = "SBQQ__ConfiguredSKU__c"
        case maxQuantity = "SBQQ__MaxQuantity__c"
        case minQuantity = "SBQQ__MinQuantity__c"
        case optionName = "Name"
        case productDescription = "SBQQ__ProductDescription__c"
        case productName = "SBQQ__ProductName__c"
        case productFamily = "SBQQ__ProductFamily__c"
        case defaultQuantity = "SBQQ__Quantity__c"
        case quantityEditable = "SBQQ__QuantityEditable__c"
        case required = "SBQQ__Required__c"
        case type = "SBQQ__Type__c"
        case unitPrice = "SBQQ__UnitPrice__c"
        case optionType = "OptionType__c"
        case orderNumber = "SBQQ__Number__c"
        case selected = "SBQQ__Selected__c"
        case optionSKU = "SBQQ__OptionalSKU__c"
        
        static let allFields = [configuredProduct.rawValue, maxQuantity.rawValue, minQuantity.rawValue, optionName.rawValue, productDescription.rawValue, productName.rawValue, productFamily.rawValue, defaultQuantity.rawValue, quantityEditable.rawValue, required.rawValue, type.rawValue, unitPrice.rawValue, optionType.rawValue, orderNumber.rawValue, selected.rawValue, optionSKU.rawValue]
    }
    public fileprivate(set) lazy var configuredProduct: String? = data[Field.configuredProduct.rawValue] as? String
    public fileprivate(set) lazy var maxQuantity: Int? = data[Field.maxQuantity.rawValue] as? Int
    public fileprivate(set) lazy var minQuantity: Int? = data[Field.minQuantity.rawValue] as? Int
    public fileprivate(set) lazy var optionName: String? = data[Field.optionName.rawValue] as? String
    public fileprivate(set) lazy var productDescription: String? = data[Field.productDescription.rawValue] as? String
    public fileprivate(set) lazy var productName: String? = data[Field.productName.rawValue] as? String
    public fileprivate(set) lazy var productFamily: String? = data[Field.productFamily.rawValue] as? String
    public fileprivate(set) lazy var defaultQuantity: Int? = data[Field.defaultQuantity.rawValue] as? Int
    public fileprivate(set) lazy var quantityEditable: Bool? = data[Field.quantityEditable.rawValue] as? Bool
    public fileprivate(set) lazy var required: Bool? = data[Field.required.rawValue] as? Bool
    public fileprivate(set) lazy var type: String? = data[Field.type.rawValue] as? String
    public fileprivate(set) lazy var unitPrice: Float? = data[Field.unitPrice.rawValue] as? Float
    public fileprivate(set) lazy var optionType: ProductionOptionType? = ProductionOptionType(rawValue: data[Field.optionType.rawValue] as! String)
    public fileprivate(set) lazy var orderNumber: Int? = data[Field.orderNumber.rawValue] as? Int
    public fileprivate(set) lazy var selected: Bool? = data[Field.selected.rawValue] as? Bool
    public fileprivate(set) lazy var optionSKU: String? = data[Field.optionSKU.rawValue] as? String
    
    public override static var indexes: [[String : String]] {
        return super.indexes + [
            ["path" : Field.configuredProduct.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.optionName.rawValue, "type" : kSoupIndexTypeString],
            ["path" : Field.optionSKU.rawValue, "type" : kSoupIndexTypeString]
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
    
    public static var orderPath: String = Field.configuredProduct.rawValue
}
