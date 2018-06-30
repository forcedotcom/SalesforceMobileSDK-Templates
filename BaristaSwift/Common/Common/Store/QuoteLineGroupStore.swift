//
//  File.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/22/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class QuoteLineGroupStore: Store<QuoteLineGroup> {
    public static let instance = QuoteLineGroupStore()
    
    public override func records() -> [QuoteLineGroup] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(QuoteLineGroup.objectName, withOrderPath: QuoteLineGroup.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(QuoteLineGroup.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return QuoteLineGroup.from(results)
    }
    
    public func lineGroupsForQuote(_ quoteId:String) -> [QuoteLineGroup] {
        let query = SFQuerySpec.newExactQuerySpec(QuoteLineGroup.objectName, withPath: QuoteLineGroup.Field.quote.rawValue, withMatchKey: quoteId, withOrderPath: QuoteLineGroup.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(QuoteLineGroup.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return QuoteLineGroup.from(results)
    }
}
