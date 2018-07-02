/*
  CartFooterView.swift
  Consumer

  Created by Nicholas McDonald on 2/13/18.

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
import Common

class CartFooterView: UIView {
    
    fileprivate var totalLabel = UILabel()
    fileprivate var editButton = UIButton(type: .custom)
    var total:String? {
        didSet {
            self.totalLabel.text = total
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        let topBar = UIView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor(white:0.5, alpha:0.3)
        self.addSubview(topBar)
        
        let totalContainer = UIView()
        totalContainer.translatesAutoresizingMaskIntoConstraints = false
        totalContainer.backgroundColor = UIColor(white: 0.5, alpha: 0.1)
        self.addSubview(totalContainer)
        
        let botBar = UIView()
        botBar.translatesAutoresizingMaskIntoConstraints = false
        botBar.backgroundColor = UIColor(white:0.5, alpha:0.3)
        self.addSubview(botBar)
        
        self.editButton.translatesAutoresizingMaskIntoConstraints = false
        self.editButton.setTitle("Edit Order", for: .normal)
        self.editButton.setTitleColor(Theme.appAccentColor01, for: .normal)
        self.editButton.titleLabel?.font = Theme.appMediumFont(13.0)
        self.addSubview(editButton)
        
        let totalTextLabel = UILabel()
        totalTextLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTextLabel.text = "TOTAL"
        totalTextLabel.font = Theme.appBoldFont(14.0)
        totalTextLabel.textColor = Theme.cartItemTextColor
        
        self.totalLabel.translatesAutoresizingMaskIntoConstraints = false
        self.totalLabel.font = Theme.appBoldFont(14.0)
        self.totalLabel.textColor = Theme.cartItemTextColor
        
        totalContainer.addSubview(totalTextLabel)
        totalContainer.addSubview(self.totalLabel)
        
        totalTextLabel.leftAnchor.constraint(equalTo: totalContainer.leftAnchor, constant: 20).isActive = true
        totalTextLabel.centerYAnchor.constraint(equalTo: totalContainer.centerYAnchor).isActive = true
        self.totalLabel.rightAnchor.constraint(equalTo: totalContainer.rightAnchor, constant: -20).isActive = true
        self.totalLabel.centerYAnchor.constraint(equalTo: totalContainer.centerYAnchor).isActive = true
        
        topBar.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        topBar.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        topBar.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        topBar.bottomAnchor.constraint(equalTo: totalContainer.topAnchor).isActive = true
        
        totalContainer.topAnchor.constraint(equalTo: self.topAnchor, constant:0).isActive = true
        totalContainer.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        totalContainer.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        totalContainer.heightAnchor.constraint(equalToConstant: 34.0).isActive = true
        
        botBar.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        botBar.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        botBar.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        botBar.topAnchor.constraint(equalTo: totalContainer.bottomAnchor).isActive = true
        
        self.editButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.editButton.topAnchor.constraint(equalTo: totalContainer.bottomAnchor, constant:20).isActive = true
        self.editButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
