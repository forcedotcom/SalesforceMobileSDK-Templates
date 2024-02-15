/*
Copyright (c) 2019-present, salesforce.com, inc. All rights reserved.

Redistribution and use of this software in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of
conditions and the following disclaimer in the documentation and/or other materials provided
with the distribution.
* Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
endorse or promote products derived from this software without specific prior written
permission of salesforce.com, inc.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


import Foundation
import SwiftUI
import Combine
import SalesforceSDKCore

struct FieldView: View {
    var label: String
    var value: String?
    
    var body: some View {
        return HStack(spacing: 10){
            VStack(alignment: .leading, spacing: 3) {
                Text(value ?? "None listed")
                Text(label).font(.subheadline).italic()
            }
        }
    }
}

struct AddressView: View {
    var contact: Contact
    
    var body: some View {
        return HStack(spacing: 10){
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 10) {
                    Text(contact.MailingStreet ?? "")
                    Text(contact.MailingCity ?? "")
                    Text(contact.MailingState ?? "")
                    Text(contact.MailingPostalCode ?? "")
                }
                Text("Address").font(.subheadline).italic()
            }
        }
    }
}

struct ContactDetailView: View {
    var contact: Contact
    
    var body: some View {
        return List {
            FieldView(label: "First Name", value: contact.FirstName)
            FieldView(label: "Last Name", value: contact.LastName)
            FieldView(label: "Email", value: contact.Email)
            FieldView(label: "Phone Number", value: contact.PhoneNumber)
            AddressView(contact: contact)
        }
    }
}

struct ContactDetailView_Previews: PreviewProvider {
  static var previews: some View {
    ContactDetailView(contact: Contact(
        Id: "123456",
        FirstName: "Astro",
        LastName: "Nomical",
        PhoneNumber: "9198675309",
        Email: "Astro.Nomical@gmail.com",
        MailingStreet: "123 Sessame St",
        MailingCity: "Sunny Days",
        MailingState: "NJ",
        MailingPostalCode: "12345"
    ))
  }
}
