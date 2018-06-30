//
//  QuoteLineItemStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/22/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class QuoteLineItemStore: Store<QuoteLineItem> {
    public static let instance = QuoteLineItemStore()
    
    public override func records() -> [QuoteLineItem] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(QuoteLineItem.objectName, withOrderPath: QuoteLineItem.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(QuoteLineItem.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return QuoteLineItem.from(results)
    }
    
    public func lineItemsForGroup(_ lineGroupId:String) -> [QuoteLineItem] {
        let query = SFQuerySpec.newExactQuerySpec(QuoteLineItem.objectName, withPath: QuoteLineItem.Field.group.rawValue, withMatchKey: lineGroupId, withOrderPath: QuoteLineItem.Field.lineNumber.rawValue, with: .ascending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(QuoteLineItem.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return QuoteLineItem.from(results)
    }
    
    public func create(_ lineItem:QuoteLineItem, completion:SyncCompletion) {
        self.createEntry(entry: lineItem, completion: completion)
    }
}
