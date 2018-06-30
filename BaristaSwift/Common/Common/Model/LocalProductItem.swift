//
//  LocalCartItem.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/27/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation

public struct LocalProductItem {
    public let product:Product
    public var options:[LocalProductOption]
    public var quantity:Int
    
    public init(product:Product, options:[LocalProductOption], quantity:Int) {
        self.product = product
        self.options = options
        self.quantity = quantity
    }
}
