//
//  StatusAlertView.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 10/1/24.
//  Copyright © 2024 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import SwiftUI

struct StatusAlert: View {
    @ObservedObject var viewModel: AlertViewModel

    func twoButtonDisplay() -> Bool {
        if let alertContent = viewModel.alertContent {
            return alertContent.okayButton && alertContent.stopButton
        }
        return false
    }

    func stopButton() -> Bool {
        return viewModel.alertContent?.stopButton ?? false
    }

    func okayButton() -> Bool {
        return viewModel.alertContent?.okayButton ?? false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            VStack {
                Text(viewModel.alertContent?.title ?? "").bold()
                Text(viewModel.alertContent?.message ?? "").lineLimit(nil)
                
                if stopButton() || okayButton() {
                    Divider()
                    HStack {
                        if stopButton() {
                            if twoButtonDisplay() {
                                Spacer()
                            }
                            Button(action: {
                                self.viewModel.alertStopTapped()
                            }, label: {
                                Text("Stop").foregroundColor(Color.blue)
                            })
                        }
                        
                        if twoButtonDisplay() {
                            Spacer()
                            Divider()
                            Spacer()
                        }

                        if okayButton() {
                            Button(action: {
                                self.viewModel.alertOkTapped()
                            }, label: {
                                Text("Ok").foregroundColor(Color.blue)
                            })
                            if twoButtonDisplay() {
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 30)
                }
            }
            .padding(10)
            .frame(maxWidth: 300, minHeight: 100)
            .background(Color(UIColor.secondarySystemBackground))
            .opacity(1.0)
            .foregroundColor(Color(UIColor.label))
            .cornerRadius(20)
        }
    }
}
