//
//  ActivityIndicatorView.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/5/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class ActivityIndicatorView: UIView {
    
    fileprivate var indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.indicator)
        
        self.indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.25)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimating() {
        self.indicator.startAnimating()
    }
    
    func showIn(_ view:UIView) {
        view.addSubview(self)
        self.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
