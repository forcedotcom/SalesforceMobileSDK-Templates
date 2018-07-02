/*
  ImageCache.swift
  Consumer

  Created by David Vieser on 2/16/18.

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
import SalesforceSwiftSDK

public class ImageCache {
    
    static public func fetchImageUsingCache(withUrl urlString : String?, completion: ((UIImage?) -> ())? = nil) -> UIImage? {
        guard urlString != nil else {
            return nil
        }
        let imageScale = Int(UIScreen.main.scale)
        var url = URL(string:  urlString!)
        if imageScale > 1 {
            let newFileName = url?.lastPathComponent.replacingOccurrences(of: ".", with: "@\(imageScale)x.") ?? ""
            url?.deleteLastPathComponent()
            url?.appendPathComponent(newFileName)
        }
        
        // check cached image
        
        if let cachedImage = imageCache.object(forKey: urlString! as NSString) {
            let image = UIImage(cgImage: cachedImage as! CGImage, scale: CGFloat(imageScale), orientation: UIImageOrientation.up)
            return image
        }
        
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            guard error == nil else {
                SalesforceSwiftLogger.log(type(of:self) as! AnyClass, level:.error, message: "\(String(describing: url)) failed to download")
                return
            }
            if let image = UIImage(data: data!), let cgImage = image.cgImage {
                imageCache.setObject(cgImage, forKey: urlString! as NSString)
                let scaled = UIImage(cgImage: cgImage, scale: CGFloat(imageScale), orientation: UIImageOrientation.up)
                completion?(scaled)
                
            }
        }).resume()
        return nil
    }
}
