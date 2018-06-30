//
//  OrderStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/7/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class OrderStore: Store<Order> {
    public static let instance = OrderStore()
    
    // get products from order soql
    // SELECT Id,name,(select Id, OrderId, OrderItemNumber, PricebookEntry.Product2.Name, PricebookEntry.Product2.id, Quantity, UnitPrice FROM OrderItems ) from order where id=\(orderId)
    
    public func records<T:Order>(for user:String) -> [T] {
        let query = SFQuerySpec.newExactQuerySpec(Order.objectName, withPath: Order.Field.createdById.rawValue, withMatchKey: user, withOrderPath: Order.Field.orderId.rawValue, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = self.store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch Order list failed: \(error!.localizedDescription)")
            return []
        }
        return T.from(results)
    }
    
    public override func records() -> [Order] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Order.objectName, withOrderPath: Order.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Order.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return Order.from(results)
    }
    
    public func pendingOrder() -> Order? {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Order.objectName, withOrderPath: Order.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Order.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        let records:[Order] = Order.from(results)
        let pending = records.filter({$0.orderStatus() == .pending})
        return pending.last
    }
    
    public func incompleteOrders() -> [Order] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Order.objectName, withOrderPath: Order.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Order.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        let records:[Order] = Order.from(results)
        let incomplete = records.filter({$0.orderStatus() == .submitted})
        return incomplete
    }
}
