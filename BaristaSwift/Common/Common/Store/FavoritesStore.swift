//
//  FavoritesStore.swift
//  Common
//
//  Created by Nicholas McDonald on 3/18/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class FavoritesStore: Store<UserFavorite> {
    public static let instance = FavoritesStore()
    
    public func myFavorites() -> [UserFavorite] {
        guard let account = AccountStore.instance.myAccount(), let accountId = account.accountId else { return [] }
        let query = SFQuerySpec.newExactQuerySpec(UserFavorite.objectName, withPath: UserFavorite.Field.accountId.rawValue, withMatchKey: accountId, withOrderPath: UserFavorite.orderPath, with: .descending, withPageSize: 50)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(UserFavorite.objectName) failed: \(error!.localizedDescription)")
            return []
        }
        return UserFavorite.from(results)
    }
    
    public func addNewFavorite(_ forProduct:Product, completion:SyncCompletion) {
        guard let account = AccountStore.instance.myAccount(), let accountId = account.accountId else { return }
        let fav = UserFavorite()
        fav.productId = forProduct.id
        fav.accountId = accountId
        self.createEntry(entry: fav, completion: completion)
    }
}
