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
    
    init(maxSize: Int) {
        self.maxSize = maxSize
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

class RecentContacts {
    static let shared = RecentContacts()
    let encryptionKeyLabel = "com.salesforce.mobilesyncexplorer.recentcontacts.encryptionkey"
    let fileName = "recentContacts.json"
    let groupIdentifier = "group.com.salesforce.mobilesyncexplorer"
    private var contacts: Queue<ContactSummary>
    
    private init() {
        contacts = Queue(maxSize: 3)
        contacts.append(contentsOf: persistedContacts())
        NotificationCenter.default.addObserver(self, selector: #selector(persistContacts), name: UIScene.willDeactivateNotification, object: nil)
    }
   
    func addContact(_ contact: ContactSummary) {
        contacts.append(contact)
    }
    
    func persistedContacts() -> [ContactSummary]? {
        let decoder = JSONDecoder()
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
        
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
    
    @objc func persistContacts() {
        guard !contacts.isEmpty, let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)?.appendingPathComponent(fileName) else {
            return
        }
    
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(contacts.array) {
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

struct ContactSummary: Codable, Hashable {
    let id: String
    let firstName: String?
    let lastName: String?
}
