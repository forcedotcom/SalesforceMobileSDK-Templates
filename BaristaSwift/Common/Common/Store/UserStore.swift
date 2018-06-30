//
//  UserStore.swift
//  Common
//
//  Created by Nicholas McDonald on 3/23/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class UserStore: Store<User> {
    public static let instance = UserStore()
    
    public func user(_ forUserId:String) -> User? {
        let query = SFQuerySpec.newExactQuerySpec(User.objectName, withPath: User.Field.id.rawValue, withMatchKey: forUserId, withOrderPath: User.orderPath, with: .ascending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Account.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        return User.from(results)
    }
}
