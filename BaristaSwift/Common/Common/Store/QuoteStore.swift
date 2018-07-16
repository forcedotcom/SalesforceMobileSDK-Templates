/*
  QuoteStore.swift
  Consumer

  Created by Nicholas McDonald on 2/21/18.

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
import PromiseKit

public class QuoteStore: Store<Quote> {
    public static let instance = QuoteStore()
    
    public override func records() -> [Quote] {
        let query: SFQuerySpec = SFQuerySpec.newAllQuerySpec(Quote.objectName, withOrderPath: Quote.orderPath, with: .descending, withPageSize: 100)
        if let results = runQuery(query: query) {
            return Quote.from(results)
        }
        return []
    }
    
    public func create(_ quote:Quote) -> Promise<Quote> {
        return self.createEntry(entry: quote)
    }
    
    public func quoteFromId(_ quoteId:String) -> Quote? {
        let query = SFQuerySpec.newExactQuerySpec(Quote.objectName, withPath: Quote.Field.quoteId.rawValue, withMatchKey: quoteId, withOrderPath: Quote.orderPath, with: .descending, withPageSize: 1)
        if let results = runQuery(query: query) {
            return Quote.from(results)
        }
        return nil
    }
    
    public func quotesFromOpportunityId(_ opportunityId:String) -> [Quote] {
        let query = SFQuerySpec.newExactQuerySpec(Quote.objectName, withPath: Quote.Field.opportunity.rawValue, withMatchKey: opportunityId, withOrderPath: Quote.orderPath, with: .descending, withPageSize: 1)
        if let results = runQuery(query: query) {
            return Quote.from(results)
        }
        return []
    }
}
