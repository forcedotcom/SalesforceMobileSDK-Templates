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
    
    /// The reCAPTCHA client used to obtain reCAPTCHA tokens when needed for Salesforce Headless Identity API requests
    @EnvironmentObject var reCaptchaClientObservable: ReCaptchaClientObservable
    
    /// The layout type for the user's active identity flow, such as registration, forgot password or login
    @State private var identityFlowLayoutType = IdentityFlowLayoutType.LoginViaUsernamePassword
    
    /// An error message displayed to the user.  Note this is used by multiple layout types
    @State private var errorMessage = ""
    
    /// An option to display indicators when an identity action is in progress. Note this is used by multiple layout types
    @State private var isAuthenticating = false
    
    /// The user's entered username.  Note this is used by multiple layout types
    @State private var username = ""
    
    /// The user's entered password.  Note this is used by multiple layout types
    @State private var password = ""
    
    /// Password-Less Login Via One-Time-Passcode: The user's entered one-time-passcode
    @State private var otp = ""
    
    /// Password-Less Login Via One-Time-Passcode:  The OTP identifier returned by the Salesforce Identity API's initialize headless login endpoint
    @State private var otpIdentifier: String? = nil
    
    /// Password-Less Login Via One-Time-Passcode: The user's chosen OTP verification method of email or SMS
    @State private var otpVerificationMethod = OtpVerificationMethod.sms
    
    var body: some View {
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
                    .frame(width: 300, height: 500)
                    .padding(.top, 0)
                
                VStack {
                    Image(.msdkPhone)
                        .resizable()
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 20)
                        .shadow(color: .black, radius: 3)
                        .blur(radius: 0.0)
                    
                    if isAuthenticating {
                        ProgressView()
                    } else {
                        Spacer().frame(height: 35)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .frame(width: 250, height: 50)
                    } else {
                        Spacer().frame(width: 250, height: 65)
                    }
                    
                    // Switch the layout to match the selected identity flow.
                    switch(identityFlowLayoutType) {
                        
                    case .LoginViaUsernamePassword:
                        TextField("Username", text: $username)
                            .foregroundColor(.blue)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.center)
                            .buttonStyle(.borderless)
                            .autocapitalization(.none)
                            .frame(maxWidth: 250)
                            .padding(.top)
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
                                isAuthenticating = true
                                
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
                                    password = ""
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lock")
                                Text("Log In")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        .padding(.bottom, 25)
                        
                        Button {
                            identityFlowLayoutType = .InitializePasswordLessLoginViaOtp
                        } label: {
                            Text("Use One Time Password Instead").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                    case .InitializePasswordLessLoginViaOtp:
                        // Layout to initialize password-less login by requesting a one-time-passcode.
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
                            onRequestOtpTapped()
                        } label: {
                            HStack {
                                Image(systemName: "key.radiowaves.forward")
                                Text("Request One Time Password")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            identityFlowLayoutType = .LoginViaUsernamePassword
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                        
                    case .LoginViaUsernameAndOtp:
                        // Layout for password-less login by submitting a previously requested one-time-passcode.
                        TextField("One Time Password", text: $otp)
                            .autocapitalization(.none)
                            .buttonStyle(.borderless)
                            .disableAutocorrection(true)
                            .foregroundColor(.blue)
                            .frame(maxWidth: 250)
                            .multilineTextAlignment(.center)
                            .padding(.top, 25)
                            .zIndex(2.0)
                        
                        Button {
                            onSubmitOtpTapped()
                        } label: {
                            HStack {
                                Image(systemName: "lock")
                                Text("Log In Using OTP")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            identityFlowLayoutType = .LoginViaUsernamePassword
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.bottom, 125)
            
            // Fallback to webview based authentication.
            Button("Looking for Salesforce Log In?") {
                SalesforceManager.shared.nativeLoginManager().fallbackToWebAuthentication()
            }.tint(colorScheme == .dark ? .white : .blue)
        }.background(Gradient(colors: [.blue, .cyan, .green]).opacity(0.6))
            .blur(radius: isAuthenticating ? 2.0 : 0.0)
    }
    
    ///
    /// Submits the OTP delivery request when the request button is tapped.  This submits a request to the
    /// `init/passwordless/login`endpoint and opens the submit OTP verification view on success.
    ///
    private func onRequestOtpTapped() {
        // Reset the error message if needed.
        errorMessage = ""
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Execute for a new reCAPTCHA token.
        reCaptchaClientObservable.reCaptchaClient?.execute(withAction: .login) {reCaptchaExecuteResult, error in
            
            // Guard for the new reCAPTCHA token.
            guard let reCaptchaToken = reCaptchaExecuteResult else {
                SalesforceLogger.e(AppDelegate.self, message: "Could not obtain a reCAPTCHA token due to error with description '\(error?.localizedDescription ?? "(A description wasn't provided.)")'.")
                return
            }
            
            // Submit the request and act on the response.
            Task {
                // Submit the request.
                let result = await SalesforceManager.shared.nativeLoginManager()
                    .submitOtpRequest(
                        username: username,
                        reCaptchaToken: reCaptchaToken,
                        otpVerificationMethod: otpVerificationMethod)
                
                // Clear the progresss indicator.
                isAuthenticating = false
                
                // Act on the response.
                switch result.nativeLoginResult {
                    
                case .invalidCredentials:
                    errorMessage = "Check your username and password."
                    break
                    
                case .invalidPassword:
                    errorMessage = "Invalid password."
                    break
                    
                case .invalidUsername:
                    errorMessage = "Invalid username."
                    break
                    
                case .unknownError:
                    errorMessage = "An error occurred."
                    break
                    
                case .success:
                    // Verify parameters.
                    guard let otpIdentifierResult = result.otpIdentifier else { return }
                    
                    // Switch to the OTP submission layout.
                    otpIdentifier = otpIdentifierResult
                    identityFlowLayoutType = .LoginViaUsernameAndOtp
                }
            }
        }
    }
    
    ///
    /// Submits the OTP verification request when the request button is tapped.  This submits a request to
    /// the `services/oauth2/authorize`endpoint and in turn the `services/oauth2/token`
    /// endpoint.
    ///
    /// On receiving a successful response from the endpoints, the user will be authenticated by Salesforce
    /// Mobile SDK and returned to the app's views.
    ///
    private func onSubmitOtpTapped() {
        
        guard let otpIdentifier = otpIdentifier else { return }
        
        // Reset the error message if needed.
        errorMessage = ""
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Submit the request and act on the response.
        Task {
            // Submit the request.
            let result = await SalesforceManager.shared.nativeLoginManager()
                .submitPasswordlessAuthorizationRequest(
                    otp: otp,
                    otpIdentifier: otpIdentifier,
                    otpVerificationMethod: otpVerificationMethod)
            
            // Clear the progresss indicator.
            isAuthenticating = false
            
            switch result {
            case .success:
                // Switch back to the initial login layout.
                identityFlowLayoutType = .LoginViaUsernamePassword
                break
            default:
                errorMessage = "An error occurred."
            }
        }
    }
    
}

///
/// Layouts for the available Salesforce identity flows.
///
enum IdentityFlowLayoutType {
    
    /// A layout to initialize password-less login via one-time-passcode request.
    case InitializePasswordLessLoginViaOtp
    
    /// A layout for authorization code and credentials flow via username and previously requested one-time-passcode.
    case LoginViaUsernameAndOtp
    
    /// A layout for authorization code and credentials flow via username and password
    case LoginViaUsernamePassword
}

#Preview {
    NativeLoginView()
}
