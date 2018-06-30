//
//  ProductTableViewCell.swift
//  Consumer
//
//  Created by David Vieser on 2/5/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class ProductTableViewCell: BaseTableViewCell {
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    var price: String? {
        didSet {
            self.priceLabel.text = price
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.addButton.round()
        self.addButton.backgroundColor = Theme.appMainControlColor
        self.priceLabel.font = Theme.appMediumFont(12.0)
        self.priceLabel.textColor = Theme.categoryItemTextColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.priceLabel.text = ""
    }
}
