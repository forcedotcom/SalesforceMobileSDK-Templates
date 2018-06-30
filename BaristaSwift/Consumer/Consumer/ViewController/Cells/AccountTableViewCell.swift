//
//  AccountTableViewCell.swift
//  Consumer
//
//  Created by Nicholas McDonald on 3/19/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit
import Common

class AccountTableViewCell: UITableViewCell {
    
    fileprivate var nameLabel = UILabel()
    
    var name:String? {
        didSet {
            self.nameLabel.text = name
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.white
        
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.font = Theme.appMediumFont(14.0)
        self.contentView.addSubview(self.nameLabel)
        
        self.nameLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant:20.0).isActive = true
        self.nameLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.nameLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
