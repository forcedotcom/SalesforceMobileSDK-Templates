//
//  UIButtonExtension.swift
//  Consumer
//
//  Created by David Vieser on 2/16/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

extension UIButton {
    func loadBackgroundImageUsingCache(withUrl urlString: String, for controlState: UIControlState) {
        let image = ImageCache.fetchImageUsingCache(withUrl: urlString) { image in
            DispatchQueue.main.async {
                self.setBackgroundImage(image, for: controlState)
            }
        }
        self.setImage(image, for: controlState)
    }
}
