//
//  OrderTableViewCell.swift
//  Provider
//
//  Created by Nicholas McDonald on 3/19/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class OrderTableViewCell: UITableViewCell {
    
    fileprivate var userImageView = UIImageView()
    fileprivate var itemImageViews:[UIImageView] = []
    fileprivate var itemNameLabels:[UILabel] = []
    fileprivate var optionsLabels:[UILabel] = []
    fileprivate var optionContainer = UIStackView()
    fileprivate var customerLabel = UILabel()
    fileprivate var timeLabel = UILabel()
    
    var customerName:String? {
        didSet {
            self.customerLabel.text = customerName
        }
    }
    
    var timeWaiting:String? {
        didSet {
            self.timeLabel.text = timeWaiting
        }
    }
    
    var profilePhoto:String? {
        didSet {
            DispatchQueue.global().async {
                if let profile = self.profilePhoto {
                    if let url = URL(string: profile),
                        let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            if profile == self.profilePhoto {
                                let image = UIImage(data: data)
                                self.userImageView.image = image
                                self.userImageView.round()
                            }
                        }
                    }
                }
                
            }
            
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        
        self.userImageView.translatesAutoresizingMaskIntoConstraints = false
        self.userImageView.clipsToBounds = true
        self.addSubview(self.userImageView)
        
        self.userImageView.heightAnchor.constraint(equalToConstant: 52).isActive = true
        self.userImageView.widthAnchor.constraint(equalTo: self.userImageView.heightAnchor, multiplier: 1.0).isActive = true
        self.userImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant:40).isActive = true
        self.userImageView.topAnchor.constraint(equalTo: self.topAnchor, constant:38).isActive = true
        
        self.customerLabel.translatesAutoresizingMaskIntoConstraints = false
        self.customerLabel.font = Theme.appMediumFont(14.0)
        self.addSubview(self.customerLabel)
        self.customerLabel.leftAnchor.constraint(equalTo: self.userImageView.rightAnchor, constant:20.0).isActive = true
        self.customerLabel.centerYAnchor.constraint(equalTo: self.userImageView.centerYAnchor).isActive = true
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(container)
        container.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        container.addSubview(self.optionContainer)
        
        self.optionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        self.optionContainer.alignment = .leading
        self.optionContainer.distribution = .fill
        self.optionContainer.spacing = 22.0
        self.optionContainer.axis = .vertical
        
        self.optionContainer.leftAnchor.constraint(equalTo: self.userImageView.rightAnchor, constant:173).isActive = true
        self.optionContainer.rightAnchor.constraint(equalTo: container.rightAnchor, constant:-173).isActive = true
        self.optionContainer.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        self.optionContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant:-20).isActive = true
        
        let clockImage = UIImageView(image: UIImage(named: "clock"))
        clockImage.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(clockImage)
        clockImage.leftAnchor.constraint(equalTo: self.rightAnchor, constant: -170).isActive = true
        clockImage.centerYAnchor.constraint(equalTo: self.userImageView.centerYAnchor).isActive = true
        
        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.timeLabel.font = Theme.appMediumFont(24.0)
        self.addSubview(self.timeLabel)
        self.timeLabel.centerYAnchor.constraint(equalTo: clockImage.centerYAnchor).isActive = true
        self.timeLabel.leftAnchor.constraint(equalTo: clockImage.rightAnchor, constant: 8).isActive = true
        
        self.layoutIfNeeded()
        self.userImageView.round()
        
        self.heightAnchor.constraint(greaterThanOrEqualToConstant: 120.0).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func add(product:Product, options:[LocalProductOption]) {
        if self.itemNameLabels.count == 0 && self.optionsLabels.count == 0 {
            let topSpacer = UIView()
            topSpacer.translatesAutoresizingMaskIntoConstraints = false
            topSpacer.heightAnchor.constraint(equalToConstant: 2.0).isActive = true
            self.optionContainer.addArrangedSubview(topSpacer)
        }
        
        let productContainer = UIStackView()
        productContainer.translatesAutoresizingMaskIntoConstraints = false
        productContainer.alignment = .leading
        productContainer.spacing = 30.0
        productContainer.distribution = .fill
        productContainer.axis = .horizontal
        
        let productImage = UIImageView()
        productImage.translatesAutoresizingMaskIntoConstraints = false
        productImage.loadImageUsingCache(withUrl: product.iconImageURL)
        productImage.widthAnchor.constraint(equalToConstant: 80).isActive = true
        productImage.heightAnchor.constraint(equalTo: productImage.widthAnchor, multiplier: 1.0).isActive = true
        productContainer.addArrangedSubview(productImage)
        self.itemImageViews.append(productImage)
        
        let labelContainer = UIStackView()
        labelContainer.translatesAutoresizingMaskIntoConstraints = false
        labelContainer.alignment = .leading
        labelContainer.distribution = .fill
        labelContainer.axis = .vertical
        
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        topSpacer.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        labelContainer.addArrangedSubview(topSpacer)
        
        let itemNameLabel = UILabel()
        itemNameLabel.translatesAutoresizingMaskIntoConstraints = false
        itemNameLabel.font = Theme.appBoldFont(24.0)
        itemNameLabel.textColor = Theme.cartItemTextColor
        itemNameLabel.text = product.name
        self.itemNameLabels.append(itemNameLabel)
        labelContainer.addArrangedSubview(itemNameLabel)
        
        for option in options {
            guard let type = option.product.optionType, let name = option.product.productDescription else { return }
            let optionLabel = UILabel()
            optionLabel.translatesAutoresizingMaskIntoConstraints = false
            optionLabel.font = Theme.appMediumFont(20.0)
            optionLabel.textColor = Theme.cartItemTextColor
            if type == .integer {
                optionLabel.text = "(\(option.quantity)) \(name)"
            } else {
                optionLabel.text = name
            }
            self.optionsLabels.append(optionLabel)
            labelContainer.addArrangedSubview(optionLabel)
        }
        productContainer.addArrangedSubview(labelContainer)
        self.optionContainer.addArrangedSubview(productContainer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.userImageView.image = nil
        self.customerLabel.text = ""
        self.timeLabel.text = ""
        for image in self.itemImageViews {
            image.removeFromSuperview()
        }
        for label in self.itemNameLabels {
            label.removeFromSuperview()
        }
        for label in self.optionsLabels {
            label.removeFromSuperview()
        }
        self.itemImageViews.removeAll()
        self.itemNameLabels.removeAll()
        self.optionsLabels.removeAll()
        for view in self.optionContainer.arrangedSubviews {
            self.optionContainer.removeArrangedSubview(view)
        }
    }

}
