//
//  UIViewExtension.swift
//  Consumer
//
//  Created by David Vieser on 2/7/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

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
