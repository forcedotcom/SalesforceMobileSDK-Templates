/*
  UIViewExtension.swift
  Consumer

  Created by David Vieser on 2/7/18.

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

import Foundation
import UIKit

extension UIView {
    public enum Side: Int {
        case left = 0
        case right
        case top
        case bottom
    }
    
    public enum Direction: Int {
        case concave = 0
        case convex
    }

    public func mask(offset curveOffset: CGFloat, direction: Direction, side: Side) {
        let left: CGFloat = bounds.minX + ((side == .left) && (direction == .convex) ? curveOffset : 0)
        let right: CGFloat = bounds.maxX - ((side == .right) && (direction == .convex) ? curveOffset : 0)
        let top: CGFloat = bounds.minY + ((side == .top) && (direction == .convex) ? curveOffset : 0)
        let bottom: CGFloat = bounds.maxY - ((side == .bottom) && (direction == .convex) ? curveOffset : 0)
        var control: CGPoint {
            switch side {
            case .left:
                return CGPoint(x: bounds.minX + (direction == .concave ? curveOffset : 0), y: bounds.midY)
            case .right:
                return CGPoint(x: bounds.maxX - (direction == .concave ? curveOffset : 0), y: bounds.midY)
            case .top:
                return CGPoint(x: bounds.midX, y: bounds.minY + (direction == .concave ? curveOffset : 0))
            case .bottom:
                return CGPoint(x: bounds.midX, y: bounds.maxY - (direction == .concave ? curveOffset : 0))
            }
        }

        let maskPath: UIBezierPath = UIBezierPath()
        
        func draw(side currentSide: Side, toX: CGFloat, toY: CGFloat) {
            side == currentSide ? maskPath.addQuadCurve(to: CGPoint(x: toX, y: toY), controlPoint: control) : maskPath.addLine(to: CGPoint(x: toX, y: toY))
        }

        maskPath.move(to: CGPoint(x: left, y: top))
        draw(side: .top, toX: right, toY: top)
        draw(side: .right, toX: right, toY: bottom)
        draw(side: .bottom, toX: left, toY: bottom)
        draw(side: .left, toX: left, toY: top)
        
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    func round() {
        layer.cornerRadius = bounds.size.width / 2
    }
}
