//
//  OpportunityStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/22/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class OpportunityStore: Store<Opportunity> {
    public static let instance = OpportunityStore()
    
    public override func records() -> [Opportunity] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Opportunity.objectName, withOrderPath: Opportunity.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Opportunity.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return Opportunity.from(results)
    }
    
    public func opportunitiesForAccount(_ account:Account) -> [Opportunity] {
        guard let accountId = account.accountId else {return []}
        let query = SFQuerySpec.newExactQuerySpec(Opportunity.objectName, withPath: Opportunity.Field.accountName.rawValue, withMatchKey: accountId, withOrderPath: Opportunity.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Opportunity.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return Opportunity.from(results)
    }
    
    public func opportunitiesInProgressForAccount(_ account:Account) -> [Opportunity] {
        let accountOpportunities = self.opportunitiesForAccount(account)
        let inProgress = accountOpportunities.filter { (opportunity) -> Bool in
            return opportunity.stage == .prospecting
        }
        return inProgress
    }
    
    public func opportunitiesInReview() -> [Opportunity] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Opportunity.objectName, withOrderPath: Opportunity.orderPath, with: .ascending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Opportunity.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        
        let allRecords:[Opportunity] = Opportunity.from(results)
        let inReview = allRecords.filter({$0.stage == .negotiationReview})
        return inReview
    }
}
