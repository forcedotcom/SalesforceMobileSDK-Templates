//
//  Dictionary.swift
//  MobileSyncExplorerSwift
//
//  Created by keith siilats on 4/19/20.
//  Copyright © 2020 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
extension Dictionary {
    
    func nonNullObject(forKey key: Key) -> Any? {
        let result = self[key]
        if (result as? NSNull) == NSNull() {
            return nil
        }
        
        if (result is String) {
            let res = result as! String
            if ((res == "<nil>") || (res == "<null>")) {
                return nil
            }
        }
        return result
    }
    
}
