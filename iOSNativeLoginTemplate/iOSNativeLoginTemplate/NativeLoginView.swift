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
    
    /// The active native login flow.
    @State private var navigationDestination = NavigationDestination.NativeLoginView
    
    /// The user's chosen OTP verification method of email or SMS.
    @State private var otpVerificationMethod = OtpVerificationMethod.sms
    
    var body: some View {
        NavigationStack(path: $navigationPathObservable.navigationPath) {
            VStack {
                Spacer()
                
                HStack {Spacer()}
                
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
                        
                        switch(navigationDestination) {
                            
                        case .NativeLoginView:
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
                            
                        case .NativeRequestOtpView:
                            TextField("Username", text: $username)
                                .autocapitalization(.none)
                                .buttonStyle(.borderless)
                                .disableAutocorrection(true)
                                .foregroundColor(.blue)
                                .frame(maxWidth: 250)
                                .multilineTextAlignment(.center)
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
//                                onRequestOtpTapped()
                            } label: {
                                HStack {
                                    Image(systemName: "key.radiowaves.forward")
                                    Text("Request One-Time-Passcode")
                                }.frame(minWidth: 150)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .zIndex(2.0)
                            
                        default:
                            Text("...")
                        }
                    
                    // Other login options.
                    Button {
//                        navigationPathObservable.navigationPath.append(.NativeRequestOtpView)
                        navigationDestination = .NativeRequestOtpView
                    } label: {
                        Text("Use Passcode Instead").frame(minWidth: 150)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Spacer()
                    
                    // Fallback to webview based authentication.
                    Button("Looking for Salesforce Log In?") {
                        SalesforceManager.shared.nativeLoginManager().fallbackToWebAuthentication()
                    }
                    
                    // Check Native Login Manager to see if the "back to app" (cancel login) button should be shown.
                    if (SalesforceManager.shared.nativeLoginManager().shouldShowBackButton()) {
                        Button {
                            // Pop to the navigation root to reset login experience.
//                            navigationPathObservable.navigationPath.removeAll()
//                            navigationPathObservable.navigationPath.append(.NativeLoginView)
                            
                            // Salesforce Mobile SDK's native login manager provides the cancel authentication logic, plus dismisses the login view so the user returns to the app.
                            SalesforceManager.shared.nativeLoginManager().cancelAuthentication()
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Spacer().frame(height: 30)
                    }
                }
                .background(
                    Gradient(colors: [.blue, .cyan, .green]).opacity(0.6)
                )
                .blur(radius: self.isAuthenticating ? 2.0 : 0.0)
                .navigationDestination(for: NavigationDestination.self) { navigationDestination in
                    switch (navigationDestination) {
                        
                    case .NativeLoginView:
                        self
                        
                    case .NativeRequestOtpView:
                        NativeRequestOtpView()
                        
                    case .NativeSubmitOtpView (
                        let otpIdentifier,
                        let otpVerificationMethod
                    ):
                        NativeSubmitOtpView(
                            otpIdentifier: otpIdentifier,
                            otpVerificationMethod: otpVerificationMethod)
                    }
                }
//                
//                ///
//                /// Submits the OTP delivery request when the request button is tapped.  This submits a request to the
//                /// `init/passwordless/login`endpoint and opens the submit OTP verification view on success.
//                ///
//                private func onRequestOtpTapped() {
//                    // Reset the error message if needed.
//                    errorMessage = ""
//                    
//                    // Show the progress indicator.
//                    isAuthenticating = true
//                    
//                    // Execute for a new reCAPTCHA token.
//                    reCaptchaClientObservable.reCaptchaClient?.execute(withAction: .login) {reCaptchaExecuteResult, error in
//                        
//                        // Guard for the new reCAPTCHA token.
//                        guard let reCaptchaToken = reCaptchaExecuteResult else {
//                            print("Could not obtain a reCAPTCHA token due to error with description '\(error?.localizedDescription ?? "(A description wasn't provided.)")'.")
//                            return
//                        }
//                        
//                        // Submit the request and act on the response.
//                        Task {
//                            // Submit the request.
//                            let result = await SalesforceManager.shared.nativeLoginManager()
//                                .submitOtpRequest(
//                                    username: username,
//                                    reCaptchaToken: reCaptchaToken,
//                                    otpVerificationMethod: otpVerificationMethod)
//                            
//                            // Clear the progresss indicator.
//                            isAuthenticating = false
//                            
//                            // Act on the response.
//                            switch result.nativeLoginResult {
//                                
//                            case .invalidCredentials:
//                                errorMessage = "Check your username and password."
//                                break
//                                
//                            case .invalidPassword:
//                                errorMessage = "Invalid password."
//                                break
//                                
//                            case .invalidUsername:
//                                errorMessage = "Invalid username."
//                                break
//                                
//                            case .unknownError:
//                                errorMessage = "An error occurred."
//                                break
//                                
//                            case .success:
//                                guard let otpIdentifier = result.otpIdentifier else { return }
//                                navigationPathObservable.navigationPath.append(
//                                    .NativeSubmitOtpView(
//                                        otpIdentifier: otpIdentifier,
//                                        otpVerificationMethod: otpVerificationMethod))
//                            }
//                        }
                    }
                }
            }
        }
    }
    
    ///
    /// The available navigation destinations.
    ///
    enum NavigationDestination: Hashable {
        
        /// A navigation destination for the login view.
        case NativeLoginView
        
        /// A navigation destination for the request one-time-passcode view.
        case NativeRequestOtpView
        
        /// A navigation destination for the submit one-time-passcode view.
        case NativeSubmitOtpView(
            /// The OTP identifier returned by the Salesforce Identity API initialize password-less login endpoint.
            otpIdentifier: String,
            
            /// The OTP verification method used when requesting the OTP and OTP identifier.
            otpVerificationMethod: OtpVerificationMethod
        )
    }
    
    #Preview {
        NativeLoginView()
    }
