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
    @Binding var contactInput: ContactInput

    var body: some View {
        Form {
            TextField("First Name", text: $contactInput.firstName)
                .disableAutocorrection(true)
            TextField("Last Name", text: $contactInput.lastName)
                .disableAutocorrection(true)
            TextField("Mobile Phone", text: $contactInput.mobilePhone)
                .keyboardType(.numberPad)
            TextField("Home Phone", text: $contactInput.homePhone)
                .keyboardType(.numberPad)
            TextField("Job Title", text: $contactInput.title)
            TextField("Email Address", text: $contactInput.email)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
                .autocapitalization(.none)
            TextField("Department", text: $contactInput.department)
        }
    }
}

struct ContactInput {
    var firstName: String = ""
    var lastName: String = ""
    var mobilePhone: String = ""
    var homePhone: String = ""
    var title: String = ""
    var email: String = ""
    var department: String = ""

    init(contact: ContactSObjectData?) {
        if let firstName = contact?.firstName {
            self.firstName = firstName
        }
        if let lastName = contact?.lastName {
            self.lastName = lastName
        }
        if let mobilePhone = contact?.mobilePhone {
            self.mobilePhone = mobilePhone
        }
        if let homePhone = contact?.homePhone {
            self.homePhone = homePhone
        }
        if let title = contact?.title {
            self.title = title
        }
        if let email = contact?.email {
            self.email = email
        }
        if let department = contact?.department {
            self.department = department
        }
    }
}

struct ContactDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var contact: ContactSObjectData
    @State private var contactInput: ContactInput
    @State private var isEditing: Bool = false
    private var sObjectDataManager: SObjectDataManager<ContactSObjectData>
    private var isNewContact: Bool = false
    private var title: String

    init(contact: ContactSObjectData?, sObjectDataManager: SObjectDataManager<ContactSObjectData>) {
        self.sObjectDataManager = sObjectDataManager
        if let c = contact {
            self.title = ContactHelper.nameStringFromContact(c)
            self._contact = State(initialValue: c)
        } else {
            self.title = "New Contact"
            self.isNewContact = true
            self._isEditing = State(initialValue: true)
            self._contact = State(initialValue: ContactSObjectData())
        }
        self._contactInput = State(initialValue: ContactInput(contact: contact))
    }

    func saveInput() {
        contact.firstName = contactInput.firstName
        contact.lastName = contactInput.lastName
        contact.mobilePhone = contactInput.mobilePhone
        contact.homePhone = contactInput.homePhone
        contact.title = contactInput.title
        contact.email = contactInput.email
        contact.department = contactInput.department

        if self.isNewContact {
            sObjectDataManager.createLocalData(contact)
        } else {
            sObjectDataManager.updateLocalData(contact)
        }
    }
    func isLocallyDeleted() -> Bool {
        return SObjectDataManager<ContactSObjectData>.dataLocallyDeleted(contact)
    }

    var body: some View {
        VStack {
            if isEditing {
                EditView(contactInput: $contactInput)
            } else {
                ReadView(contact: contact)
            }
            Spacer()
            DeleteButton(label: isLocallyDeleted() ? "Undelete Contact" : "Delete Contact", isDisabled: isNewContact) {
                self.isLocallyDeleted() ? self.sObjectDataManager.undeleteLocalData(self.contact) : self.sObjectDataManager.deleteLocalData(self.contact)
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationBarTitle(Text(title), displayMode: .inline)
        .navigationBarItems(leading:
            Button(action: {
                if self.isEditing {
                    withAnimation {
                       self.isEditing.toggle()
                    }
                } else {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }, label: {
                if self.isEditing {
                    Text("Cancel")
                } else {
                    HStack {
                        Image("backArrow")
                        Text("Back")
                    }
                }
            }), trailing:
            Button(action: {
                if self.isEditing {
                    self.saveInput()
                    if self.isNewContact {
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
