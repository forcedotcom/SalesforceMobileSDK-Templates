//
//  PercentLine.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/24/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

protocol PercentLineCompletionDelegate: NSObjectProtocol {
    func lineDidCompleteAnimation()
}

class PercentLine: UIControl {
    
    enum LineCapStyle {
        case round
        case butt
    }
    
    weak var delegate:PercentLineCompletionDelegate?
    var maxValue:Float = 100.0
    var thickness:CGFloat = 0.0
    var showTrack:Bool = false
    var currentValue:Float = 0.0 {
        didSet {
            self.startValue = 0.0
            self.setNeedsDisplay()
        }
    }
    var color:UIColor = UIColor.white
    var trackColor:UIColor = UIColor(white: 0.0, alpha: 0.2)
    var capStyle:LineCapStyle = .butt
    var finalValue:Float = 0.0 {
        didSet {
            self.beginAnimation()
        }
    }
    var goalValue:Float = 0.0 {
        didSet {
            self.shouldShowEffectAtGoalValue = true
        }
    }
    var valueFont:UIFont? {
        didSet {
            self.valueLabel.font = valueFont
        }
    }
    var valueTextColor:UIColor = UIColor.white {
        didSet {
            self.valueLabel.textColor = valueTextColor
        }
    }
    var titleFont:UIFont? {
        didSet {
            self.titleLabel?.font = titleFont
        }
    }
    var titleTextColor:UIColor = UIColor.white {
        didSet {
            self.titleLabel?.textColor = titleTextColor
        }
    }
    var subtitleFont:UIFont? {
        didSet {
            self.subtitleLabel?.font = subtitleFont
        }
    }
    var subtitleTextColor:UIColor = UIColor.white {
        didSet {
            self.subtitleLabel?.textColor = subtitleTextColor
        }
    }
    var valuePrefix:String = ""
    var valueSuffix:String = ""
    
    var shouldHideValueDisplay:Bool = false
    var shouldAnimateValueDiplay:Bool = true
    var shouldShowEffectAtGoalValue:Bool = false
    var decimalCountToDisplay:Int = 1 {
        didSet {
            self.updateValueLabel()
        }
    }
    
    private var displayLink:CADisplayLink!
    private var currentPercentComplete:Float = 0.0
    private var currentAnimationTime:Float = 0.0
    private var animationDuration:Float = 0.0
    private var startValue:Float = 0.0
    private var labelContainer:UIView = UIView()
    private var valueLabel:UILabel = UILabel()
    private var titleLabel:UILabel?
    private var subtitleLabel:UILabel?
    private var iconImageView:UIImageView?
    
    
    init(title:String?, subtitle:String?, icon:UIImage?) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.backgroundColor = UIColor.clear
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = false
        self.labelContainer.translatesAutoresizingMaskIntoConstraints = false
        self.labelContainer.isUserInteractionEnabled = false
        
        self.addSubview(self.labelContainer)
        self.labelContainer.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.labelContainer.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.labelContainer.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.valueLabel.font = self.valueFont
        self.valueLabel.textColor = self.valueTextColor
        self.labelContainer.addSubview(self.valueLabel)
        self.valueLabel.centerXAnchor.constraint(equalTo: self.labelContainer.centerXAnchor).isActive = true
        self.valueLabel.centerYAnchor.constraint(equalTo: self.labelContainer.centerYAnchor).isActive = true
        
