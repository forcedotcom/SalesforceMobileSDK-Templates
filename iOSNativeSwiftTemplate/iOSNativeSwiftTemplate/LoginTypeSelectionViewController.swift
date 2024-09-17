//
//  LoginTypeSelectionViewController.swift
//  iOSNativeSwiftTemplate
//
//  Created by Eric Johnson on 9/3/24.
//  Copyright © 2024 iOSNativeSwiftTemplateOrganizationName. All rights reserved.
//

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
        loginWithQrCodeButton.backgroundColor = UIColor.purple
        loginWithQrCodeButton.setTitle("Log In With QR Code", for: .normal)
        
        view.addSubview(loginWithQrCodeButton)
    }
    
    override func viewWillLayoutSubviews() {
        // Intentionally blank to negate legacy super view layout.
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Replace legacy super view layout with a comparable constraint layout including the Log In With QR Code button.
        self.view.translatesAutoresizingMaskIntoConstraints = true
        
        if let oauthView = oauthView {
            oauthView.translatesAutoresizingMaskIntoConstraints = false
            oauthView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            oauthView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            oauthView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            if let biometricButton = self.biometricButton {
                biometricButton.translatesAutoresizingMaskIntoConstraints = false
                biometricButton.topAnchor.constraint(equalTo: oauthView.bottomAnchor, constant: 22.0).isActive = true
                loginWithQrCodeButton.topAnchor.constraint(equalTo: biometricButton.bottomAnchor, constant: 22.0).isActive = true
            } else {
                loginWithQrCodeButton.topAnchor.constraint(equalTo: oauthView.bottomAnchor, constant: 22.0).isActive = true
            }
            
            loginWithQrCodeButton.translatesAutoresizingMaskIntoConstraints = false
            loginWithQrCodeButton.widthAnchor.constraint(equalToConstant: 200.0).isActive = true
            loginWithQrCodeButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
            loginWithQrCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            loginWithQrCodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22.0).isActive = true
        }
    }
    
    @objc
    func loginWithQrCodeButtonTapped(_: Any?) {

        // Present a QR code scan controller to capture the log in QR code.
        let qrCodeScanController = QrCodeScanController()
        qrCodeScanController.onQrCodeCaptured = { qrCodePayloadString in
         
            // Login using the QR code payload.
            print("🤘🏻 \(qrCodePayloadString)")
            let _ = self.loginFromQrCode(loginQrCodeContent: qrCodePayloadString)
        }
        present(qrCodeScanController, animated: true)
    }
}
