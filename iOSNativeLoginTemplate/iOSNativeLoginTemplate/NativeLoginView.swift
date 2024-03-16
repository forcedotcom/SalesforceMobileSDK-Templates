//
//  NativeLogin.swift
//  SalesforceSDKCore
//
//  Created by Brandon Page on 12/18/23.
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

import SwiftUI
import SalesforceSDKCore

struct NativeLoginView: View {
    @Environment(\.colorScheme) var colorScheme
    
    /// The reCAPTCHA client used to obtain reCAPTCHA tokens when needed for Salesforce Headless Identity API requests.
    @EnvironmentObject var reCaptchaClientObservable: ReCaptchaClientObservable
    
    /// The navigation path.
    @EnvironmentObject var navigationPathObservable: NavigationPathObservable
    
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    
    var body: some View {
        NavigationStack(path: $navigationPathObservable.navigationPath) {
            VStack {
                Spacer()
                HStack {
                    
                    // Check Native Login Manager to see if back button should be shown.
                    if (SalesforceManager.shared.nativeLoginManager().shouldShowBackButton()) {
                        Button {
                            // Let Native Login Manager do all the work.
                            SalesforceManager.shared.nativeLoginManager().cancelAuthentication()
                        } label: {
                            Image(systemName: "arrowshape.backward.fill")
                                .resizable()
                                .frame(width: 30, height: 30, alignment: .topLeading)
                                .tint(colorScheme == .dark ? .white : .blue)
                                .opacity(0.5)
                        }
                        .frame(width: 30, height: 30, alignment: .topLeading)
                        .padding(.leading)
                        
                    } else {
                        Spacer().frame(height: 30)
                    }
                    Spacer()
                }
                
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
                        
                        SecureField("Password", text: $password)
                            .foregroundColor(.blue)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.center)
                            .buttonStyle(.borderless)
                            .autocapitalization(.none)
                            .frame(maxWidth: 250)
                            .padding(.bottom)
                            .padding(.top, 10)
                            .zIndex(2.0)
                        
                        Button {
                            Task {
                                errorMessage = ""
                                self.isAuthenticating = true
                                
                                // Login
                                let result = await SalesforceManager.shared.nativeLoginManager()
                                    .login(username: username, password: password)
                                self.isAuthenticating = false
                                
                                switch result {
                                case .invalidCredentials:
                                    errorMessage = "Please check your username and password."
                                    break
                                case .invalidUsername:
                                    errorMessage = "Username format is incorrect."
                                    break
                                case .invalidPassword:
                                    errorMessage = "Invalid password."
                                    break
                                case .unknownError:
                                    errorMessage = "An unknown error has occurred."
                                    break
                                case .success:
                                    self.password = ""
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lock")
                                Text("Log In")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .zIndex(2.0)
                    }.padding(.bottom, 0)
                }
                
                // Other login options.
                Button("Need to register, reset your password or login without a password?") {
                    navigationPathObservable.navigationPath.append("NativeRequestOtpView")
                }
                
                Spacer()
                
                // Fallback to webview based authentication.
                Button("Looking for Salesforce Log In?") {
                    SalesforceManager.shared.nativeLoginManager().fallbackToWebAuthentication()
                }
            }
            .background(
                Gradient(colors: [.blue, .cyan, .green]).opacity(0.6)
            )
            .blur(radius: self.isAuthenticating ? 2.0 : 0.0)
            .navigationDestination(for: String.self) { path in
                switch (path) {
                case "NativeRequestOtpView":
                    NativeRequestOtpView()
                    
                case "NativeSubmitOtpView":
                    NativeSubmitOtpView()
                    
                default:
                    NativeLoginView()
                }
            }
        }
    }
}

#Preview {
    NativeLoginView()
}