        if let t = title {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = self.titleFont
            label.textColor = self.titleTextColor
            label.text = t
            label.isUserInteractionEnabled = false
            self.titleLabel = label
            self.labelContainer.addSubview(label)
            label.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: self.valueLabel.topAnchor).isActive = true
            label.topAnchor.constraint(equalTo: labelContainer.topAnchor).isActive = true
        }
        
        if let st = subtitle {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = self.subtitleFont
            label.textColor = self.subtitleTextColor
            label.text = st
            label.isUserInteractionEnabled = false
            self.subtitleLabel = label
            self.labelContainer.addSubview(label)
            label.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).isActive = true
            label.topAnchor.constraint(equalTo: self.valueLabel.bottomAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: labelContainer.bottomAnchor).isActive = true
        }
        
        if let i = icon {
            let imageview = UIImageView(image: i)
            imageview.translatesAutoresizingMaskIntoConstraints = false
            imageview.contentMode = .scaleAspectFit
            imageview.isUserInteractionEnabled = false
            self.iconImageView = imageview
            self.labelContainer.addSubview(imageview)
            imageview.centerXAnchor.constraint(equalTo: labelContainer.centerXAnchor).isActive = true
            imageview.bottomAnchor.constraint(equalTo: self.valueLabel.topAnchor).isActive = true
            imageview.topAnchor.constraint(equalTo: labelContainer.topAnchor).isActive = true
        }
        
        self.setNeedsDisplay()
        
        self.updateValueLabel()
    }
    
    convenience init() {
        self.init(title:nil)
    }
    
    convenience init(title:String?) {
        self.init(title:title, subtitle:nil)
    }
    
    convenience init(title:String?, subtitle:String?) {
        self.init(title:title, subtitle:subtitle, icon:nil)
    }
    
    convenience init(icon:UIImage?) {
        self.init(title:nil, subtitle:nil, icon:icon)
    }
    
    convenience init(icon:UIImage?, subtitle:String?) {
        self.init(title:nil, subtitle:subtitle, icon:icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateValueLabel() {
        self.valueLabel.text = NSString(format: "%@%0.*f%@", self.valuePrefix, self.decimalCountToDisplay, self.currentValue, self.valueSuffix) as String
    }
    
    private func beginAnimation() {
        self.animationDuration = max((fabsf((self.finalValue - self.startValue))/30.0), 0.15)
        self.currentAnimationTime = 0.0
        self.currentPercentComplete = 0.0
        if let d = self.displayLink {
            d.invalidate()
            self.displayLink = nil
        }
        self.displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire(displayLink:)))
        self.displayLink.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    @objc private func displayLinkDidFire(displayLink:CADisplayLink) {
        self.currentAnimationTime = self.currentAnimationTime + Float(displayLink.duration)
        
        if self.currentAnimationTime >= self.animationDuration {
            self.displayLink.invalidate()
            self.displayLink = nil
            self.currentPercentComplete = (self.finalValue / self.maxValue)
            self.currentValue = self.finalValue
            self.startValue = self.finalValue
            if let d = self.delegate {
                d.lineDidCompleteAnimation()
            }
        } else {
            let t = Ease.cubicEase(true, true, CGFloat(self.currentAnimationTime), 0.0, 1.0, CGFloat(self.animationDuration))
            
            self.currentValue = (Float(t) * (self.finalValue - self.startValue)) + self.startValue
            self.currentPercentComplete = self.currentValue / self.maxValue
        }
        
        if self.shouldShowEffectAtGoalValue {
            if self.currentValue >= self.goalValue {
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                    self.valueLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: { (completed) in
                    
                })
            }
        }
        
        self.setNeedsDisplay()
        
        self.valueLabel.text = NSString(format: "%@%0.*f%@", self.valuePrefix, self.decimalCountToDisplay, self.currentValue, self.valueSuffix) as String
    }
    
    override func draw(_ rect: CGRect) {
        if let ctx = UIGraphicsGetCurrentContext() {
            var lineThickness:CGFloat = 0.0
            
            if self.thickness == 0.0 {
                lineThickness = rect.size.height / 10.0
            } else {
                lineThickness = self.thickness
            }
            
            ctx.setLineWidth(lineThickness)
            switch self.capStyle {
            case .round:
                ctx.setLineCap(.round)
            case .butt:
                ctx.setLineCap(.butt)
            }
            
            if self.showTrack {
                self.trackColor.setStroke()
                ctx.move(to: CGPoint(x: 0.0, y: rect.size.height))
                ctx.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
                ctx.strokePath()
            }
            
            self.color.setStroke()
            ctx.move(to: CGPoint(x: 0.0, y: rect.size.height))
            let width = rect.size.width * CGFloat(self.currentValue/self.goalValue)
            ctx.addLine(to: CGPoint(x: width, y: rect.size.height))
            ctx.strokePath()
        }
    }
}
