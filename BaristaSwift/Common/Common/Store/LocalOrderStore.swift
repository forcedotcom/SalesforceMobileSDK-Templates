//
//  LocalOrderStore.swift
//  Common
//
//  Created by Nicholas McDonald on 3/19/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSDKCore
import SalesforceSwiftSDK
import SmartSync

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
    
    public func completeOrder(_ order:LocalOrder, completion:@escaping (Bool) -> Void) {
        let opty = order.opportunity
        opty.stage = .closedWon
        let quote = order.quote
        quote.status = .accepted
        
        QuoteStore.instance.updateEntry(entry: quote) { (quoteSync) in
            guard let quoteState = quoteSync else { return }
            if quoteState.isDone() {
                NSLog("update quote completed")
                OpportunityStore.instance.updateEntry(entry: opty, completion: { (optSync) in
                    guard let optyState = optSync else { return }
                    if optyState.isDone() {
                        NSLog("update opty completed")
                        completion(true)
                    } else if optyState.hasFailed() {
                        NSLog("Failed syncing opportunity update")
                        completion(false)
                    }
                })
            } else if quoteState.hasFailed() {
                NSLog("Failed syncing quote update")
                completion(false)
            }
        }
    }
    
    public func locallyCompleteOrder(_ order:LocalOrder) {
        let opty = order.opportunity
        opty.stage = .closedWon
        let quote = order.quote
        quote.status = .accepted
        
        QuoteStore.instance.locallyUpdateEntry(entry: quote)
        OpportunityStore.instance.locallyUpdateEntry(entry: opty)
    }
    
    public func syncDownOrders(completion:@escaping () -> Void) {
        let storeCount = 6
        var syncedCount = 0
        let syncCompletion:((SFSyncState?) -> Void) = { (syncState) in
            NSLog("sync completed \(syncedCount)")
            if let complete = syncState?.isDone(), complete == true {
                syncedCount = syncedCount + 1
            }
            
            DispatchQueue.main.async {
                if syncedCount == storeCount {
                    completion()
                }
            }
        }
        
        UserStore.instance.syncDown(completion: syncCompletion)
        ProductOptionStore.instance.syncDown(completion: syncCompletion)
        QuoteStore.instance.syncDown(completion: syncCompletion)
        QuoteLineItemStore.instance.syncDown(completion: syncCompletion)
        QuoteLineGroupStore.instance.syncDown(completion: syncCompletion)
        OpportunityStore.instance.syncDown(completion: syncCompletion)
    }
    
    public func syncUpDownOrders(completion:@escaping () -> Void) {
        let storeCount = 2
        var syncedCount = 0
        let syncUpCompletion:((SFSyncState?) -> Void) = { (syncState) in
            if let complete = syncState?.isDone(), complete == true {
                syncedCount = syncedCount + 1
            }
            NSLog("sync completed \(syncedCount)")
            if syncedCount == storeCount {
                NSLog("sync up completed")
                self.syncDownOrders(completion: completion)
            }
        }
        OpportunityStore.instance.syncUp(completion: syncUpCompletion)
        QuoteStore.instance.syncUp(completion: syncUpCompletion)
    }
    
    public func fullSyncDown(completion:@escaping () -> Void) {
        let storeCount = 8
        var syncedCount = 0
        let syncCompletion:((SFSyncState?) -> Void) = { (syncState) in
            NSLog("sync completed \(syncedCount)")
            if let complete = syncState?.isDone(), complete == true {
                syncedCount = syncedCount + 1
            }
            
            DispatchQueue.main.async {
                if syncedCount == storeCount {
                    completion()
                }
            }
        }
        
        UserStore.instance.syncDown(completion: syncCompletion)
        AccountStore.instance.syncDown(completion: syncCompletion)
        ProductStore.instance.syncDown(completion: syncCompletion)
        ProductOptionStore.instance.syncDown(completion: syncCompletion)
        QuoteStore.instance.syncDown(completion: syncCompletion)
        QuoteLineItemStore.instance.syncDown(completion: syncCompletion)
        QuoteLineGroupStore.instance.syncDown(completion: syncCompletion)
        OpportunityStore.instance.syncDown(completion: syncCompletion)
        PricebookStore.instance.syncDown(completion: syncCompletion)
    }
}
