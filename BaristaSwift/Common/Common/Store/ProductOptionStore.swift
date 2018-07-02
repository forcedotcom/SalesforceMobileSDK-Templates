/*
  ProductOptionStore.swift
  Consumer

  Created by Nicholas McDonald on 2/24/18.

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
