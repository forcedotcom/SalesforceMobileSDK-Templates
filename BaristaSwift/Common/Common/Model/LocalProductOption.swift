//
//  LocalCartOption.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/28/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation

public struct LocalProductOption {
    public let product:ProductOption
    public var quantity:Int
    
    public init(product:ProductOption, quantity:Int) {
        self.product = product
        self.quantity = quantity
    }
}
