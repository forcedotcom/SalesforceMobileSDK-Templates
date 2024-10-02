//
//  ContactDetail.swift
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
import SalesforceSDKCore

struct ReadView: View {
    var contact: ContactSObjectData

    var body: some View {
        List {
            ReadViewField(fieldName: "First Name", fieldValue: contact.firstName)
            ReadViewField(fieldName: "Last Name", fieldValue: contact.lastName)
            ReadViewField(fieldName: "Mobile Phone", fieldValue: contact.mobilePhone)
            ReadViewField(fieldName: "Home Phone", fieldValue: contact.homePhone)
            ReadViewField(fieldName: "Job Title", fieldValue: contact.title)
            ReadViewField(fieldName: "Email Address", fieldValue: contact.email)
            ReadViewField(fieldName: "Department", fieldValue: contact.department)
        }
    }
}

struct ReadViewField: View {
    var fieldName: String
    var fieldValue: String?

    var body: some View {
        if let value = fieldValue {
            VStack(alignment: .leading, spacing: 3) {
                Text(fieldName).font(.subheadline).foregroundColor(.secondaryLabelText)
                Text(value)
            }
        }
    }
}

struct EditView: View {
    @Binding var contact: ContactSObjectData

    var body: some View {
        Form {
            TextField("First Name", text: $contact.firstName.bound)
                .disableAutocorrection(true)
            TextField("Last Name", text: $contact.lastName.bound)
                .disableAutocorrection(true)
            TextField("Mobile Phone", text: $contact.mobilePhone.bound)
                .keyboardType(.phonePad)
            TextField("Home Phone", text: $contact.homePhone.bound)
                .keyboardType(.phonePad)
            TextField("Job Title", text: $contact.title.bound)
            TextField("Email Address", text: $contact.email.bound)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
                .autocapitalization(.none)
            TextField("Department", text: $contact.department.bound)
        }
    }
}

struct ContactButton: View {
    let value: String?
    let urlScheme: String
    let imageName: String
    
    var fullURL: URL? {
        if let value = value,
           let url = URL(string: "\(urlScheme):\(value)") {
            return url
        }
        return nil
    }
    
    var isDisabled: Bool {
        if let fullURL = fullURL, UIApplication.shared.canOpenURL(fullURL) {
            return false
        }
        return true
    }
    
    var body: some View {
        Button(action: {
            if let fullURL {
                UIApplication.shared.open(fullURL)
            }
        }, label: {
            Image(systemName: imageName)
                .font(.largeTitle)
                .padding()
        })
        .disabled(isDisabled)
    }
}

struct LeadingNavBarButtons: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ContactDetailViewModel
    
    var body: some View {
        if viewModel.isEditing && viewModel.isNewContact {
            Button(role: .cancel, action: {
                withAnimation {
                    if viewModel.isNewContact {
                        self.presentationMode.wrappedValue.dismiss()
                    } else {
                        viewModel.isEditing.toggle()
                    }
                }
            }, label: {
                Text("Cancel")
            })
        } else {
            EmptyView()
        }
    }
}

struct ContactDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: ContactDetailViewModel
    private var onAppearAction: () -> Void = {}
    private var onSaveAction: ((ContactSObjectData.ID?) -> Void)?
    
    init(id: String, sObjectDataManager: SObjectDataManager, onAppear: @escaping () -> Void) {
        self.viewModel = ContactDetailViewModel(id: id, sObjectDataManager: sObjectDataManager)
        self.onAppearAction = onAppear
    }
    
    init(sObjectDataManager: SObjectDataManager) {
        self.viewModel = ContactDetailViewModel(sObjectDataManager: sObjectDataManager)
    }

    init(localId: ContactSObjectData.ID?, sObjectDataManager: SObjectDataManager, onSave: ((ContactSObjectData.ID?) -> Void)? = nil) {
        self.viewModel = ContactDetailViewModel(localId: localId, sObjectDataManager: sObjectDataManager)
        self.onSaveAction = onSave
    }

    var body: some View {
        VStack {
            if viewModel.isEditing {
                EditView(contact: $viewModel.contact)
            } else {
                VStack {
                    ReadView(contact: viewModel.contact)
                    Spacer()
                    HStack(alignment: .center) {
                        ContactButton(value: viewModel.contact.mobilePhone, urlScheme: "facetime", imageName: "video.fill")
                        ContactButton(value: viewModel.contact.email, urlScheme: "mailto", imageName: "envelope.fill")
                        ContactButton(value: viewModel.contact.mobilePhone, urlScheme: "sms", imageName: "message.fill")
                    }
                    .background(Color(uiColor: .systemBackground).clipShape(RoundedRectangle(cornerRadius:20)))
                    .padding()
                    .padding(.bottom)
                }.background(Color(UIColor.secondarySystemBackground))
            }
        }.onAppear {
            self.onAppearAction()
        }
        .navigationBarTitle(Text(viewModel.title), displayMode: .large)
        .navigationBarBackButtonHidden(viewModel.isEditing)
        .navigationBarItems(
            leading: LeadingNavBarButtons(viewModel: viewModel),
            trailing:
                HStack {
                    if !viewModel.isEditing {
                        Button(action: {
                            self.viewModel.deleteButtonTapped()
                        }, label: {
                            Text("\(viewModel.deleteButtonTitle())")
                                .foregroundStyle(.red)
                        })
                    } else if !viewModel.isNewContact {
                        Button(role: .cancel, action: {
                            withAnimation {
                                if viewModel.isNewContact {
                                    self.presentationMode.wrappedValue.dismiss()
                                } else {
                                    viewModel.loadContact(id: viewModel.contact.id)
                                    viewModel.isEditing.toggle()
                                }
                            }
                        }, label: {
                            Text("Cancel")
                        })
                    }
                    
                    Button(action: {
                        if viewModel.isEditing {
                            let id = viewModel.saveButtonTapped()
                            onSaveAction?(id)
                        }
                        withAnimation {
                            viewModel.isEditing.toggle()
                            if viewModel.isNewContact {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                            
                        }
                    }, label: {
                        viewModel.isEditing ? Text("Save") : Text("Edit")
                    })
                }
        )
    }
}

#Preview {
    let credentials = OAuthCredentials(identifier: "test", clientId: "", encrypted: false)!
    let userAccount = UserAccount(credentials: credentials)
    let sObjectManager = SObjectDataManager.sharedInstance(for: userAccount)
    
    return ContactDetailView(id: "", sObjectDataManager: sObjectManager, onAppear: {})
}
