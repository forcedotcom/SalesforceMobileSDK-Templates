/*
  Theme.swift
  Consumer

  Created by Nicholas McDonald on 2/5/18.

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

public struct Theme {
    
    // Colors
    public static var headingTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 1.0)
        }
    }
    
    public static var tabBarUnselectedColor: UIColor {
        get {
            return UIColor(displayP3Red: 247.0/255.0, green: 244.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        }
    }
    
    public static var tabBarSelectedColor: UIColor {
        get {
            return UIColor(displayP3Red: 250.0/255.0, green: 200.0/255.0, blue: 19.0/255.0, alpha: 1.0)
        }
    }
    
    public static var menuTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 47.0/255.0, green: 26.0/255.0, blue: 0.0, alpha: 1.0)
        }
    }
    
    public static var cartItemTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 28.0/255.0, green: 15.0/255.0, blue: 11.0/255.0, alpha: 1.0)
        }
    }
    
    public static var cartAddButtonTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        }
    }
    
    public static var cartCancelButtonTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 3.0/255.0, green: 201.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigDividerColor: UIColor {
        get {
            return UIColor(displayP3Red: 3.0/255.0, green: 201.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigAddToCartColor: UIColor {
        get {
            return UIColor(displayP3Red: 3.0/255.0, green: 201.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigCancelAddToCartColor: UIColor {
        get {
            return UIColor(displayP3Red: 0.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 0.0)
        }
    }
    
    public static var productConfigTopBgGradColor: UIColor {
        get {
            return UIColor(displayP3Red: 46.0/255.0, green: 25.0/255.0, blue: 18.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigBottomBgGradColor: UIColor {
        get {
            return UIColor(displayP3Red: 28.0/255.0, green: 15.0/255.0, blue: 11.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigTableSeparatorColor: UIColor {
        get {
            return UIColor(displayP3Red: 151.0/255.0, green: 137.0/255.0, blue: 129.0/255.0, alpha: 1.0)
        }
    }
    
    public static var productConfigSliderMaxTrackColor: UIColor {
        get {
            return UIColor(displayP3Red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.5)
        }
    }
    
    public static var appMainControlColor: UIColor {
        get {
            return UIColor(displayP3Red: 3.0/255.0, green: 201.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    public static var appMainControlTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        }
    }
    
    public static var appDestructiveControlColor: UIColor {
        get {
            return UIColor(displayP3Red: 3.0/255.0, green: 201.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    public static var appNavBarTintColor: UIColor {
        get {
            return UIColor(displayP3Red: 247.0/255.0, green: 244.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        }
    }
    
    public static var appNavBarTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 28.0/255.0, green: 15.0/255.0, blue: 11.0/255.0, alpha: 1.0)
        }
    }
    
    public static var categoryItemTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 28.0/255.0, green: 15.0/255.0, blue: 11.0/255.0, alpha: 1.0)
        }
    }
    
    public static var appAccentColor01: UIColor {
        get {
            return UIColor(displayP3Red: 3.0/255.0, green: 201.0/255.0, blue: 244.0/255.0, alpha: 1.0)
        }
    }
    
    public static var featureItemTextColor: UIColor {
        get {
            return UIColor(displayP3Red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        }
    }
    
    // Fonts
    
    public static func appBoldFont(_ size:CGFloat) -> UIFont? {
        return UIFont(name: "AvenirNext-DemiBold", size: size)
    }
    
    public static func appMediumFont(_ size:CGFloat) -> UIFont? {
        return UIFont(name: "AvenirNext-Medium", size: size)
    }
    
    public static func appRegularFont(_ size:CGFloat) -> UIFont? {
        return UIFont(name: "AvenirNext-Regular", size: size)
    }
    
    public static var appBoldFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-DemiBold", size: 12.0)
        }
    }
    
    public static var menuTextFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-DemiBold", size: 12.0)
        }
    }
    
    public static var tabBarFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-DemiBold", size: 11.0)
        }
    }
    
    public static var cartButtonFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-DemiBold", size: 12.0)
        }
    }
    
    public static var productConfigButtonFont: UIFont? {
        get {
            return UIFont(name: "DrukText-Medium", size: 16.0)
        }
    }
    
    public static var productConfigItemNameFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-DemiBold", size: 18.0)
        }
    }
    
    public static var productConfigItemPriceFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-Medium", size: 14.0)
        }
    }
    
    public static var productConfigItemDescriptionFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-Medium", size: 12.0)
        }
    }
    
    public static var productConfigItemCellFont: UIFont? {
        get {
            return UIFont(name: "AvenirNext-DemiBold", size: 14.0)
        }
    }
}
