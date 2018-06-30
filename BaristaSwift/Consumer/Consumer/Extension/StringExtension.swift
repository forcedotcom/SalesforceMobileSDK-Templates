//
//  StringExtension.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/12/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation

extension String {
    func stringByAddingPercentEncodingForURL() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return self.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
}
