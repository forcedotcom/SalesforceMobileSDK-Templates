//
//  AlertViewModel.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 10/1/24.
//  Copyright © 2024 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import SwiftUI

struct AlertContent: Identifiable {
    var id = UUID()
    var title: String?
    var message: String?
    var stopButton = false
    var okayButton = false
}

// Using custom alert so it can be updated with status changes
class AlertViewModel: ObservableObject {
    @Published var alertContent: AlertContent?
    @Published var showAlertContent = false
    
    func createAlert(title: String, message: String?, stopButton: Bool, okayButton: Bool = false) {
        alertContent = AlertContent(title: title, message: message, stopButton: stopButton, okayButton: okayButton)
        showAlertContent = true
    }
    
    func updateAlert(info: String?, okayButton: Bool = true) {
        showAlertContent = true
        if alertContent != nil {
            alertContent!.message = info
            alertContent!.okayButton = okayButton
        }
    }
    
    func alertOkTapped() {
        withAnimation {
            alertContent = nil
            showAlertContent = false
        }
    }
    
    func alertStopTapped() {}
}
