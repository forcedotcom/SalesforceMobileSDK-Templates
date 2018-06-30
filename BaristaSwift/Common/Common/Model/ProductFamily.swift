//
//  ProductFamily.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/26/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation

public struct ProductFamily {
    public let familyName: String
    public let type: ProductionOptionType
    public var options: [ProductOption] = []
}
