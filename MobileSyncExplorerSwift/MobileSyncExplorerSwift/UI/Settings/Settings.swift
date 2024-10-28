//
//  Settings.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 8/16/24.
//  Copyright © 2024 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import SwiftUI
import SalesforceSDKCore
import SmartStore

enum ModalAction: Identifiable {
    case switchUser
    case inspectDB

    var id: Int {
        return self.hashValue
    }
}

struct Settings: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var modalPresented: ModalAction?
    @State private var logoutAlertPresented = false
    
    init(sObjectDataManager: SObjectDataManager) {
        viewModel = SettingsViewModel(sObjectDataManager: sObjectDataManager)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        Button("Clear Local Data", action: viewModel.clearLocalData)
                        Button("Show Info", action: viewModel.showInfo)
                        Button("Refresh Local Data", action: viewModel.refreshLocalData)
                        Button("Sync Down", action: viewModel.syncDown)
                        Button("Sync Up", action: viewModel.syncUp)
                        Button("Clean Sync Ghosts", action: viewModel.cleanGhosts)
                        Button("Stop Sync Manager", action: viewModel.stopSyncManager)
                        Button("Resume Sync Manager", action: viewModel.resumeSyncManager)
                    }
                    
                    Section {
                        Button("Inspect Database", action: {
                            modalPresented = .inspectDB
                        })
                    }
                    
                    Section {
                        Button("Logout", action: {
                            logoutAlertPresented = true
                        })
                        Button("Switch User", action: {
                            modalPresented = .switchUser
                        })
                    }
                }
                if viewModel.alertContent != nil {
                    StatusAlert(viewModel: viewModel)
                }
            }
            .sheet(item: $modalPresented) { creationType in
                if creationType == ModalAction.inspectDB, let store = self.viewModel.sObjectDataManager.store {
                    InspectorViewControllerWrapper(store: store)
                } else if creationType == ModalAction.switchUser {
                    SalesforceUserManagementViewControllerWrapper()
                }
            }
            .alert(isPresented: $logoutAlertPresented, content: {
                Alert(title: Text("Are you sure you want to log out?"),
                      primaryButton: .destructive(Text("Logout"), action: {
                          UserAccountManager.shared.logout()
                      }),
                      secondaryButton: .cancel())
            })
            .navigationTitle("Settings")
        }
    }
}

struct InspectorViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = InspectorViewController
    var store: SmartStore

    func updateUIViewController(_ uiViewController: InspectorViewController, context: Context) {
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<InspectorViewControllerWrapper>) -> InspectorViewControllerWrapper.UIViewControllerType {
        return InspectorViewController(store: store)
    }
}

struct SalesforceUserManagementViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = SalesforceUserManagementViewController
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<SalesforceUserManagementViewControllerWrapper>) -> SalesforceUserManagementViewControllerWrapper.UIViewControllerType {
        return SalesforceUserManagementViewController { _ in
            self.presentationMode.wrappedValue.dismiss()
        }
    }

    func updateUIViewController(_ uiViewController: SalesforceUserManagementViewControllerWrapper.UIViewControllerType, context: UIViewControllerRepresentableContext<SalesforceUserManagementViewControllerWrapper>) {
    }
}

#Preview {
    let credentials = OAuthCredentials(identifier: "test", clientId: "", encrypted: false)!
    let userAccount = UserAccount(credentials: credentials)
    let sObjectManager = SObjectDataManager.sharedInstance(for: userAccount)
    
    Settings(sObjectDataManager: sObjectManager)
}
