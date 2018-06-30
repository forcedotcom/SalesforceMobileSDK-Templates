//
//  UIViewExtension.swift
//  Provider
//
//  Created by Nicholas McDonald on 3/20/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

extension UIView {
    func round() {
        layer.cornerRadius = bounds.size.width / 2
    }
}
