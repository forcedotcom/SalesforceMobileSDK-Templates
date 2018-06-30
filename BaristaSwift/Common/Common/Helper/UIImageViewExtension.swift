//
//  UIImageViewExtension.swift
//  Consumer
//
//  Created by David Vieser on 1/31/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import SalesforceSwiftSDK

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    public func loadImageUsingCache(withUrl urlString : String?) {
        self.image = ImageCache.fetchImageUsingCache(withUrl: urlString) { image in
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
        
    func tintImage(withColor color: UIColor) {
        if let originalImage = image {
            let templateImage = originalImage.withRenderingMode(.alwaysTemplate)
            image = templateImage
            tintColor = color
        }
    }
}
