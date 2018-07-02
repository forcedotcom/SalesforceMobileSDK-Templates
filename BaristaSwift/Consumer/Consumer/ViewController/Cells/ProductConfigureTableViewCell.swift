/*
  ProductConfigureTableViewCell.swift
  Consumer

  Created by Nicholas McDonald on 2/13/18.

 Copyright (c) 2018-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import Common

enum ProductConfigureCellControlType {
    case unknown
    case slider
    case increment
    case list
}

class ProductConfigureTableViewCell: UITableViewCell {
    
    var controlClosure:((Int) -> Void)?
    var pickListClosure:((Int, String) -> Void)?
    
    var imageURL: String? {
        didSet {
            self.cellImageView.loadImageUsingCache(withUrl: imageURL)
        }
    }
    var name: String? {
        didSet {
            self.cellTitleLabel.text = name
        }
    }
    
    var minValue: Int? {
        didSet {
            if let control = self.configureControl as? IncrementControl, let new = minValue {
                control.minValue = new
            }
        }
    }
    
    var maxValue: Int? {
        didSet {
            if let control = self.configureControl as? IncrementControl, let new = maxValue {
                control.maxValue = new
            }
        }
    }
    
    var currentValue: Int? {
        didSet {
            if let control = self.configureControl as? IncrementControl, let new = currentValue {
                control.currentValue = new
            }
        }
    }
    
    var controlStyle:(ProductConfigureCellControlType) = (.unknown) {
        didSet {
            switch controlStyle {
            case .slider:
                let control = SliderControl()
                control.minTrackColor = Theme.appMainControlColor
                control.maxTrackColor = Theme.productConfigSliderMaxTrackColor
                control.thumbColor = Theme.appMainControlColor
                control.textColor = Theme.appMainControlTextColor
                if let max = self.maxValue {
                    control.maxValue = max
                }
                control.thumbLabels = self.sliderLabels
                control.addTarget(self, action: #selector(handleControlEventChange), for: .valueChanged)
                self.configureControl = control
            case .increment:
                let control = IncrementControl()
                control.controlColor = Theme.appMainControlColor
                control.plusImage = UIImage(named: "plus01")
                control.minusImage = UIImage(named: "minus01")
                control.textColor = Theme.appMainControlTextColor
                if let max = self.maxValue {
                    control.maxValue = max
                }
                if let min = self.minValue {
                    control.minValue = min
                }
                if let current = self.currentValue {
                    control.currentValue = current
                }
                control.addTarget(self, action: #selector(handleControlEventChange), for: .valueChanged)
                self.configureControl = control
            case .list:
                self.rightImageView.image = UIImage(named: "expand")
                return
            case .unknown:
                return
            }
        }
    }
    
    var listItems: [String] = [] {
        didSet {
            self.addListItems(listItems)
        }
    }
    
    var sliderLabels: [String] = [] {
        didSet {
            if let c = self.configureControl as? SliderControl {
                c.thumbLabels = sliderLabels
            }
        }
    }
    
    fileprivate var cellImageView = UIImageView()
    fileprivate var cellTitleLabel = UILabel()
    fileprivate var configureControl:UIControl? {
        didSet {
            guard let control = configureControl else {return}
            self.contentView.addSubview(control)
            control.translatesAutoresizingMaskIntoConstraints = false
            control.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant:-10).isActive = true
            control.centerYAnchor.constraint(equalTo: self.contentView.topAnchor, constant:34.0).isActive = true
        }
    }
    fileprivate var rightImageView = UIImageView()
    fileprivate var listContentView = UIView()
    fileprivate var listControlItems: [ListItemControl] = []
    fileprivate var listContentHeightConstraint: NSLayoutConstraint!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        
        self.cellImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.cellImageView)
        
        self.cellTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.cellTitleLabel)
        
        self.rightImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.rightImageView)
        
        self.listContentView.translatesAutoresizingMaskIntoConstraints = false
        self.listContentView.clipsToBounds = true
        self.contentView.addSubview(self.listContentView)
        
        self.cellTitleLabel.textColor = Theme.productConfigTextColor
        self.cellTitleLabel.font = Theme.appBoldFont(14.0)
        
        self.cellImageView.centerXAnchor.constraint(equalTo: self.contentView.leftAnchor, constant:30.0).isActive = true
        self.cellImageView.centerYAnchor.constraint(equalTo: self.contentView.topAnchor, constant:34.0).isActive = true
        
        self.cellTitleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant:70.0).isActive = true
        self.cellTitleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.cellTitleLabel.heightAnchor.constraint(equalToConstant: 68.0).isActive = true
        
        self.listContentView.topAnchor.constraint(equalTo: self.cellTitleLabel.bottomAnchor).isActive = true
        self.listContentView.leftAnchor.constraint(equalTo: self.cellTitleLabel.leftAnchor, constant:0.0).isActive = true

        self.listContentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.listContentHeightConstraint = self.listContentView.heightAnchor.constraint(equalToConstant: 0.0)
        self.listContentHeightConstraint.priority = .defaultHigh
        self.listContentHeightConstraint.isActive = true
        
        self.rightImageView.setContentHuggingPriority(.required, for: .horizontal)
        self.rightImageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant:-16.0).isActive = true
        self.rightImageView.centerYAnchor.constraint(equalTo: self.contentView.topAnchor, constant:34.0).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if let control = self.configureControl {
            control.removeTarget(nil, action: nil, for: .allEvents)
            control.removeFromSuperview()
        }
        for view in self.listContentView.subviews {
            view.removeFromSuperview()
        }
        self.configureControl = nil
        self.cellImageView.image = nil
        self.rightImageView.image = nil
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        var transform = CGAffineTransform.identity
        if self.listItems.count > 0 && self.listContentHeightConstraint.constant == 0.0 && selected == true {
            self.listContentHeightConstraint.constant = CGFloat((self.listItems.count * 42) + 10)
            transform = transform.rotated(by: .pi)
        } else {
            self.listContentHeightConstraint.constant = 0.0
        }
        UIView.animate(withDuration: 0.2) {
            self.rightImageView.transform = transform
        }
    }

    fileprivate func addListItems(_ items:[String]) {
        var lastControl: UIView?
        for (index, item) in items.enumerated() {
            let control = ListItemControl(frame: .zero)
            control.label = item
            control.controlIndex = index
            control.textColor = Theme.appMainControlTextColor
            control.labelFont = Theme.appBoldFont(13.0)
            control.controlColor = Theme.appMainControlColor
            control.addTarget(self, action: #selector(handleListControlPressed(control:)), for: .touchUpInside)
            self.listContentView.addSubview(control)
            if let last = lastControl {
                control.topAnchor.constraint(equalTo: last.bottomAnchor, constant:10.0).isActive = true
                control.leftAnchor.constraint(equalTo: last.leftAnchor).isActive = true
                control.rightAnchor.constraint(equalTo: last.rightAnchor).isActive = true
            } else {
                control.topAnchor.constraint(equalTo: self.listContentView.topAnchor).isActive = true
                control.leftAnchor.constraint(equalTo: self.listContentView.leftAnchor).isActive = true
                control.rightAnchor.constraint(equalTo: self.listContentView.rightAnchor).isActive = true
            }
            
            lastControl = control
        }
    }
    
    @objc func handleControlEventChange() {
        guard let control = self.configureControl as? ProductConfigControlBase else {return}
        let value = control.currentValue
        if let closure = self.controlClosure {
            closure(value)
        }
    }
    
    @objc func handleListControlPressed(control:ListItemControl) {
        guard let name = control.label else {return}
        if let closure = self.pickListClosure {
            closure(control.controlIndex, name)
        }
    }
}
