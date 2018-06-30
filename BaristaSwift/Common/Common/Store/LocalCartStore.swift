//
//  LocalCartStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/27/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSDKCore
import SalesforceSwiftSDK
import SmartSync

public class LocalCartStore {
    public static let instance = LocalCartStore()
    
    fileprivate var inProgressItem:LocalProductItem?
    fileprivate var itemQueue:[LocalProductItem] = []
    fileprivate var syncingItem:LocalProductItem?
    
    public func cartCount() -> Int {
        if let account = AccountStore.instance.myAccount(),
            let opportunity = OpportunityStore.instance.opportunitiesInProgressForAccount(account).first,
            let primary = opportunity.primaryQuote {
            let lineGroups = QuoteLineGroupStore.instance.lineGroupsForQuote(primary)
            return lineGroups.count
        }
        return 0
    }
    
    public func currentCart() -> [LocalProductItem?] {
        // will only show commited cart items. In progress items should be ignored
        var cartItems:[LocalProductItem] = []
        if let account = AccountStore.instance.myAccount(),
            let opportunity = OpportunityStore.instance.opportunitiesInProgressForAccount(account).first,
            let primary = opportunity.primaryQuote {
            let lineGroups = QuoteLineGroupStore.instance.lineGroupsForQuote(primary)
            for group in lineGroups {
                guard let groupId = group.id ?? group.externalId else { continue }
                let items = QuoteLineItemStore.instance.lineItemsForGroup(groupId)
                var primaryItem:LocalProductItem?
                for (index, item) in items.enumerated() {
                    guard let quantity = item.quantity,
                        let productId = item.product else { continue }
                    if index == 0 {
                        guard let product = ProductStore.instance.product(from: productId) else { break }
                        primaryItem = LocalProductItem(product: product, options: [], quantity: quantity)
                    } else {
                        if let option = ProductOptionStore.instance.optionFromOptionalSKU(productId) {
                            let optionItem = LocalProductOption(product: option, quantity: quantity)
                            primaryItem?.options.append(optionItem)
                        }
                    }
                }
                if let item = primaryItem {
                    cartItems.append(item)
                }
            }
        }
        return cartItems
    }
    
    public func remove(_ item:LocalProductItem) {
        
    }
    
    public func beginConfiguring(_ item:LocalProductItem) {
        self.inProgressItem = item
    }
    
    public func updateInProgressItem(_ withOption:LocalProductOption) {
        // todo - update with rules from platform
        
        //rules
        // if integer type - update quantity
        // else if existing type, remove current, add new
        
        guard let optionType = withOption.product.optionType, let _ = self.inProgressItem else {return}
        if let index = self.inProgressItem!.options.index(where: { (cartOption) -> Bool in
            guard let optionFamily = withOption.product.productFamily else {return false}
            return cartOption.product.productFamily == optionFamily
        }) {
            // update value or remove existing based on type
            switch optionType {
            case .integer:
                if withOption.quantity > 0 {
                    print("updating quantity for: \(self.inProgressItem!.options[index].product.productName) to: \(withOption.quantity)")
                    self.inProgressItem!.options[index].quantity = withOption.quantity
                } else {
                    print("removing quantity for: \(self.inProgressItem!.options[index].product.productName)")
                    self.inProgressItem!.options.remove(at: index)
                }
            case .slider:
                print("removing added item: \(self.inProgressItem!.options[index].product.productName)")
                self.inProgressItem!.options.remove(at: index)
                
                print("adding new line item: \(withOption.product.productName) with quantity: \(withOption.quantity)")
                self.inProgressItem!.options.append(withOption)
            case .picklist, .multiselect:
                print("removing added item: \(self.inProgressItem!.options[index].product.productName)")
                self.inProgressItem!.options.remove(at: index)
            }
        } else {
            // doesn't exist, add line item and set quantity
            print("adding new line item: \(withOption.product.productName) with quantity: \(withOption.quantity)")
            self.inProgressItem!.options.append(withOption)
        }
    }
    
