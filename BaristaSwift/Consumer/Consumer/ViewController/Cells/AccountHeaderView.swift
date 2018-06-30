//
//  AccountHeaderView.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/19/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class AccountHeaderView: UIView {
    
    fileprivate var nameLabel = UILabel()
    var name:String? {
        didSet {
            self.nameLabel.text = name
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.font = Theme.appBoldFont(15.0)
        self.nameLabel.textColor = UIColor.black
        self.nameLabel.text = self.name
        self.addSubview(self.nameLabel)
        
        self.nameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant:20).isActive = true
        self.nameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant:-10).isActive = true
        
        let line = UIView()
        line.backgroundColor = UIColor(displayP3Red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)
        line.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(line)
        
        line.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        line.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        line.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        line.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
