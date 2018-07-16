/*
  LocalCartStore.swift
  Consumer

  Created by Nicholas McDonald on 2/27/18.

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
                    print("updating quantity for: \(String(describing: self.inProgressItem!.options[index].product.productName)) to: \(withOption.quantity)")
                    self.inProgressItem!.options[index].quantity = withOption.quantity
                } else {
                    print("removing quantity for: \(String(describing: self.inProgressItem!.options[index].product.productName))")
                    self.inProgressItem!.options.remove(at: index)
                }
            case .slider:
                print("removing added item: \(String(describing: self.inProgressItem!.options[index].product.productName))")
                self.inProgressItem!.options.remove(at: index)
                
                print("adding new line item: \(String(describing: withOption.product.productName)) with quantity: \(withOption.quantity)")
                self.inProgressItem!.options.append(withOption)
            case .picklist, .multiselect:
                print("removing added item: \(String(describing: self.inProgressItem!.options[index].product.productName))")
                self.inProgressItem!.options.remove(at: index)
            }
        } else {
            // doesn't exist, add line item and set quantity
            print("adding new line item: \(String(describing: withOption.product.productName)) with quantity: \(withOption.quantity)")
            self.inProgressItem!.options.append(withOption)
        }
    }
    
    public func commitToCart() -> Promise<Void> {
        // todo - update with validation from platform
        guard let account = AccountStore.instance.myAccount(), let item = self.inProgressItem else {
            return Promise(error:CartErrors.noInProgressItem)
        }
        // rules
        // if no current opportunity, create new opportunity from logged in user
        // if no current quote, create new quote
        // create new quote line group for in progress cart item
        // assign quote number to line group
        // create new quote line for each product
        // assign quote line group to each quote line
        guard let pricebook = PricebookStore.instance.freePricebook() else {
            self.showError("Could not find pricebook")
            return Promise(error:CartErrors.noPriceBook)
        }
        return self.getOrCreateNewOpportunity(forAccount: account, pricebook: pricebook)
            .then{ opportunity in self.getOrCreateNewQuote(forOpportunity: opportunity, withAccount: account) }
            .then { quote -> Promise<Void>  in
                let group = self.createNewLineGroup(forQuote: quote)
                guard let productId = item.product.productId else {
                    self.showError("Product missing product ID")
                    return Promise(error:CartErrors.noProductID)
                }
                let mainItem = QuoteLineItem(withLineGroup: group, forProduct: productId, quantity: item.quantity, lineNumber: 1)
                _ = QuoteLineItemStore.instance.locallyCreateEntry(entry: mainItem)
                for (index, option) in item.options.enumerated() {
                    guard let optionID = option.product.optionSKU else {
                        self.showError("Option missing product ID")
                        continue
                    }
                    let lineItem = QuoteLineItem(withLineGroup: group, forProduct: optionID, quantity: option.quantity, lineNumber: index + 2)
                    _ = QuoteLineItemStore.instance.locallyCreateEntry(entry: lineItem)
                }
                SalesforceSwiftLogger.log(type(of:self), level:.info, message:"syncing up quote lines")
                return self.beginCartSyncUp(quote: quote)
            }
    }
    
    func beginCartSyncUp(quote:Quote) -> Promise<Void> {
        guard let quoteId = quote.id else {
            return Promise(error:CartErrors.noQuote)
        }
        let lineGroups = QuoteLineGroupStore.instance.lineGroupsForQuote(quoteId)
        
        return QuoteLineGroupStore.instance.syncUpDown()
            .then { _ -> Promise<Void> in
                for lineGroup in lineGroups {
                    guard let lineGroupExternalId = lineGroup.externalId,
                        let syncedLineGroup = QuoteLineGroupStore.instance.record(forExternalId: lineGroupExternalId),
                        let lineGroupId = syncedLineGroup.id else { continue }
                    let lineItems = QuoteLineItemStore.instance.lineItemsForGroup(lineGroupExternalId)
                    for line in lineItems {
                        line.group = lineGroupId
                        SalesforceSwiftLogger.log(type(of:self), level:.info, message:"updating line with line group id \(lineGroupId)")
                        _ = QuoteLineItemStore.instance.locallyUpdateEntry(entry: line)
                    }
                }
                return QuoteLineItemStore.instance.syncUpDown()
            }
    }
    
    public func submitOrder() -> Promise<Void> {
        SalesforceSwiftLogger.log(type(of:self), level:.info, message:"submitOrder")
        if let account = AccountStore.instance.myAccount(),
            let opportunity = OpportunityStore.instance.opportunitiesInProgressForAccount(account).first,
            let primary = opportunity.primaryQuote,
            let quote = QuoteStore.instance.quoteFromId(primary) {
            quote.status = .presented
            opportunity.stage = .negotiationReview
            return self.beginCartSyncUp(quote: quote)
                .then { _ -> Promise<Quote> in
                    SalesforceSwiftLogger.log(type(of:self), level:.info, message:"submitOrder - update quote entry")
                    return QuoteStore.instance.updateEntry(entry: quote)
                }
                .then { syncedQuote -> Promise<Opportunity> in
                    SalesforceSwiftLogger.log(type(of:self), level:.info, message:"submitOrder - quote sync completed")
                    return OpportunityStore.instance.updateEntry(entry: opportunity)
                }
                .then { _ -> Promise<Void> in
                    return Promise.value(())
                }
        } else {
            return Promise(error:CartErrors.submitOrderFailed)
        }
    }
    
    public func showError(_ reason:String) {
        // todo log to screen/file
        print("LocalCartStore error: \(reason)")
    }

    enum CartErrors : Error {
        case noInProgressItem
        case noOpportunity
        case noPriceBook
        case noProductID
        case noQuote
        case noQuoteLineGroup
        case submitOrderFailed
    }
}

extension LocalCartStore {
    fileprivate func getOrCreateNewOpportunity(forAccount account:Account, pricebook:Pricebook) -> Promise<Opportunity> {
        SalesforceSwiftLogger.log(type(of:self), level:.info, message:"getOrCreateNewOpportunity")
        let opptyInProgress = OpportunityStore.instance.opportunitiesInProgressForAccount(account)
        if opptyInProgress.count == 0 {
            let newOpty = Opportunity()
            newOpty.accountName = account.accountId
            newOpty.name = account.name
            newOpty.stage = .prospecting
            newOpty.closeDate = Date(timeIntervalSinceNow: 90001)
            newOpty.pricebookId = pricebook.pricebookId
            SalesforceSwiftLogger.log(type(of:self), level:.info, message:"create new opportunity")
            return OpportunityStore.instance.createEntry(entry: newOpty)
        } else {
            SalesforceSwiftLogger.log(type(of:self), level:.info, message:"returning existing opportunity")
            return Promise.value(opptyInProgress.first!)
        }
    }
    
    fileprivate func getOrCreateNewQuote(forOpportunity opportunity:Opportunity, withAccount account:Account) -> Promise<Quote> {
        SalesforceSwiftLogger.log(type(of:self), level:.info, message:"getOrCreateNewQuote")
        // assign opportunity primary quote and sync up
        if let primary = opportunity.primaryQuote, let quote = QuoteStore.instance.quoteFromId(primary) {
            SalesforceSwiftLogger.log(type(of:self), level:.info, message:"returning exisitng quote")
            return Promise.value(quote)
        } else {
            var newQuote = Quote()
            newQuote.primaryQuote = true
            newQuote.opportunity = opportunity.id
            newQuote.account = account.accountId
            newQuote.pricebookId = opportunity.pricebookId
            newQuote.lineItemsGrouped = true
            newQuote.primaryQuote = true
            SalesforceSwiftLogger.log(type(of:self), level:.info, message:"creating new quote")
            return QuoteStore.instance.create(newQuote)
                .then { quote -> Promise<Opportunity> in
                    newQuote = quote
                    opportunity.primaryQuote = newQuote.quoteId
                    return OpportunityStore.instance.updateEntry(entry: opportunity)
                }
                .then { _ in return Promise.value(newQuote) }
        }
    }
    
    fileprivate func createNewLineGroup(forQuote quote:Quote) -> QuoteLineGroup {
        SalesforceSwiftLogger.log(type(of:self), level:.info, message:"createNewLineGroup")
        let newLineGroup = QuoteLineGroup()
        newLineGroup.account = quote.account
        newLineGroup.groupName = self.inProgressItem?.product.name
        newLineGroup.quote = quote.id
        SalesforceSwiftLogger.log(type(of:self), level:.info, message:"creating new line group")
        return QuoteLineGroupStore.instance.locallyCreateEntry(entry: newLineGroup)
    }
}
