/*
  OpportunityStore.swift
  Consumer

  Created by Nicholas McDonald on 2/22/18.

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
