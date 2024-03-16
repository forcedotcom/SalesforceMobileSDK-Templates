//
//  NativeLogin.swift
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

import SwiftUI
import SalesforceSDKCore

///
/// A view enabling the user to complete the Salesforce Identity API's "Headless Passwordless Login Flow for
/// Public Clients."  This view corresponds to the `services/oauth2/authorize` endpoint by collecting
/// the one-time-passcode previously delivered to the user, then generating the authorization request.  Also,
/// the `services/oauth2/token` endpoint will be used to complete the login flow.
///
/// The implementation of the API endpoint's client is provided by Salesforce Mobile SDK in the native login
/// manager.
///
/// On receiving a successful response from the endpoints, the user will be authenticated by Salesforce Mobile
/// SDK and returned to the app's views.
///

struct NativeSubmitOtpView: View {
    @Environment(\.colorScheme) var colorScheme
    
    /// An error message displayed to the user when needed.
    @State private var errorMessage = ""
    
    /// An authenticating state to determine the progress indicator.
    @State private var isAuthenticating = false
    
    /// The user's entered one-time-passcode.
    @State private var otp = ""
    
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
                    
                    TextField("One-Time-Passcode", text: $otp)
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
                    .tint(.blue)
                    .zIndex(2.0)
                }
            }
            
            Spacer()
        }
        .background(
            Gradient(colors: [.blue, .cyan, .green]).opacity(0.6)
        )
        .blur(radius: isAuthenticating ? 2.0 : 0.0)
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
        // Reset the error message if needed.
        errorMessage = ""
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Submit the request and act on the response.
        Task {
            // Guards.
            guard let otpIdentifier = otpIdentifier else { return }
            guard let otpVerificationMethod = otpVerificationMethod else { return }
            
            // Submit the request.
            let _ = await SalesforceManager.shared.nativeLoginManager()
                .submitPasswordlessAuthorizationRequest(
                    otp: otp,
                    otpIdentifier: otpIdentifier,
                    otpVerificationMethod: otpVerificationMethod)
            
            // Clear the progresss indicator.
            isAuthenticating = false
        }
    }
}

#Preview {
    NativeSubmitOtpView()
}
