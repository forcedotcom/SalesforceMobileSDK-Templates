//
//  RecentContacts.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 2/1/22.
//  Copyright © 2022 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
import WidgetKit
import UIKit.UIApplication
import SalesforceSDKCore

struct Queue<Element: Codable> {
    var isEmpty: Bool {
        get {
            return array.isEmpty
        }
    }
    private let maxSize: Int
    private(set) var array = [Element]()
    
    init(contentsOf array: [Element]?, maxSize: Int) {
        self.maxSize = maxSize
        self.append(contentsOf: array)
    }

    mutating func append(_ item: Element) {
        array.insert(item, at: 0)
        if array.count > maxSize {
            array.removeLast()
        }
    }
    
    mutating func append(contentsOf otherArray: [Element]?) {
        guard let trimmedArray = otherArray?.prefix(maxSize) else {
            return
        }
        trimmedArray.reversed().forEach{ item in
            append(item)
        }
    }
}

struct ContactSummary: Codable, Hashable {
    let id: String
    let firstName: String?
    let lastName: String?
}

class RecentContacts {
    static let encryptionKeyLabel = "com.salesforce.mobilesyncexplorer.recentcontacts.encryptionkey"
    static let fileName = "recentContacts.json"
    static let groupIdentifier = "group.com.salesforce.mobilesyncexplorer"
    
    static func persistedContacts() -> [ContactSummary]? {
        let decoder = JSONDecoder()
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: RecentContacts.groupIdentifier)
        
        if let url = container?.appendingPathComponent(fileName), let encryptedData = try? Data(contentsOf: url) {
            do {
                let encryptionKey = try KeyGenerator.encryptionKey(for: encryptionKeyLabel)
                let decryptedData = try Encryptor.decrypt(data: encryptedData, using: encryptionKey)
                let contacts = try decoder.decode([ContactSummary].self, from: decryptedData)
                return contacts
            } catch {
                SalesforceLogger.e(RecentContacts.self, message: "Error reading persisted contacts: \(error)")
            }
        }
        return nil
    }
    
    static func persistContacts(_ contacts: [ContactSummary]) {
        guard !contacts.isEmpty, let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)?.appendingPathComponent(fileName) else {
            return
        }
    
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(contacts) {
            do {
                let encryptionKey = try KeyGenerator.encryptionKey(for: encryptionKeyLabel)
                let encryptedData = try Encryptor.encrypt(data: encodedData, using: encryptionKey)
                try encryptedData.write(to: url)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                SalesforceLogger.e(RecentContacts.self, message: "Error persisting contacts: \(error)")
            }
        }
    }
}
