//
//  CartHeaderView.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/12/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class CartHeaderView: UIView {
    
    fileprivate var locationImageView = UIImageView()
    var locationImage:UIImage? {
        didSet {
            self.locationImageView.image = locationImage
        }
    }
    fileprivate var pickupLabel = UILabel()
    fileprivate var locationLabel1 = UILabel()
    fileprivate var locationLabel2 = UILabel()
    fileprivate var locationLabel3 = UILabel()
    var location1:String? {
        didSet {
            self.locationLabel1.text = location1
        }
    }
    var location2:String? {
        didSet {
            self.locationLabel2.text = location2
        }
    }
    var location3:String? {
        didSet {
            self.locationLabel3.text = location3
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.pickupLabel.text = "Pickup Location"
        self.backgroundColor = UIColor.lightGray
        
        self.pickupLabel.font = Theme.appBoldFont(14.0)
        self.pickupLabel.textColor = Theme.cartItemTextColor
        self.locationLabel1.font = Theme.appMediumFont(12.0)
        self.locationLabel1.textColor = Theme.cartItemTextColor
        self.locationLabel2.font = Theme.appMediumFont(12.0)
        self.locationLabel2.textColor = Theme.cartItemTextColor
        self.locationLabel3.font = Theme.appMediumFont(12.0)
        self.locationLabel3.textColor = Theme.cartItemTextColor
        
        let labelContainer = UIView()
        self.addSubview(labelContainer)
        self.addSubview(self.locationImageView)
        labelContainer.addSubview(self.pickupLabel)
        labelContainer.addSubview(self.locationLabel1)
        labelContainer.addSubview(self.locationLabel2)
        labelContainer.addSubview(self.locationLabel3)
        
        self.locationImageView.backgroundColor = UIColor.gray
        
        self.locationImageView.translatesAutoresizingMaskIntoConstraints = false
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        self.pickupLabel.translatesAutoresizingMaskIntoConstraints = false
        self.locationLabel1.translatesAutoresizingMaskIntoConstraints = false
        self.locationLabel2.translatesAutoresizingMaskIntoConstraints = false
        self.locationLabel3.translatesAutoresizingMaskIntoConstraints = false
        
        self.locationImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant:20).isActive = true
        self.locationImageView.topAnchor.constraint(equalTo: self.topAnchor, constant:20).isActive = true
        self.locationImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant:-20).isActive = true
        self.locationImageView.widthAnchor.constraint(equalTo: self.locationImageView.heightAnchor, multiplier: 1.0).isActive = true
        
        self.pickupLabel.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        self.locationLabel1.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        self.locationLabel2.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        self.locationLabel3.leftAnchor.constraint(equalTo: labelContainer.leftAnchor).isActive = true
        self.pickupLabel.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true
        self.locationLabel1.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true
        self.locationLabel2.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true
        self.locationLabel3.rightAnchor.constraint(equalTo: labelContainer.rightAnchor).isActive = true
        self.pickupLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor).isActive = true
        self.locationLabel1.topAnchor.constraint(equalTo: self.pickupLabel.bottomAnchor).isActive = true
        self.locationLabel2.topAnchor.constraint(equalTo: self.locationLabel1.bottomAnchor).isActive = true
        self.locationLabel3.topAnchor.constraint(equalTo: self.locationLabel2.bottomAnchor).isActive = true
        self.locationLabel3.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor).isActive = true
        
        labelContainer.leftAnchor.constraint(equalTo: self.locationImageView.rightAnchor, constant:20).isActive = true
//        labelContainer.rightAnchor.constraint(equalTo: self.rightAnchor, constant:-20).isActive = true
        labelContainer.centerYAnchor.constraint(equalTo: self.locationImageView.centerYAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
