//
//  CategoryCollectionViewCell.swift
//  Consumer
//
//  Created by David Vieser on 1/31/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class CategoryCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var categoryImageView: UIImageView!
    
    var categoryName: String? {
        didSet {
            categoryLabel.text = categoryName
        }
    }
    
    var categoryImageURL: String? {
        didSet {
            categoryImageView.loadImageUsingCache(withUrl: categoryImageURL)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.categoryLabel.font = Theme.appBoldFont(12.0)
        self.categoryLabel.textColor = Theme.menuTextColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
