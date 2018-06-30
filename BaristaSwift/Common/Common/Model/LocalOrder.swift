//
//  LocalOrder.swift
//  Common
//
//  Created by Nicholas McDonald on 3/19/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation

public struct LocalOrder {
    public let opportunity:Opportunity
    public let quote:Quote
    public let orderItems:[LocalProductItem]
}
