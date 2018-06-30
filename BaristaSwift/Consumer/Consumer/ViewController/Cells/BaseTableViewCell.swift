//
//  BaseTableViewCell.swift
//  Consumer
//
//  Created by David Vieser on 2/7/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class BaseTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }
    
    var imageURL: String? {
        didSet {
            iconImageView.loadImageUsingCache(withUrl: imageURL)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = ""
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameLabel.font = Theme.appBoldFont(14.0)
        self.nameLabel.textColor = Theme.categoryItemTextColor
        self.iconImageView.round()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
