//
//  AccountStore.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/1/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSwiftSDK
import SmartStore
import SmartSync

public class AccountStore: Store<Account> {
    public static let instance = AccountStore()
    
    public func myAccount() -> Account? {
        let identity = SFUserAccountManager.sharedInstance().currentUserIdentity
        guard let userId = identity?.userId else {return nil}
        return self.account(userId)
    }
    
    public func account(_ forUserId:String) -> Account? {
        // todo only sync down users record
        let query = SFQuerySpec.newAllQuerySpec(Account.objectName, withOrderPath: Account.orderPath, with: .descending, withPageSize: 100)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Account.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        let accounts: [Account] = Account.from(results)
        let filteredAccounts = accounts.filter { (account) -> Bool in
            guard let id = account.accountNumber else {return false}
            return id == forUserId
        }
        return filteredAccounts.first
        
    }
    
    public func account(forAccountId:String) -> Account? {
        let query = SFQuerySpec.newExactQuerySpec(Account.objectName, withPath: Account.Field.accountId.rawValue, withMatchKey: forAccountId, withOrderPath: Account.orderPath, with: .ascending, withPageSize: 1)
        var error: NSError? = nil
        let results: [Any] = store.query(with: query, pageIndex: 0, error: &error)
        guard error == nil else {
            SalesforceSwiftLogger.log(type(of:self), level:.error, message:"fetch \(Account.objectName) failed: \(error!.localizedDescription)")
            return nil
        }
        return Account.from(results)
    }
    
    public func create(_ account:Account, completion:SyncCompletion) {
        self.createEntry(entry: account, completion: completion)
    }
}
