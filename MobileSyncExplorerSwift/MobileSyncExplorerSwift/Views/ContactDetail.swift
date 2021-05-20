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
        VStack(alignment: .leading, spacing: 3) {
            Text(fieldName).font(.subheadline).foregroundColor(.secondaryLabelText)
            Text(fieldValue ?? "")
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
                .keyboardType(.numberPad)
            TextField("Home Phone", text: $contact.homePhone.bound)
                .keyboardType(.numberPad)
            TextField("Job Title", text: $contact.title.bound)
            TextField("Email Address", text: $contact.email.bound)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
                .autocapitalization(.none)
            TextField("Department", text: $contact.department.bound)
        }
    }
}

struct ContactDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: ContactDetailViewModel
    @State private var isEditing: Bool = false
    private var onAppearAction: () -> Void = {}
    private var dismissAction: () -> Void = {}

    init(contactId: String, sObjectDataManager: SObjectDataManager, onAppear: @escaping () -> Void) {
        self.viewModel = ContactDetailViewModel(contactId: contactId, sObjectDataManager: sObjectDataManager)
        self.onAppearAction = onAppear
    }

    init(contact: ContactSObjectData?, sObjectDataManager: SObjectDataManager) {
        self.viewModel = ContactDetailViewModel(contact: contact, sObjectDataManager: sObjectDataManager)
        if viewModel.isNewContact {
            self._isEditing = State(initialValue: true)
        }
    }
    
    init(contact: ContactSObjectData, sObjectDataManager: SObjectDataManager, dismiss: @escaping () -> Void) {
        self.viewModel = ContactDetailViewModel(contact: contact, sObjectDataManager: sObjectDataManager)
        self.dismissAction = dismiss
    }

    var body: some View {
        VStack {
            if isEditing {
                EditView(contact: $viewModel.contact)
            } else {
                ReadView(contact: viewModel.contact)
            }
            Spacer()
            DeleteButton(label: viewModel.deleteButtonTitle(), isDisabled: viewModel.isNewContact) {
                self.viewModel.deleteButtonTapped()
                self.presentationMode.wrappedValue.dismiss()
            }
        }.onAppear {
            self.onAppearAction()
        }
        .navigationBarTitle(Text(viewModel.title), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            Button(action: {
                if self.isEditing {
                    withAnimation {
                       self.isEditing.toggle()
                    }
                } else {
                    self.presentationMode.wrappedValue.dismiss()
                    self.dismissAction()
                }
            }, label: {
                if self.isEditing {
                    Text("Cancel")
                } else {
                    HStack {
                        Image("backArrow")
                            .renderingMode(.template)
                        Text("Back")
                    }
                }
            }), trailing:
            Button(action: {
                if self.isEditing {
                    self.viewModel.saveButtonTapped()
                    if self.viewModel.isNewContact {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                withAnimation {
                   self.isEditing.toggle()
                }
            }, label: {
                self.isEditing ? Text("Save") : Text("Edit")
            })
        )
    }
}

struct DeleteButton: View {
    let label: String
    let isDisabled: Bool
    let action: () -> ()
    
    func buttonBackground() -> Color {
        isDisabled ? Color.disabledDestructiveButton : Color.destructiveButton
    }

    var body: some View {
        Button(action: {
            self.action()
        }, label: {
            Text(label)
            .frame(width: 350, height: 50, alignment: .center)
            .background(buttonBackground())
            .foregroundColor(.white)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(buttonBackground(), lineWidth: 1))
            .padding([.bottom], 10)
        }).disabled(isDisabled)
    }
}
