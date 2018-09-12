/*
  OrderItemStore.swift
  Consumer

  Created by Nicholas McDonald on 2/9/18.

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
import PromiseKit

public class OrderItemStore: Store<OrderItem> {
    public static let instance = OrderItemStore()
    
    public func items(from order:Order) -> [OrderItem] {
        guard let orderId = order.orderId else { return [] }
        let query = QuerySpec.buildExactQuerySpec(soupName: OrderItem.objectName,
                                                  path: OrderItem.Field.orderId.rawValue,
                                                  matchKey: orderId,
                                                  orderPath: OrderItem.Field.itemId.rawValue,
                                                  order: .ascending,
                                                  pageSize: 100)
        if let results = runQuery(query: query) {
            return OrderItem.from(results)
        }
        return []
    }
    
    public override func records() -> [OrderItem] {
        let query: QuerySpec = QuerySpec.buildAllQuerySpec(soupName: OrderItem.objectName, orderPath: OrderItem.orderPath, order: .descending, pageSize: 100)
        if let results = runQuery(query: query) {
            return OrderItem.from(results)
        }
        return []
    }
}
