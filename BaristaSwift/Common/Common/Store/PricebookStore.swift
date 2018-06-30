//
//  PricebookStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/3/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class PricebookStore: Store<Pricebook> {
    public static let instance = PricebookStore()
    
    public func freePricebook() -> Pricebook? {
        let query = SFQuerySpec.newExactQuerySpec(Pricebook.objectName, withPath: Pricebook.Field.name.rawValue, withMatchKey: "Free", withOrderPath: Pricebook.orderPath, with: .descending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Pricebook.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        return Pricebook.from(results)
    }
}
