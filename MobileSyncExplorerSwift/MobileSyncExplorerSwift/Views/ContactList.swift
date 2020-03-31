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
import Combine

struct ContactListView: View {
    @ObservedObject private var sObjectDataManager: SObjectDataManager = SObjectDataManager(dataSpec: ContactSObjectData.dataSpec()!)
    @State private var searchTerm: String = ""
    @State private var dim = false

    init() {
        self.sObjectDataManager.syncUpDown()
    }

    func contactMatchesSearchTerm(contact: ContactSObjectData, searchTerm: String) -> Bool {
        let dataSpec: SObjectDataSpec? = ContactSObjectData.dataSpec()
        if let dataSpec = dataSpec {
            for fieldSpec in dataSpec.objectFieldSpecs where fieldSpec.isSearchable {
                let fieldValue = contact.fieldValue(forFieldName: fieldSpec.fieldName) as? String
                if let fieldValue = fieldValue {
                    if let _ = fieldValue.range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive], range: fieldValue.startIndex..<fieldValue.endIndex, locale: nil) {
                        return true
                    }
                }
            }
        }
        return false
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    Section(header: SearchBar(text: self.$searchTerm).listRowInsets(EdgeInsets())) {
                        ForEach(sObjectDataManager.contacts.filter { contact in
                            self.searchTerm.isEmpty ? true : self.contactMatchesSearchTerm(contact: contact, searchTerm: self.searchTerm)
                        }) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact, sObjectDataManager: self.sObjectDataManager)) {
                                ContactCell(contact: contact)
                            }
                            .listRowBackground(SObjectDataManager.dataLocallyDeleted(contact) ? Color.contactCellDeletedBackground : Color.clear)
                        }
                    }
                }
                .id(UUID())

                if sObjectDataManager.syncing {
                    SyncAlert(syncMessage: sObjectDataManager.syncMessage)
                }
            }
            .navigationBarTitle("MobileSync Explorer")
            .navigationBarItems(trailing: NavBarButtons(sObjectDataManager: sObjectDataManager))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SyncAlert: View {
    var syncMessage: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            VStack {
                Text("Syncing").bold()
                Text(syncMessage)
            }
            .frame(width: 250, height: 100)
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
    var sObjectDataManager: SObjectDataManager
    @State private var modalPresented: ModalAction?
    @State private var newContactPresented = false
    @State private var actionSheetPresented = false
    @State private var logoutAlertPresented = false

    var body: some View {
        HStack {
            NavigationLink(destination: ContactDetailView(contact: nil, sObjectDataManager: self.sObjectDataManager), isActive: $newContactPresented, label: { EmptyView() })
            Button(action: {
                self.newContactPresented = true
            }, label: { Image("plusButton") })
            Button(action: {
                self.sObjectDataManager.syncUpDown()
            }, label: { Image("sync") })
            Button(action: {
                self.actionSheetPresented = true
            }, label: { Image("setting") })
                .actionSheet(isPresented: $actionSheetPresented) {
                 ActionSheet(title: Text("Additional Actions"), buttons: [
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
                    InspectorViewControllerWrapper(store: self.sObjectDataManager.store)
                } else if creationType == ModalAction.switchUser {
                    SalesforceUserManagementViewControllerWrapper()
                }
            }
        }.alert(isPresented: $logoutAlertPresented, content: {
            Alert(title: Text("Are you sure you want to log out?"),
                  primaryButton: .destructive(Text("Logout"), action: {
                      UserAccountManager.shared.logout()
                  }),
                  secondaryButton: .cancel())
        })
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
        let searchBar = UISearchBar(frame: .zero)
        searchBar.placeholder = "Search"
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar,
                      context: UIViewRepresentableContext<SearchBar>) {
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
