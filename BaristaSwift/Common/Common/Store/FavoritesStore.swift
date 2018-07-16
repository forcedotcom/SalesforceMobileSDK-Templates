/*
  FavoritesStore.swift
  Common

  Created by Nicholas McDonald on 3/18/18.

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

public class FavoritesStore: Store<UserFavorite> {
    public static let instance = FavoritesStore()
    
    public func myFavorites() -> [UserFavorite] {
        guard let account = AccountStore.instance.myAccount(), let accountId = account.accountId else { return [] }
        let query = SFQuerySpec.newExactQuerySpec(UserFavorite.objectName, withPath: UserFavorite.Field.accountId.rawValue, withMatchKey: accountId, withOrderPath: UserFavorite.orderPath, with: .descending, withPageSize: 50)

        if let results = runQuery(query: query) {
            return UserFavorite.from(results)
        }
        return []
    }
    
    public func addNewFavorite(_ forProduct:Product) -> Promise<UserFavorite> {
        guard let account = AccountStore.instance.myAccount(), let accountId = account.accountId else {
            return Promise(error: FavoritesErrors.noAccount)
        }
        let fav = UserFavorite()
        fav.productId = forProduct.id
        fav.accountId = accountId
        return self.createEntry(entry: fav)
    }
    
    enum FavoritesErrors : Error {
        case noAccount
    }
}
