//
//  NativeLogin.swift
//  iOSNativeLoginTemplate
//
//  Created by Eric C. Johnson <Johnson.Eric@Salesforce.com> on 20240314.
//  Copyright (c) 2023-present, salesforce.com, inc. All rights reserved.
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

import SalesforceSDKCore
import SwiftUI

struct NativeRequestOtpView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var reCaptchaClientObservable: ReCaptchaClientObservable
    
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    @State private var otpVerificationMethod = OtpVerificationMethod.sms
    @State private var username = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack { Spacer() }
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.25))
                    .frame(width: 300, height: 450)
                    .padding(.top, 0)
                VStack {
                    Image(.msdkPhone)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 50)
                        .shadow(color: .black, radius: 3)
                        .blur(radius: 0.0)
                    
                    if isAuthenticating {
                        ProgressView()
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .frame(width: 250, height: 50)
                    } else {
                        Spacer().frame(width: 250, height: 65)
                    }
                    
                    TextField("Username", text: $username)
                        .foregroundColor(.blue)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.center)
                        .buttonStyle(.borderless)
                        .autocapitalization(.none)
                        .frame(maxWidth: 250)
                        .padding(.top, 25)
                        .zIndex(2.0)
                    
                    Picker(
                        "OTP Verification Method",
                        selection: $otpVerificationMethod) {
                            Text("Email").tag(OtpVerificationMethod.email)
                            Text("SMS").tag(OtpVerificationMethod.sms)
                        }
                        .frame(maxWidth: 250)
                        .zIndex(2.0)
                    
                    Button {
                        errorMessage = ""
                        self.isAuthenticating = true
                        
                        // Execute for a new reCAPTCHA token.
                        reCaptchaClientObservable.reCaptchaClient?.execute(withAction: .login) {token, error in
                            
                            print(token ?? error?.localizedDescription ?? "Could not obtain a reCAPTCHA token and no error description was provided.")
                            
                            //                            let result = await SalesforceManager.shared.nativeLoginManager()
                            //                                .login(username: username, password: password)
                            //                            self.isAuthenticating = false
                            //
                            //                            switch result {
                            //                            case .invalidCredentials:
                            //                                errorMessage = "Please check your username and password."
                            //                                break
                            //                            case .invalidUsername:
                            //                                errorMessage = "Username format is incorrect."
                            //                                break
                            //                            case .invalidPassword:
                            //                                errorMessage = "Invalid password."
                            //                                break
                            //                            case .unknownError:
                            //                                errorMessage = "An unknown error has occurred."
                            //                                break
                            //                            case .success:
                            //                                self.password = ""
                            //                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "key.radiowaves.forward")
                            Text("Request One-Time-Passcode")
                        }.frame(minWidth: 150)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .zIndex(2.0)
                }.padding(.bottom, 0)
            }
            
            Spacer()
        }.background(Gradient(colors: [.blue, .cyan, .green]).opacity(0.6))
            .blur(radius: self.isAuthenticating ? 2.0 : 0.0)
    }
}

#Preview {
    NativeRequestOtpView()
}
