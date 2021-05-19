//
//  ContactList.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 3/20/20.
//  Copyright (c) 2020-present, salesforce.com, inc. All rights reserved.
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

import SwiftUI
import MobileSync

struct ContactListView: View {
    @ObservedObject private var viewModel: ContactListViewModel
    private var notificationModel = NotificationListModel()
    @State private var searchTerm: String = ""
    @State var selectedRecord: String? = nil
    
    init(selectedRecord: String?, sObjectDataManager: SObjectDataManager) {
        self._selectedRecord = State(initialValue: selectedRecord)
        self.viewModel = ContactListViewModel(sObjectDataManager: sObjectDataManager)
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    SearchBar(text: self.$searchTerm)
                    List {
                        ForEach(viewModel.sObjectDataManager.contacts.filter { contact in
                            self.searchTerm.isEmpty ? true : self.viewModel.contactMatchesSearchTerm(contact: contact, searchTerm: self.searchTerm)
                        }) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact, sObjectDataManager: self.viewModel.sObjectDataManager, dismiss: { self.selectedRecord = nil }), tag: contact.id.stringValue, selection: $selectedRecord) {
                                if #available(iOS 14.0, *) {
                                    ContactCell(contact: contact)
                                        .onDrag { return viewModel.itemProvider(contact: contact) }
                                } else {
                                    ContactCell(contact: contact)
                                }
                            }
                            .listRowBackground(SObjectDataManager.dataLocallyDeleted(contact) ? Color.contactCellDeletedBackground : Color.clear)
                        }
                    }
                    .id(UUID())
                }
                if viewModel.alertContent != nil {
                    StatusAlert(viewModel: viewModel)
                }
            }
            .navigationBarTitle("MobileSync Explorer")
            .navigationBarItems(trailing: NavBarButtons(viewModel: viewModel, notificationModel: notificationModel))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.notificationModel.fetchNotifications()
        }
    }
}

struct StatusAlert: View {
    @ObservedObject var viewModel: ContactListViewModel

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

enum ModalAction: Identifiable {
    case switchUser
    case inspectDB

    var id: Int {
        return self.hashValue
    }
}

struct NavBarButtons: View {
    var viewModel: ContactListViewModel
    @State private var modalPresented: ModalAction?
    @State private var newContactPresented = false
    @State private var actionSheetPresented = false
    @State private var logoutAlertPresented = false
    @ObservedObject var notificationModel: NotificationListModel

    var body: some View {
        HStack {
            NavigationLink(destination: ContactDetailView(contact: nil, sObjectDataManager: self.viewModel.sObjectDataManager), isActive: $newContactPresented, label: { EmptyView() })
            Button(action: {
                self.newContactPresented = true
            }, label: { Image("plusButton").renderingMode(.template) })
            Button(action: {
                self.viewModel.syncUpDown()
            }, label: { Image("sync").renderingMode(.template) })
            Button(action: {
                self.actionSheetPresented = true
            }, label: { Image("setting").renderingMode(.template) })
                .actionSheet(isPresented: $actionSheetPresented) {
                 ActionSheet(title: Text("Additional Actions"), buttons: [
                    .default(Text("Show Info"), action: {
                        self.viewModel.showInfo()
                    }),
                    .default(Text("Clear Local Data"), action: {
                        self.viewModel.clearLocalData()
                    }),
                    .default(Text("Refresh Local Data"), action: {
                        self.viewModel.refreshLocalData()
                    }),
                    .default(Text("Sync Down"), action: {
                        self.viewModel.syncDown()
                    }),
                    .default(Text("Sync Up"), action: {
                        self.viewModel.syncUp()
                    }),
                    .default(Text("Clean Sync Ghosts"), action: {
                        self.viewModel.cleanGhosts()
                    }),
                    .default(Text("Stop Sync Manager"), action: {
                        self.viewModel.stopSyncManager()
                    }),
                    .default(Text("Resume Sync Manager"), action: {
                        self.viewModel.resumeSyncManager()
                    }),
                    .default(Text("Logout"), action: {
                        self.logoutAlertPresented = true
                    }),
                    .default(Text("Switch User"), action: {
                        self.modalPresented = ModalAction.switchUser
                    }),
                    .default(Text("Inspect DB"), action: {
                        self.modalPresented = ModalAction.inspectDB
                    }),
                    .default(Text("Cancel")
                )])
            }.sheet(item: $modalPresented) { creationType in
                if creationType == ModalAction.inspectDB {
                    InspectorViewControllerWrapper(store: self.viewModel.sObjectDataManager.store)
                } else if creationType == ModalAction.switchUser {
                    SalesforceUserManagementViewControllerWrapper()
                }
            }
            NotificationBell(notificationModel: notificationModel, sObjectDataManager: self.viewModel.sObjectDataManager)
        }.alert(isPresented: $logoutAlertPresented, content: {
            Alert(title: Text("Are you sure you want to log out?"),
                  primaryButton: .destructive(Text("Logout"), action: {
                      UserAccountManager.shared.logout()
                  }),
                  secondaryButton: .cancel())
        })
    }
}

struct NotificationBell: View {
    @ObservedObject var notificationModel: NotificationListModel
    var sObjectDataManager: SObjectDataManager

    var body: some View {
        NavigationLink(destination: NotificationList(model: notificationModel, sObjectDataManager: sObjectDataManager)) {
            ZStack {
                Image(systemName: "bell.fill").frame(width: 20, height: 30, alignment: .center)
                if notificationModel.unreadCount() > 0 {
                    ZStack {
                        Circle().foregroundColor(.red)
                        Text("\(notificationModel.unreadCount())").foregroundColor(.white).font(Font.system(size: 12))
                    }
                    .frame(width: 12, height: 12)
                    .position(x: 15, y: 10)
                }
              }
              .frame(width: 20, height: 30)
        }
    }
}

struct ContactCell: View {
    var contact: ContactSObjectData

    var body: some View {
        HStack {
            Image(uiImage: ContactHelper.initialsImage(ContactHelper.colorFromContact(contact), initials: ContactHelper.initialsStringFromContact(contact))!)
            VStack(alignment: .leading) {
                Text(ContactHelper.nameStringFromContact(contact)).font(.appRegularFont(16))
                Text(ContactHelper.titleStringFromContact(contact)).font(.appRegularFont(12)).foregroundColor(.secondaryLabelText)
            }
            Spacer()
            if SObjectDataManager.dataLocallyUpdated(contact) {
                Image(systemName: "arrow.2.circlepath").foregroundColor(.appBlue)
            }
            if SObjectDataManager.dataLocallyCreated(contact) {
                Image(systemName: "plus").foregroundColor(.appBlue)
            }
        }
        .padding([.all], 10)
    }
}

struct SearchBar: UIViewRepresentable {
    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
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
