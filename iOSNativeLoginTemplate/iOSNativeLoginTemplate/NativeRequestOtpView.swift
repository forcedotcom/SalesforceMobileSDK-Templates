//
//  NativeRequestOtpView.swift
//  iOSNativeLoginTemplate
//
//  Created by Eric C. Johnson <Johnson.Eric@Salesforce.com> on 20240314.
//  Copyright (c) 2024-present, salesforce.com, inc. All rights reserved.
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

///
/// A view enabling the user to start the Salesforce Identity API's "Headless Passwordless Login Flow for
/// Public Clients."  This view corresponds to the `init/passwordless/login` endpoint by collecting
/// a Salesforce username and the user's chosen OTP verification method of email or SMS.
///
/// The implementation of the API endpoint's client is provided by Salesforce Mobile SDK in the native login
/// manager.
///
/// On receiving a successful response from the endpoint, a separate view is used to finish the flow.
///
struct NativeRequestOtpView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    /// The Google reCAPTCHA client.
    @EnvironmentObject var reCaptchaClientObservable: ReCaptchaClientObservable
    
    /// The navigation path.
    @EnvironmentObject var navigationPathObservable: NavigationPathObservable
    
    /// An error message displayed to the user when needed.
    @State private var errorMessage = ""
    
    /// An authenticating state to determine the progress indicator.
    @State private var isAuthenticating = false
    
    /// The user's chosen OTP verification method of email or SMS.
    @State private var otpVerificationMethod = OtpVerificationMethod.sms
    
    /// The user's entered username.
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
                        .blur(radius: 0.0)
                        .frame(width: 150, height: 150)
                        .padding(.bottom, 50)
                        .shadow(color: .black, radius: 3)
                    
                    if isAuthenticating {
                        ProgressView()
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .frame(width: 250, height: 50)
                            .foregroundStyle(.red)
                    } else {
                        Spacer().frame(width: 250, height: 65)
                    }
                    
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
                            Text("Request One-Time-Passcode")
                        }.frame(minWidth: 150)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .zIndex(2.0)
                }
            }
            
            Spacer()
            
            // Check Native Login Manager to see if the "back to app" (cancel login) button should be shown.
            if (SalesforceManager.shared.nativeLoginManager().shouldShowBackButton()) {
                Button {
                    // Pop to the navigation root to reset login experience.
//                    navigationPathObservable.navigationPath.removeAll()
                    
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
                print("Could not obtain a reCAPTCHA token due to error with description '\(error?.localizedDescription ?? "(A description wasn't provided.)")'.")
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
                    guard let otpIdentifier = result.otpIdentifier else { return }
//                    navigationPathObservable.navigationPath.append(
//                        .NativeSubmitOtpView(
//                            otpIdentifier: otpIdentifier,
//                            otpVerificationMethod: otpVerificationMethod))
                }
            }
        }
    }
}

#Preview {
    NativeRequestOtpView()
}
