//
//  ProductOptionStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/24/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class ProductOptionStore: Store<ProductOption> {
    public static let instance = ProductOptionStore()
    
    public override func records() -> [ProductOption] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(ProductOption.objectName, withOrderPath: ProductOption.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(ProductOption.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return ProductOption.from(results)
    }
    
    public func options(_ forProduct:Product) -> [ProductOption]? {
        guard let productID = forProduct.productId else {return nil}
        let query = SFQuerySpec.newExactQuerySpec(ProductOption.objectName, withPath: ProductOption.Field.configuredProduct.rawValue, withMatchKey: productID, withOrderPath: ProductOption.orderPath, with: .ascending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(ProductOption.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return ProductOption.from(results)
    }
    
    public func families(_ forProduct:Product) -> [ProductFamily]? {
        guard var options = self.options(forProduct) else {return nil}
        options = self.sortByOrderNumber(options)

        var familiesDict :[String:Array<ProductOption>] = [:]
        for option in options {
            guard let optionFamily = option.productFamily else { break }
            if let _ = familiesDict[optionFamily] {
                familiesDict[optionFamily]?.append(option)
            } else {
                familiesDict[optionFamily] = [option]
            }
        }
        var families: [ProductFamily] = familiesDict.flatMap { (optionFamily, optionsArray) in
            guard let first = optionsArray.first, let type = first.optionType else { return nil }
            let sortedOptions = self.sortByOrderNumber(optionsArray)
            return ProductFamily(familyName: optionFamily, type: type, options: sortedOptions)
        }
        families = self.sortByOrderNumber(families)
        return families
    }
    
    public func optionFromOptionalSKU(_ sku:String) -> ProductOption? {
        let query = SFQuerySpec.newExactQuerySpec(ProductOption.objectName, withPath: ProductOption.Field.optionSKU.rawValue, withMatchKey: sku, withOrderPath: ProductOption.orderPath, with: .descending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(ProductOption.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        return ProductOption.from(results)
    }
    
    fileprivate func sortByOrderNumber(_ options:[ProductOption]) -> [ProductOption] {
        let sorted = options.sorted(by: { (first, second) -> Bool in
            guard let firstOrder = first.orderNumber, let secondOrder = second.orderNumber else { return false }
            return firstOrder < secondOrder
        })
        return sorted
    }
    
    fileprivate func sortByOrderNumber(_ family:[ProductFamily]) -> [ProductFamily] {
        let sorted = family.sorted { (firstFamily, secondFamily) -> Bool in
            guard let first = firstFamily.options.first, let firstOrder = first.orderNumber, let second = secondFamily.options.first, let secondOrder = second.orderNumber else { return false}
            return firstOrder < secondOrder
        }
        return sorted
    }
}
