//
//  ListItemControl.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/19/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class ListItemControl: ProductConfigControlBase {
    
    var controlColor: UIColor? {
        didSet {
            self.controlButton.layer.borderColor = controlColor?.cgColor
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
    var label: String? {
        didSet {
            self.valueLabel.text = label
        }
    }
    var controlIndex:Int = 0
    
    fileprivate var controlRing = UIView()
    fileprivate var controlButton = UIView()
    fileprivate var valueLabel = UILabel()
    fileprivate var lastTouchPosition:CGPoint?
    fileprivate var isButtonSelected = false
    fileprivate static let buttonSize: CGFloat = 32.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.controlRing.translatesAutoresizingMaskIntoConstraints = false
        self.controlRing.layer.cornerRadius = ListItemControl.buttonSize / 2.0
        self.controlRing.layer.borderWidth = 1.0
        self.controlRing.layer.borderColor = UIColor.white.cgColor
        self.controlRing.isUserInteractionEnabled = false
        self.addSubview(self.controlRing)
        
        self.controlButton.translatesAutoresizingMaskIntoConstraints = false
        self.controlButton.isUserInteractionEnabled = false
        self.controlButton.layer.cornerRadius = (ListItemControl.buttonSize - 8.0) / 2.0
        self.controlButton.layer.borderWidth = 0.0
        self.addSubview(self.controlButton)
        
        self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.valueLabel.isUserInteractionEnabled = false
        self.addSubview(self.valueLabel)
        
        self.heightAnchor.constraint(equalToConstant: ListItemControl.buttonSize).isActive = true
        
        self.controlButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant:4.0).isActive = true
        self.controlButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.controlButton.heightAnchor.constraint(equalTo: self.controlButton.widthAnchor).isActive = true
        self.controlButton.widthAnchor.constraint(equalToConstant: ListItemControl.buttonSize - 8.0).isActive = true
        
        self.controlRing.centerXAnchor.constraint(equalTo: self.controlButton.centerXAnchor).isActive = true
        self.controlRing.centerYAnchor.constraint(equalTo: self.controlButton.centerYAnchor).isActive = true
        self.controlRing.heightAnchor.constraint(equalToConstant: ListItemControl.buttonSize - 0.5).isActive = true
        self.controlRing.widthAnchor.constraint(equalToConstant: ListItemControl.buttonSize - 0.5).isActive = true
        
        self.valueLabel.leftAnchor.constraint(equalTo: self.controlButton.rightAnchor, constant:16.0).isActive = true
        self.valueLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.valueLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        if self.bounds.contains(last) {
            self.isButtonSelected = !self.isButtonSelected
        }
        var borderWidth = self.controlButton.layer.borderWidth
        var ringColor:UIColor? = UIColor.white
        var after:Double = 0.0
        if self.isButtonSelected {
            borderWidth = ListItemControl.buttonSize / 2.0
            ringColor = self.controlColor
        } else {
            after = 0.1
            borderWidth = 0.0
        }
        let anim = CABasicAnimation(keyPath: "borderWidth")
        anim.fromValue = self.controlButton.layer.borderWidth
        anim.toValue = borderWidth
        anim.duration = 0.1
        self.controlButton.layer.add(anim, forKey: "width")
        self.controlButton.layer.borderWidth = borderWidth
        DispatchQueue.main.asyncAfter(deadline: .now() + after) {
            self.controlRing.layer.borderColor = ringColor?.cgColor

        }
    }
}
