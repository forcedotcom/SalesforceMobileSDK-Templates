/*
  OrderStore.swift
  Consumer

  Created by Nicholas McDonald on 2/7/18.

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
import SalesforceMobileSDKPromises
import SmartStore
import SmartSync

public class OrderStore: Store<Order> {
    public static let instance = OrderStore()
    
    // get products from order soql
    // SELECT Id,name,(select Id, OrderId, OrderItemNumber, PricebookEntry.Product2.Name, PricebookEntry.Product2.id, Quantity, UnitPrice FROM OrderItems ) from order where id=\(orderId)
    
    public func records<T:Order>(for user:String) -> [T] {
        let query = QuerySpec.buildExactQuerySpec(soupName: Order.objectName, path: Order.Field.createdById.rawValue, matchKey: user, orderPath: Order.Field.orderId.rawValue, order: .descending, pageSize: 100)
        if let results = runQuery(query: query) {
            return T.from(results)
        }
        return []
    }
    
    public override func records() -> [Order] {
        let query: QuerySpec = QuerySpec.buildAllQuerySpec(soupName: Order.objectName, orderPath: Order.orderPath, order: .descending, pageSize: 100)
        if let results = runQuery(query: query) {
            return Order.from(results)
        }
        return []
    }
    
    public func pendingOrder() -> Order? {
        let query: QuerySpec = QuerySpec.buildAllQuerySpec(soupName: Order.objectName, orderPath: Order.orderPath, order: .descending, pageSize: 100)
        if let results = runQuery(query: query) {
            let records:[Order] = Order.from(results)
            let pending = records.filter({$0.orderStatus() == .pending})
            return pending.last
        }
        return nil
    }
    
    public func incompleteOrders() -> [Order] {
        let query: QuerySpec = QuerySpec.buildAllQuerySpec(soupName: Order.objectName, orderPath: Order.orderPath, order: .descending, pageSize: 100)
        if let results = runQuery(query: query) {
            let records:[Order] = Order.from(results)
            let incomplete = records.filter({$0.orderStatus() == .submitted})
            return incomplete
        }
        return []
    }
}
