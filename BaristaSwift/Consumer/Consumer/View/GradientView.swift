//
//  GradientView.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/14/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open class var layerClass: AnyClass {
        return CAGradientLayer.classForCoder()
    }
}