    public func commitToCart(completion:@escaping (Bool) -> Void) {
        // todo - update with validation from platform
        guard let account = AccountStore.instance.myAccount(), let item = self.inProgressItem else {return}
        // rules
        // if no current opportunity, create new opportunity from logged in user
        // if no current quote, create new quote
        // create new quote line group for in progress cart item
        // assign quote number to line group
        // create new quote line for each product
        // assign quote line group to each quote line
        guard let pricebook = PricebookStore.instance.freePricebook() else {
            self.showError("Could not find pricebook")
            completion(false)
            return
        }
        self.getOrCreateNewOpportunity(forAccount: account, pricebook: pricebook) { (opportunity) in
            guard let opty = opportunity else {
                self.showError("Unable to create or retrieve Opportunity record")
                completion(false)
                return
            }
            self.getOrCreateNewQuote(forOpportunity: opty, withAccount: account, completion: { (quote) in
                guard let newQuote = quote else {
                    self.showError("Unable to create or retrieve Quote record")
                    completion(false)
                    return
                }
                self.createNewLineGroup(forQuote: newQuote, completion: { (quoteLineGroup) in
                    guard let group = quoteLineGroup else {
                        self.showError("Unable to create QuoteLineGroup record")
                        completion(false)
                        return
                    }
                    guard let productId = item.product.productId else {
                        self.showError("Product missing product ID")
                        completion(false)
                        return
                    }
                    let mainItem = QuoteLineItem(withLineGroup: group, forProduct: productId, quantity: item.quantity, lineNumber: 1)
                    QuoteLineItemStore.instance.upsertNewEntries(entry: mainItem)
                    for (index, option) in item.options.enumerated() {
                        guard let optionID = option.product.optionSKU else {
                            self.showError("Option missing product ID")
                            continue
                        }
                        let lineItem = QuoteLineItem(withLineGroup: group, forProduct: optionID, quantity: option.quantity, lineNumber: index + 2)
                        QuoteLineItemStore.instance.upsertNewEntries(entry: lineItem)
                    }
                    NSLog("syncing up quote lines")
                    completion(true)
                    self.beginCartSyncUp(quote: newQuote, completion: { (completed) in
                        NSLog("cart sync up completed")
                    })
                })
                
            })
        }
    }
    
    func beginCartSyncUp(quote:Quote, completion:@escaping (Bool) -> Void) {
        guard let quoteId = quote.id else {
            completion(false)
            return
        }
        let lineGroups = QuoteLineGroupStore.instance.lineGroupsForQuote(quoteId)
        
        QuoteLineGroupStore.instance.syncUpDown(completion: { (lineGroupState) in
            if let complete = lineGroupState?.isDone(), complete == true {
                NSLog("line group sync up down complete")
                for lineGroup in lineGroups {
                    guard let lineGroupExternalId = lineGroup.externalId,
                        let syncedLineGroup = QuoteLineGroupStore.instance.record(forExternalId: lineGroupExternalId),
                        let lineGroupId = syncedLineGroup.id else { continue }
                    let lineItems = QuoteLineItemStore.instance.lineItemsForGroup(lineGroupExternalId)
                    for line in lineItems {
                        line.group = lineGroupId
                        NSLog("updating line with line group id \(lineGroupId)")
                        QuoteLineItemStore.instance.locallyUpdateEntry(entry: line)
                    }
                }
                QuoteLineItemStore.instance.syncUpDown(completion: { (lineItemState) in
                    if let lineComplete = lineItemState?.isDone(), lineComplete == true {
                        NSLog("Line item store sync up down completed")
                        completion(true)
                    }
                })
            }
        })
    }
    
