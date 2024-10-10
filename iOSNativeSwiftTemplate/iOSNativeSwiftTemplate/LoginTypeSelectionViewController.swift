//
//  LoginTypeSelectionViewController.swift
//  iOSNativeSwiftTemplate
//
//  Created by Eric Johnson on 9/3/24.
//
//  Copyright (c) 2024-present, salesforce.com, inc. All rights reserved.
//
//  Redistribution and use of this software in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials provided
//  with the distribution.
//  * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission of salesforce.com, inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import SalesforceSDKCore
import UIKit

/**
 * Adds QR code log in to the Salesforce Mobile SDK login view.
 */
class LoginTypeSelectionViewController: SalesforceLoginViewController {
    
    /** A button for QR code log in */
    let loginWithQrCodeButton = UIButton()
    
    override func loadView() {
        super.loadView()
        
        // Load the Log In With QR Code button.
        loginWithQrCodeButton.addTarget(
            self,
            action: #selector(loginWithQrCodeButtonTapped),
            for: .touchUpInside)
        loginWithQrCodeButton.setTitle("Log In with QR Code", for: .normal)
        
        view.addSubview(loginWithQrCodeButton)
    }
    
    override func viewWillLayoutSubviews() {
        // Intentionally blank to negate legacy super view layout.
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Replace legacy super view layout with a comparable constraint layout including the Log In With QR Code button.
        view.translatesAutoresizingMaskIntoConstraints = true
        
        if let oauthView = oauthView {
            oauthView.translatesAutoresizingMaskIntoConstraints = false
            oauthView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            oauthView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            oauthView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            if let biometricButton = biometricButton {
                biometricButton.layer.borderColor = UIColor.white.cgColor
                biometricButton.layer.borderWidth = 2.0
                biometricButton.translatesAutoresizingMaskIntoConstraints = false
                biometricButton.topAnchor.constraint(equalTo: oauthView.bottomAnchor, constant: 22.0).isActive = true
                biometricButton.widthAnchor.constraint(equalToConstant: 250.0).isActive = true
                biometricButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
                biometricButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                loginWithQrCodeButton.topAnchor.constraint(equalTo: biometricButton.bottomAnchor, constant: 22.0).isActive = true
            } else {
                loginWithQrCodeButton.topAnchor.constraint(equalTo: oauthView.bottomAnchor, constant: 22.0).isActive = true
            }
            
            loginWithQrCodeButton.layer.borderColor = UIColor.white.cgColor
            loginWithQrCodeButton.layer.borderWidth = 2.0
            loginWithQrCodeButton.translatesAutoresizingMaskIntoConstraints = false
            loginWithQrCodeButton.widthAnchor.constraint(equalToConstant: 250.0).isActive = true
            loginWithQrCodeButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
            loginWithQrCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loginWithQrCodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22.0).isActive = true
        }
    }
    
    @objc
    func loginWithQrCodeButtonTapped(_: Any?) {
        
        // Present a QR code scan controller to capture the log in QR code.
        let qrCodeScanController = QrCodeScanController()
        qrCodeScanController.onQrCodeCaptured = { qrCodeLoginUrl in
            
            // Use the QR code login URL.
            let _ = LoginTypeSelectionViewController.loginWithFrontdoorBridgeUrlFromQrCode(qrCodeLoginUrl)
        }
        present(qrCodeScanController, animated: true)
    }
}
