/*
  SliderControl.swift
  Consumer

  Created by Nicholas McDonald on 2/15/18.

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

class SliderControl: ProductConfigControlBase {
    
    var minTrackColor: UIColor? {
        didSet {
            self.minTrack.backgroundColor = minTrackColor
        }
    }
    var maxTrackColor: UIColor? {
        didSet {
            self.maxTrack.backgroundColor = maxTrackColor
        }
    }
    var thumbColor: UIColor? {
        didSet {
            self.thumb.backgroundColor = thumbColor
        }
    }
    var textColor: UIColor? {
        didSet {
            self.thumbLabel.textColor = textColor
        }
    }
    var textFont: UIFont! {
        didSet {
            self.thumbLabel.font = textFont
        }
    }
    var thumbLabels: [String]? {
        didSet {
            if let first = thumbLabels?.first {
                self.thumbLabel.text = first
            }
        }
    }
    
    fileprivate var minTrack = UIView()
    fileprivate var maxTrack = UIView()
    fileprivate var thumb = UIView()
    fileprivate var thumbLabel = UILabel()
    
    fileprivate var initialTouchPoint:CGPoint?
    fileprivate var thumbXConstraint:NSLayoutConstraint!
    
    fileprivate static let minTrackheight:CGFloat = 12.0
    fileprivate static let maxTrackHeight:CGFloat = 6.0
    fileprivate static let thumbSize:CGFloat = 32.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.minTrack.translatesAutoresizingMaskIntoConstraints = false
        self.minTrack.isUserInteractionEnabled = false
        self.minTrack.layer.cornerRadius = SliderControl.minTrackheight / 2.0
        self.addSubview(self.minTrack)

        self.maxTrack.translatesAutoresizingMaskIntoConstraints = false
        self.maxTrack.isUserInteractionEnabled = false
        self.maxTrack.layer.cornerRadius = SliderControl.maxTrackHeight / 2.0
        self.addSubview(self.maxTrack)
        
        self.thumb.translatesAutoresizingMaskIntoConstraints = false
        self.thumb.isUserInteractionEnabled = false
        self.thumb.layer.cornerRadius = SliderControl.thumbSize / 2.0
        self.addSubview(self.thumb)
        
        self.thumbLabel.translatesAutoresizingMaskIntoConstraints = false
        self.thumbLabel.isUserInteractionEnabled = false
        self.addSubview(self.thumbLabel)
        
        self.minTrack.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.maxTrack.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.minTrack.rightAnchor.constraint(equalTo: self.maxTrack.leftAnchor).isActive = true
        self.minTrack.heightAnchor.constraint(equalToConstant: SliderControl.minTrackheight).isActive = true
        self.minTrack.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.maxTrack.heightAnchor.constraint(equalToConstant: SliderControl.maxTrackHeight).isActive = true
        self.maxTrack.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        self.thumb.widthAnchor.constraint(equalToConstant: SliderControl.thumbSize).isActive = true
        self.thumb.heightAnchor.constraint(equalToConstant: SliderControl.thumbSize).isActive = true
        self.thumb.centerYAnchor.constraint(equalTo: self.minTrack.centerYAnchor).isActive = true
        self.thumb.centerXAnchor.constraint(equalTo: self.minTrack.rightAnchor).isActive = true
        
        self.thumbLabel.centerXAnchor.constraint(equalTo: self.thumb.centerXAnchor).isActive = true
        self.thumbLabel.centerYAnchor.constraint(equalTo: self.thumb.centerYAnchor).isActive = true
        
        self.thumbXConstraint = self.minTrack.rightAnchor.constraint(equalTo: self.leftAnchor, constant: SliderControl.thumbSize / 2.0)
        self.thumbXConstraint.isActive = true
        
        self.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
        self.heightAnchor.constraint(equalToConstant: SliderControl.thumbSize).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if let labels = self.thumbLabels {
            precondition(labels.count == self.maxValue, "you must have the same number of labels as possible values if labels provided")
        }
        let touchPoint = touch.location(in: self)
        self.initialTouchPoint = touchPoint
        
        if self.thumb.frame.contains(touchPoint) {
            return true
        }
        
        return false
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard let initial = self.initialTouchPoint else { return false}
        let touchPoint = touch.location(in: self)
        let delta = initial.x - touchPoint.x
        var total = self.thumbXConstraint.constant - delta
        if total > self.frame.size.width {
            total = self.frame.size.width - 1.0 // keeps from overflowing
        } else if total < 0.0 {
            total = 0.0
        }
        self.thumbXConstraint.constant = total
        self.layoutIfNeeded()
        self.initialTouchPoint = touchPoint
        if let labels = self.thumbLabels {
            let windowSize:CGFloat = (self.frame.size.width / CGFloat(self.maxValue))
            let currentWindow = Int(total / windowSize)
            if currentWindow + 1 <= labels.count {
                let label = labels[currentWindow]
                self.thumbLabel.text = label
            }
        }
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if self.maxValue == 0 { return }
        let endPosition = self.thumbXConstraint.constant
        let windowSize:CGFloat = self.frame.size.width / CGFloat(self.maxValue)
        let inWindow = Int(endPosition / windowSize)
        let stickToWindowSize = self.frame.size.width / CGFloat(self.maxValue - 1)
        var stickTo:CGFloat = stickToWindowSize * CGFloat(inWindow)
        let min = SliderControl.thumbSize / 2.0
        let max = self.frame.size.width - (SliderControl.thumbSize / 2.0)
        if stickTo < min {
            stickTo = min
        } else if stickTo > max {
            stickTo = max
        }
        
        self.currentValue = inWindow
        UIView.animate(withDuration: 0.2, animations: {
            self.thumbXConstraint.constant = stickTo
            self.layoutIfNeeded()
        }) { (completed) in
            self.sendActions(for: .valueChanged)
        }
    }
    
}