    public func submitOrder(completion:@escaping (Bool) -> Void) {
        NSLog("submitOrder")
        if let account = AccountStore.instance.myAccount(),
            let opportunity = OpportunityStore.instance.opportunitiesInProgressForAccount(account).first,
            let primary = opportunity.primaryQuote,
            let quote = QuoteStore.instance.quoteFromId(primary) {
            quote.status = .presented
            opportunity.stage = .negotiationReview
            self.beginCartSyncUp(quote: quote, completion: { (completed) in
                NSLog("submitOrder - update quote entry")
                QuoteStore.instance.updateEntry(entry: quote, completion: { (quoteSync) in
                    guard let quoteState = quoteSync else { return }
                    if quoteState.isDone() {
                        NSLog("submitOrder - quote sync completed")
                        OpportunityStore.instance.updateEntry(entry: opportunity, completion: { (optSync) in
                            guard let optyState = optSync else { return }
                            if optyState.isDone() {
                                NSLog("submitOrder - opportunity sync completed")
                                completion(true)
                            } else if optyState.hasFailed() {
                                self.showError("Failed syncing opportunity update")
                                completion(false)
                            }
                        })
                    } else if quoteState.hasFailed() {
                        self.showError("Failed syncing quote update")
                        completion(false)
                    }
                })
            })
        }
    }
    
    public func showError(_ reason:String) {
        // todo log to screen/file
        print("LocalCartStore error: \(reason)")
    }
}

extension LocalCartStore {
    fileprivate func getOrCreateNewOpportunity(forAccount account:Account, pricebook:Pricebook, completion:@escaping (Opportunity?) -> Void) {
        NSLog("getOrCreateNewOpportunity")
        let inProgress = OpportunityStore.instance.opportunitiesInProgressForAccount(account)
        if inProgress.count == 0 {
            let newOpty = Opportunity()
            newOpty.accountName = account.accountId
            newOpty.name = account.name
            newOpty.stage = .prospecting
            newOpty.closeDate = Date(timeIntervalSinceNow: 90001)
            newOpty.pricebookId = pricebook.pricebookId
            let optyId = newOpty.externalId
//            NSLog("creating new opportunity \(account.name)")
//            OpportunityStore.instance.upsertNewEntries(entry: newOpty)
//            completion(newOpty)
            OpportunityStore.instance.createEntry(entry: newOpty, completion: { (syncState) in
                if let complete = syncState?.isDone(), complete == true {
                    NSLog("create new opportunity - sync completed")
                    guard let synced = OpportunityStore.instance.record(forExternalId: optyId) else {
                        completion(nil)
                        return
                    }
                    completion(synced)
                }
            })
        } else {
            NSLog("returning existing opportunity")
            completion(inProgress.first!)
        }
    }
    
    fileprivate func getOrCreateNewQuote(forOpportunity opportunity:Opportunity, withAccount account:Account, completion:@escaping (Quote?) -> Void) {
        NSLog("getOrCreateNewQuote")
        // assign opportunity primary quote and sync up
        if let primary = opportunity.primaryQuote, let quote = QuoteStore.instance.quoteFromId(primary) {
            NSLog("returning exisitng quote")
            completion(quote)
        } else {
            let newQuote = Quote()
            newQuote.primaryQuote = true
            newQuote.opportunity = opportunity.id
            newQuote.account = account.accountId
            newQuote.pricebookId = opportunity.pricebookId
            newQuote.lineItemsGrouped = true
            newQuote.primaryQuote = true
            let newQuoteId = newQuote.externalId
            NSLog("creating new quote")
            QuoteStore.instance.create(newQuote, completion: { (syncState) in
                // Todo - need to handle sync failure properly
                if let complete = syncState?.isDone(), complete == true {
                    NSLog("create new quote - sync completed")
                    guard let synced = QuoteStore.instance.record(forExternalId: newQuoteId) else {
                        completion(nil)
                        return
                    }
                    opportunity.primaryQuote = synced.quoteId
                    OpportunityStore.instance.upsertEntries(record: opportunity)
                    OpportunityStore.instance.syncUp()
                    completion(synced)
                }
            })
        }
    }
    
    fileprivate func createNewLineGroup(forQuote quote:Quote, completion:@escaping (QuoteLineGroup?) -> Void) {
        NSLog("createNewLineGroup")
        let newLineGroup = QuoteLineGroup()
        newLineGroup.account = quote.account
        newLineGroup.groupName = self.inProgressItem?.product.name
        newLineGroup.quote = quote.id
        let lineGroupId = newLineGroup.externalId
        NSLog("creating new line group")
        QuoteLineGroupStore.instance.upsertNewEntries(entry: newLineGroup)
        completion(newLineGroup)
    }
}
