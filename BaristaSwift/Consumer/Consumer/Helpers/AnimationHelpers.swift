//
//  AnimationHelpers.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/25/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

import UIKit

class Ease {
    class func cubicEase(_ easeIn:Bool, _ easeOut:Bool, _ time:CGFloat, _ start:CGFloat, _ change:CGFloat, _ duration:CGFloat) -> CGFloat {
        var t = time
        let b = start
        let c = change
        let d = duration
        if easeIn && easeOut {
            t = t/(d/2)
            if t<1 {
                return c/2*t*t*t + b
            }
            t = t-2
            return c/2*(t*t*t + 2) + b
        } else if easeIn {
            t = t/d
            return c*t*t*t + b
        } else if easeOut {
            t = t/d
            t = t-1
            return c*(t*t*t + 1) + b
        } else {
            return t
        }
    }
}
