//
//  CartItemCollectionViewCell.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/12/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class CartItemTableViewCell: UITableViewCell {
    
    fileprivate var itemNameLabel = UILabel()
    fileprivate var descriptionLabel1 = UILabel()
    fileprivate var priceLabel = UILabel()
    fileprivate var optionsLabels:[UILabel] = []
    fileprivate var optionContainer = UIStackView()
    
    var itemName:String? {
        didSet {
            self.itemNameLabel.text = itemName
        }
    }
    var price:String? {
        didSet {
            self.priceLabel.text = price
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(container)
        container.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        container.addSubview(self.itemNameLabel)
        container.addSubview(self.optionContainer)
        container.addSubview(self.priceLabel)
        
        self.itemNameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.optionContainer.translatesAutoresizingMaskIntoConstraints = false
        self.priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.optionContainer.alignment = .leading
        self.optionContainer.distribution = .fillEqually
        self.optionContainer.axis = .vertical
        
        self.itemNameLabel.font = Theme.appBoldFont(14.0)
        self.itemNameLabel.textColor = Theme.cartItemTextColor
        
        self.priceLabel.font = Theme.appMediumFont(12.0)
        self.priceLabel.textColor = Theme.cartItemTextColor
        
        self.itemNameLabel.leftAnchor.constraint(equalTo: container.leftAnchor, constant:20).isActive = true
        self.optionContainer.leftAnchor.constraint(equalTo: self.itemNameLabel.leftAnchor).isActive = true
        self.optionContainer.rightAnchor.constraint(equalTo: container.rightAnchor, constant:-20).isActive = true
        self.priceLabel.rightAnchor.constraint(equalTo: container.rightAnchor, constant:-20).isActive = true
        
        self.itemNameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant:20).isActive = true
        self.optionContainer.topAnchor.constraint(equalTo: self.itemNameLabel.bottomAnchor).isActive = true
        self.optionContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant:-20).isActive = true
        self.priceLabel.firstBaselineAnchor.constraint(equalTo: self.itemNameLabel.firstBaselineAnchor).isActive = true
        
    }
    
    func addOption(_ optionName:String) {
        let optionLabel = UILabel()
        optionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionLabel.font = Theme.appMediumFont(12.0)
        optionLabel.textColor = Theme.cartItemTextColor
        optionLabel.text = optionName
        self.optionsLabels.append(optionLabel)
        self.optionContainer.addArrangedSubview(optionLabel)
    }
    
    override func prepareForReuse() {
        self.itemName = ""
        for label in self.optionsLabels {
            label.removeFromSuperview()
        }
        self.optionsLabels.removeAll()
        self.price = ""
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
