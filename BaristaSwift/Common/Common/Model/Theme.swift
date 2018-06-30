//
//  Theme.swift
//  Consumer
//
//  Created by Nicholas McDonald on 2/5/18.
//  Copyright © 2018 Salesforce. All rights reserved.
//

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
