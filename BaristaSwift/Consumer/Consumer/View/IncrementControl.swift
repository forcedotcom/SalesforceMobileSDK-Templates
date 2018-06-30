//
//  IncrementControl.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/15/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class IncrementControl: ProductConfigControlBase {
    
    var controlColor: UIColor? {
        didSet {
            self.plusButton.backgroundColor = controlColor
            self.minusButton.backgroundColor = controlColor
        }
    }
    var plusImage: UIImage? {
        didSet {
            self.plusButton.image = plusImage?.withRenderingMode(.alwaysOriginal)
        }
    }
    var minusImage: UIImage? {
        didSet {
            self.minusButton.image = minusImage?.withRenderingMode(.alwaysOriginal)
        }
    }
    var textColor: UIColor? {
        didSet {
            self.valueLabel.textColor = textColor
        }
    }
    var labelFont: UIFont! {
        didSet {
            self.valueLabel.font = labelFont
        }
    }
    override var currentValue: Int {
        didSet {
            self.valueLabel.text = "\(self.currentValue)"
            self.updateControlLayout()
        }
    }
    
    fileprivate var container = UIView()
    fileprivate var plusButton = UIImageView()
    fileprivate var minusButton = UIImageView()
    fileprivate var valueLabel = UILabel()
    fileprivate var widthConstraint: NSLayoutConstraint!
    fileprivate var lastTouchPosition:CGPoint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.container.translatesAutoresizingMaskIntoConstraints = false
        self.container.isUserInteractionEnabled = false
        self.container.layer.cornerRadius = 16.0
        self.container.clipsToBounds = true
        self.addSubview(container)
        
        self.minusButton.translatesAutoresizingMaskIntoConstraints = false
        self.minusButton.isUserInteractionEnabled = false
        self.minusButton.contentMode = .left
        container.addSubview(self.minusButton)
        
        self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.valueLabel.isUserInteractionEnabled = false
        self.valueLabel.text = "\(self.currentValue)"
        container.addSubview(self.valueLabel)
        
        self.plusButton.translatesAutoresizingMaskIntoConstraints = false
        self.plusButton.isUserInteractionEnabled = false
        self.plusButton.contentMode = .right
        container.addSubview(self.plusButton)
        
        self.heightAnchor.constraint(equalToConstant: 32.0).isActive = true
        self.widthAnchor.constraint(equalToConstant: 110.0).isActive = true
        
        self.container.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.container.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.container.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.widthConstraint = self.container.widthAnchor.constraint(equalToConstant: 32.0)
        self.widthConstraint.isActive = true
        
        self.plusButton.rightAnchor.constraint(equalTo: self.container.rightAnchor).isActive = true
        self.plusButton.topAnchor.constraint(equalTo: self.container.topAnchor).isActive = true
        self.plusButton.bottomAnchor.constraint(equalTo: self.container.bottomAnchor).isActive = true
        
        self.minusButton.leftAnchor.constraint(equalTo: self.container.leftAnchor).isActive = true
        self.minusButton.topAnchor.constraint(equalTo: self.container.topAnchor).isActive = true
        self.minusButton.bottomAnchor.constraint(equalTo: self.container.bottomAnchor).isActive = true
        
        self.valueLabel.centerXAnchor.constraint(equalTo: self.container.centerXAnchor).isActive = true
        self.valueLabel.centerYAnchor.constraint(equalTo: self.container.centerYAnchor).isActive = true
        
        self.plusButton.widthAnchor.constraint(equalTo: self.plusButton.heightAnchor, multiplier: 1.1).isActive = true
        self.minusButton.widthAnchor.constraint(equalTo: self.plusButton.widthAnchor, multiplier: 1.0).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateControlLayout() {
        self.layoutIfNeeded()
        if self.currentValue == 0 {
            self.widthConstraint.constant = 32.0
        } else {
            self.widthConstraint.constant = 110.0
        }
        UIView.animate(withDuration: 0.2) {
            super.layoutIfNeeded()
            self.layoutIfNeeded()
        }
    }
    
    func updateDisplayLabel() {
        self.valueLabel.text = "\(self.currentValue)"
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        self.lastTouchPosition = touchPoint
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        self.lastTouchPosition = touchPoint
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard let last = self.lastTouchPosition else {return}
        var newValue = 0
        let plusRect = self.plusButton.superview!.convert(self.plusButton.frame, to: self)
        let minusRect = self.minusButton.superview!.convert(self.minusButton.frame, to: self)
        if self.currentValue == 0 && plusRect.contains(last) {
            newValue = 1
        } else if self.currentValue > 0 {
            
            if plusRect.contains(last) {
                newValue = self.currentValue + 1
            } else if minusRect.contains(last) {
                newValue = self.currentValue - 1
            }
        }
        var shouldUpdateLayout = false
        if newValue != self.currentValue && (newValue == 0 || (newValue > 0 && self.currentValue == 0)) {
            shouldUpdateLayout = true
        }
        if newValue >= 0 && newValue <= self.maxValue {
            self.currentValue = newValue
        }
        if shouldUpdateLayout {
            self.updateControlLayout()
        }
        self.updateDisplayLabel()
        self.sendActions(for: .valueChanged)
    }
}
