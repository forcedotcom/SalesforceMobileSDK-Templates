//
//  CategoryStore.swift
//  Consumer
//
//  Created by David Vieser on 1/30/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

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
