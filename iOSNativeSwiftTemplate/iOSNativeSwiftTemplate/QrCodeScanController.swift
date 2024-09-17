//
//  QrCodeScanController.swift
//  iOSNativeSwiftTemplate
//
//  Created by Eric Johnson on 8/30/24.
//  Copyright © 2024 iOSNativeSwiftTemplateOrganizationName. All rights reserved.
//

import AVFoundation
import Foundation
import SwiftUI

/**
 * A view enabling QR code capture.
 */
class QrCodeScanController: UIViewController {
    
    // MARK: - View Controller Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            await setupCaptureView()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Layout the video capture preview view.
        avVideoPreviewLayer?.frame = view.bounds
    }
    
    // MARK: - QR Code Scan Controller Implementation
    
    /** A callback when the QR code is captured */
    var onQrCodeCaptured: ((String) -> ())? = nil
    
    // MARK: - QR Code Scan Controller A/V Implementation
    
    /** The A/V video capture preview layer used as the QR code viewfinder */
    private var avVideoPreviewLayer: AVCaptureVideoPreviewLayer? = nil
    
    /**
     * Determines if the user has authorized camera access for this app, requested authorization from the
     * user if needed.
     *
     * See https://developer.apple.com/documentation/avfoundation/capture_setup/requesting_authorization_to_capture_and_save_media
     */
    private var isAuthorized: Bool {
        get async {
            // Fetch video capture authorization status.
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized video capture.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status, explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    /**
     * Sets up for image capture via the device camera and A/V foundation.
     */
    private func setupCaptureView() async {
        
        // Review video capture authorization status.
        guard await isAuthorized else { return }
        
        // Acquire the default video capture device.
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            // Fetch the video capture input.
            let input = try AVCaptureDeviceInput(device: device)
            
            let session = AVCaptureSession()
            session.addInput(input)
            
            // Create the video capture preview view.
            let avVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            avVideoPreviewLayer.videoGravity = .resizeAspectFill
            self.avVideoPreviewLayer = avVideoPreviewLayer
            
            // Create the video capture metadata output used to extract the QR code.
            let output = AVCaptureMetadataOutput()
            
            // Create the A/V session.
            session.addOutput(output)
            
            // Add the video capture preview view to the root view.
            view.layer.addSublayer(avVideoPreviewLayer)
            
            // Start the A/V session.
            DispatchQueue.global(qos: .background).async {
                
                output.setMetadataObjectsDelegate(self, queue: .main)
                let x = output.availableMetadataObjectTypes
                output.metadataObjectTypes = [.qr]
                
                session.startRunning()
            }
        } catch {
            
            // Handle A/V errors.
            displayAlert()
        }
    }
    
    // MARK: - Alerts
    
    private func displayAlert() {
        let alert = UIAlertController(title: Constants.alertTitle,
                                      message: Constants.alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.alertButtonTitle,
                                      style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let alertTitle = "Camera Session Error"
        static let alertMessage = "Cannot scan QR codes as a camera session could not be started."
        static let alertButtonTitle = "OK"
    }
}

// MARK: - A/V Capture Metadata Output Objects Delegate Implementation

let lock = NSLock()

extension QrCodeScanController: AVCaptureMetadataOutputObjectsDelegate {
        
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        guard lock.try() else { return }

        
        // Guard for QR metadata objects.
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let qrCodePayloadString = metadataObject.stringValue,
              qrCodePayloadString.starts(with: "mobileapp://") else { return }
        
        // Deliver the first QR code when it is captured.
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            lock.unlock()
            self.onQrCodeCaptured?(qrCodePayloadString)
            self.onQrCodeCaptured = nil
        }
        
        // Automatically dismiss.
        dismiss(animated: true)
    }
}
