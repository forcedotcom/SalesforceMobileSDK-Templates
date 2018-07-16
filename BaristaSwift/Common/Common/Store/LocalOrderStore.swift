/*
  LocalOrderStore.swift
  Common

  Created by Nicholas McDonald on 3/19/18.

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
import SalesforceSDKCore
import SalesforceSwiftSDK
import SmartSync
import PromiseKit

public class LocalOrderStore {
    public static let instance = LocalOrderStore()
    
    public func currentOrders() -> [LocalOrder] {
        var orders:[LocalOrder] = []
        let opportunities = OpportunityStore.instance.opportunitiesInReview()
        for opty in opportunities {
            var orderItems:[LocalProductItem] = []
            guard let primary = opty.primaryQuote,
                let quote = QuoteStore.instance.quoteFromId(primary) else { continue }
            let lineGroups = QuoteLineGroupStore.instance.lineGroupsForQuote(primary)
            for line in lineGroups {
                guard let lineId = line.id else { continue }
                let lineItems = QuoteLineItemStore.instance.lineItemsForGroup(lineId)
                var productOptions:[LocalProductOption] = []
                guard let first = lineItems.first,
                    let firstProductId = first.product,
                    let mainProduct = ProductStore.instance.product(from: firstProductId) else { continue }
                
                for (index, value) in lineItems.enumerated() {
                    if index > 0 {
                        guard let optionId = value.product,
                            let quantity = value.quantity,
                            let option = ProductOptionStore.instance.optionFromOptionalSKU(optionId) else { continue }
                        let productOption = LocalProductOption(product: option, quantity: quantity)
                        productOptions.append(productOption)
                    }
                }
                productOptions = productOptions.sorted(by: { (firstOption, secondOption) -> Bool in
                    guard let first = firstOption.product.orderNumber, let second = secondOption.product.orderNumber else { return false }
                    return first < second
                })
                let product = LocalProductItem(product: mainProduct, options: productOptions, quantity: 1)
                orderItems.append(product)
            }
            let order = LocalOrder(opportunity: opty, quote: quote, orderItems: orderItems)
            orders.append(order)
        }
        return orders
    }
    
    public func completeOrder(_ order:LocalOrder) -> Promise<Void> {
        let opty = order.opportunity
        opty.stage = .closedWon
        let quote = order.quote
        quote.status = .accepted
        
        return QuoteStore.instance.updateEntry(entry: quote)
            .then { quote -> Promise<Opportunity> in
                return OpportunityStore.instance.updateEntry(entry: opty)
            }
            .then { opportunity in
                return Promise.value(())
            }
    }
    
    public func locallyCompleteOrder(_ order:LocalOrder) {
        let opty = order.opportunity
        opty.stage = .closedWon
        let quote = order.quote
        quote.status = .accepted
        
        _ = QuoteStore.instance.locallyUpdateEntry(entry: quote)
        _ = OpportunityStore.instance.locallyUpdateEntry(entry: opty)
    }
    
    public func syncDownOrders() -> Promise<Void> {
        let syncs : [Promise<Void>] = [
            UserStore.instance.syncDown(),
            ProductOptionStore.instance.syncDown(),
            QuoteStore.instance.syncDown(),
            QuoteLineItemStore.instance.syncDown(),
            QuoteLineGroupStore.instance.syncDown(),
            OpportunityStore.instance.syncDown()];
        
        return when(fulfilled:syncs)
    }
    
    public func syncUpDownOrders() -> Promise<Void> {
        return OpportunityStore.instance.syncUp()
            .then { QuoteStore.instance.syncUp() }
            .then { self.syncDownOrders() }
    }
    
}
