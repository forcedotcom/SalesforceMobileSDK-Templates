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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @ObservedObject var viewModel: ContactListViewModel
    @ObservedObject private var notificationModel = NotificationListModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var searchTerm: String = ""
    
    init(sObjectManager: SObjectDataManager, selectedRecord: String? = nil, newContact: Bool = false, searchFocused: Bool = false) {
        self.viewModel = ContactListViewModel(sObjectDataManager: sObjectManager, presentNewContact: newContact, selectedRecord: selectedRecord)
    }
    
    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                List(viewModel.sObjectDataManager.contacts.filter { contact in
                    self.searchTerm.isEmpty ? true : self.viewModel.contactMatchesSearchTerm(contact: contact, searchTerm: self.searchTerm)
                },
                     selection: $viewModel.selectedRecord) { contact in
                    ContactCell(contact: contact)
                        .onDrag { return viewModel.itemProvider(contact: contact) }
                }
                .listStyle(.plain)
                .searchable(text: $searchTerm)
                .navigationTitle("Contacts")
                .toolbar(content: {
                    ToolbarItemGroup(placement: UIDevice.current.userInterfaceIdiom == .pad ? .topBarLeading : .topBarTrailing) {
                        Button(action: {
                            viewModel.newContactSelected()
                        }, label: { Image("plusButton").renderingMode(.template) })
                        Button(action: {
                            self.viewModel.syncUpDown()
                        }, label: { Image("sync").renderingMode(.template) })
                    }
                })
            } detail: {
                if let selectedRecord = viewModel.selectedRecord {
                    ContactDetailView(localId: selectedRecord, sObjectDataManager: self.viewModel.sObjectDataManager)
                } else {
                    Text("Select a Contact")
                }
            }
            .navigationSplitViewStyle(BalancedNavigationSplitViewStyle())
            .onAppear {
                self.notificationModel.fetchNotifications()
            }.sheet(isPresented: $viewModel.newContact, content: {
                NavigationStack {
                    ContactDetailView(localId: nil, sObjectDataManager: viewModel.sObjectDataManager) { newContactId in
                        viewModel.selectedRecord = newContactId
                    }
                }
            })
            if viewModel.alertContent != nil {
                StatusAlert(viewModel: viewModel)
            }
        }
        .onChange(of: viewModel.sObjectDataManager.contacts) { _, _ in
            // In two column splitview, select the first item in the list by default
            // if one isn't already selected or if the currently selected record is deleted
            if horizontalSizeClass != .compact && (viewModel.selectedRecord == nil || !viewModel.sObjectDataManager.contacts.contains(where: { record in
                record.id == viewModel.selectedRecord
            })) {
                viewModel.selectedRecord = viewModel.sObjectDataManager.contacts.first?.id
            }
        }
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
            Circle()
                .fill(Color(ContactHelper.colorFromContact(lastName: contact.lastName)))
                .frame(width: 45, height: 45)
                .overlay(
                    Text(ContactHelper.initialsStringFromContact(firstName: contact.firstName, lastName: contact.lastName))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading) {
                Text(ContactHelper.nameStringFromContact(firstName: contact.firstName, lastName: contact.lastName))
                    .font(.headline)
                    .foregroundColor(Color(UIColor.label))
                Text(ContactHelper.titleStringFromContact(title: contact.title))
                    .font(.subheadline)
                    .foregroundColor(.secondaryLabelText)
            }
            Spacer()
            if contact.locallyUpdated {
                Image(systemName: "arrow.2.circlepath").foregroundColor(.appBlue)
            }
            if contact.locallyCreated {
                Image(systemName: "plus")
                    .foregroundColor(.green)
            }
            if contact.locallyDeleted {
                Image(systemName: "trash").foregroundColor(.red)
            }
        }
        .padding([.all], 10)
    }
}

#Preview {
    let credentials = OAuthCredentials(identifier: "test", clientId: "", encrypted: false)!
    let userAccount = UserAccount(credentials: credentials)
    let sObjectManager = SObjectDataManager.sharedInstance(for: userAccount)
    
    return ContactListView(sObjectManager: sObjectManager)
}
