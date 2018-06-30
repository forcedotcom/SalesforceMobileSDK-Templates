//
//  QuoteStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/21/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class QuoteStore: Store<Quote> {
    public static let instance = QuoteStore()
    
    public override func records() -> [Quote] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Quote.objectName, withOrderPath: Quote.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Quote.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return Quote.from(results)
    }
    
    public func create(_ quote:Quote, completion:SyncCompletion) {
        self.createEntry(entry: quote, completion: completion)
    }
    
    public func quoteFromId(_ quoteId:String) -> Quote? {
        let query = SFQuerySpec.newExactQuerySpec(Quote.objectName, withPath: Quote.Field.quoteId.rawValue, withMatchKey: quoteId, withOrderPath: Quote.orderPath, with: .descending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Quote.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        return Quote.from(results)
    }
    
    public func quotesFromOpportunityId(_ opportunityId:String) -> [Quote] {
        let query = SFQuerySpec.newExactQuerySpec(Quote.objectName, withPath: Quote.Field.opportunity.rawValue, withMatchKey: opportunityId, withOrderPath: Quote.orderPath, with: .descending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Quote.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return Quote.from(results)
    }
}
