//
//  RecentContacts.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 2/1/22.
//  Copyright © 2022 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
import UIKit.UIApplication
import SalesforceSDKCore

#if canImport(WidgetKit)
import WidgetKit
#endif

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

    static func persistedContacts() -> [ContactSummary]? {
        guard let path = SFDirectoryManager.shared().directoryOfCurrentUser(forType: .libraryDirectory, components: [fileName]) else {
            return nil
        }
       
        let url = URL(fileURLWithPath: path)
        if let encryptedData = try? Data(contentsOf: url) {
            do {
                let encryptionKey = try KeyGenerator.encryptionKey(for: encryptionKeyLabel)
                let decryptedData = try Encryptor.decrypt(data: encryptedData, using: encryptionKey)
                let contacts = try JSONDecoder().decode([ContactSummary].self, from: decryptedData)
                return contacts
            } catch {
                SalesforceLogger.e(RecentContacts.self, message: "Error reading persisted contacts: \(error)")
            }
        }
        return nil
    }
    
    static func persistContacts(_ contacts: [ContactSummary]) {
        guard !contacts.isEmpty,
              let directory = SFDirectoryManager.shared().directoryOfCurrentUser(forType: .libraryDirectory, components: nil) else {
            return
        }
        
        do {
            try SFDirectoryManager.ensureDirectoryExists(directory)
            let url = URL(fileURLWithPath: directory).appendingPathComponent(fileName)
            let encodedData = try JSONEncoder().encode(contacts)
            let encryptionKey = try KeyGenerator.encryptionKey(for: encryptionKeyLabel)
            let encryptedData = try Encryptor.encrypt(data: encodedData, using: encryptionKey)
            try encryptedData.write(to: url)
            #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            SalesforceLogger.e(RecentContacts.self, message: "Error persisting contacts: \(error)")
        }
    }
}
