/*
  CategoryStore.swift
  Consumer

  Created by David Vieser on 1/30/18.

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

public class ProductStore: Store<Product> {
    public static let instance = ProductStore()
    
    public func records<T:Product>(for category: ProductCategory? = nil) -> [T] {
        if let category = category, let categoryId = category.id {
            let queryString = "SELECT \(Product.selectFieldsString()) FROM {\(ProductCategoryAssociation.objectName)}, {\(Product.objectName)} WHERE {\(ProductCategoryAssociation.objectName):\(ProductCategoryAssociation.Field.categoryId.rawValue)} = '\(categoryId)' AND {\(Product.objectName):\(Product.Field.id.rawValue)} = {\(ProductCategoryAssociation.objectName):\(ProductCategoryAssociation.Field.productId.rawValue)} ORDER BY {\(Product.objectName):\(Product.Field.name.rawValue)} ASC"
            
            let query:SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: 100)!
            var error: NSError? = nil
            let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
            guard error == nil else {
                SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch Products for Category failed: \(error!.localizedDescription)")
                return []
            }
            return Product.from(results)
        }
        return []
    }

    public func featuredProduct<T:Product>() -> T? {
        return featuredProducts(pageSize: 1).first
    }
    
    public func featuredProducts<T:Product>() -> [T] {
        return featuredProducts(pageSize: 100)
    }
    
    fileprivate func featuredProducts<T:Product>(pageSize: UInt) -> [T] {
        let queryString = "SELECT \(Product.selectFieldsString()) FROM {\(Product.objectName)} WHERE {\(Product.objectName):\(Product.Field.isFeaturedItem.rawValue)} = 1 ORDER BY {\(Product.objectName):\(Product.Field.featuredItemPriority.rawValue)} ASC"
        
        let query:SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryString, withPageSize: pageSize)!
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch Featured Product list failed: \(error!.localizedDescription)")
            return []
        }
        return T.from(results)
    }
    
    public func product<T:Product>(from productId:String) -> T? {
        let query = SFQuerySpec.newExactQuerySpec(Product.objectName,
                                                  withPath: Product.Field.productId.rawValue,
                                                  withMatchKey: productId,
                                                  withOrderPath: Product.Field.productId.rawValue,
                                                  with: .ascending,
                                                  withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch Product by product id failed: \(error!.localizedDescription)")
            return nil
        }
        return T.from(results)
    }

}