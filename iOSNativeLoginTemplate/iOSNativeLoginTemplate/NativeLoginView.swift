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
    
    // MARK: reCAPTCHA Properties
    
    /// The reCAPTCHA client used to obtain reCAPTCHA tokens when needed for Salesforce Headless Identity API requests
    @EnvironmentObject var reCaptchaClientObservable: ReCaptchaClientObservable
    
    /// The layout type for the user's active identity flow, such as registration, forgot password or login
    @State private var identityFlowLayoutType = IdentityFlowLayoutType.Login
    
    // MARK: Start Registration Properties
    
    /// Start Registration: The user's entered first name.
    @State private var firstName = ""
    
    /// Start Registration: The user's entered email address.
    @State private var email = ""
    
    /// Start Registration: The user's entered last name.
    @State private var lastName = ""
    
    // MARK: Complete Registration
    
    /// Complete Registration:  The request identifier returned by the Salesforce Identity API's initialize registration endpoint
    @State private var requestIdentifier: String? = nil
    
    // MARK: User Messaging
    
    /// User Messaging: Indicates if the message displayed to the user is informational or an error.  Note this is used by multiple layout types
    @State private var isMessageError = false
    
    /// User Messaging: A message displayed to the user.  Note this is used by multiple layout types
    @State private var messageText = ""
    
    // MARK: Common User Interface State
    
    /// An option to display indicators when an identity action is in progress. Note this is used by multiple layout types
    @State private var isAuthenticating = false
    
    /// The user's entered one-time-passcode. Note this is used by multiple layout types
    @State private var otp = ""
    
    /// The OTP identifier returned by the Salesforce Identity API's initialize headless login endpoint. Note this is used by multiple layout types
    @State private var otpIdentifier: String? = nil
    
    /// Password-Less Login Via One-Time-Passcode: The user's chosen OTP verification method of email or SMS
    @State private var otpVerificationMethod = OtpVerificationMethod.sms
    
    /// The user's entered password.  Note this is used by multiple layout types
    @State private var password = ""
    
    /// The user's entered username.  Note this is used by multiple layout types
    @State private var username = ""
    
    // MARK: Layout
    
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
                    .frame(width: 300, height: 650)
                    .padding(.top, 0)
                
                VStack {
                    Image(.msdkPhone)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(.bottom, 10)
                        .shadow(color: .black, radius: 3)
                        .blur(radius: 0.0)
                    
                    if isAuthenticating {
                        ProgressView()
                    } else {
                        Spacer().frame(height: 35)
                    }
                    
                    if !messageText.isEmpty {
                        Text(messageText)
                            .foregroundStyle({switch(isMessageError) {
                            case true:
                                return Color.red
                            default:
                                return Color.blue
                            }}())
                            .frame(width: 250, height: 50)
                    } else {
                        Spacer().frame(width: 250, height: 65)
                    }
                    
                    // Switch the layout to match the selected identity flow.
                    switch(identityFlowLayoutType) {
                        
                    case .Login:
                        TextField("Username", text: $username)
                            .loginTextField()
                        
                        SecureField("Password", text: $password)
                            .loginSecureField()
                        
                        Button {
                            Task {
                                messageReset()
                                isAuthenticating = true
                                
                                // Login.
                                let result = await SalesforceManager.shared.nativeLoginManager()
                                    .login(username: username, password: password)
                                isAuthenticating = false
                                
                                // Act on the response.
                                unwrapResult(result) {
                                    layoutReset()
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
                            navigate(.StartPasswordLessLogin)
                        } label: {
                            Text("Use One Time Password Instead").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            navigate(.StartPasswordReset)
                        } label: {
                            Text("Reset Password").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            navigate(.StartRegistration)
                        } label: {
                            Text("Register").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                    case .StartRegistration:
                        TextField("Email", text: $email)
                            .loginTextField()
                        
                        TextField("First Name", text: $firstName)
                            .loginTextField()
                        
                        TextField("Last Name", text: $lastName)
                            .loginTextField()
                        
                        TextField("Username", text: $username)
                            .loginTextField()
                        
                        SecureField("Password", text: $password)
                            .loginSecureField()
                        
                        Picker(
                            "OTP Verification Method",
                            selection: $otpVerificationMethod) {
                                Text("Email").tag(OtpVerificationMethod.email)
                                Text("SMS").tag(OtpVerificationMethod.sms)
                            }
                            .frame(maxWidth: 250)
                            .zIndex(2.0)
                        
                        Button {
                            onRequestOtpForRegistrationTapped()
                        } label: {
                            HStack {
                                Image(systemName: "lock")
                                Text("Request One-Time-Password")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            layoutReset()
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                        
                    case .CompleteRegistration:
                        TextField("One-Time-Password", text: $otp)
                            .loginTextField()
                        
                        Button {
                            onCompleteRegistrationTapped()
                        } label: {
                            HStack {
                                Image(systemName: "lock")
                                Text("Complete Registration")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            layoutReset()
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                        
                    case .StartPasswordReset:
                        // Layout to start password reset.
                        TextField("Username", text: $username)
                            .loginTextField()
                        
                        Button {
                            onRequestOtpForResetPasswordTapped()
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
                            layoutReset()
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                        
                    case .CompletePasswordReset:
                        // Layout to complete password reset.
                        Text($username.wrappedValue)
                            .foregroundColor(.blue)
                            .frame(maxWidth: 250)
                            .multilineTextAlignment(.center)
                            .padding(.top, 25)
                            .zIndex(2.0)
                        
                        TextField("One-Time-Password", text: $otp)
                            .loginTextField()
                        
                        SecureField("New Password", text: $password)
                            .loginSecureField()
                        
                        Button {
                            onResetPasswordTapped()
                        } label: {
                            HStack {
                                Image(systemName: "lock")
                                Text("Reset Password")
                            }.frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(colorScheme == .dark ? .white : .blue)
                        .zIndex(2.0)
                        
                        Button {
                            layoutReset()
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                        
                    case .StartPasswordLessLogin:
                        // Layout to initialize password-less login by requesting a one-time-passcode.
                        TextField("Username", text: $username)
                            .loginTextField()
                        
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
                            layoutReset()
                        } label: {
                            Text("Cancel").frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .zIndex(2.0)
                        
                    case .CompletePasswordLessLogin:
                        // Layout for password-less login by submitting a previously requested one-time-passcode.
                        TextField("One Time Password", text: $otp)
                            .loginTextField()
                        
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
                            layoutReset()
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
    
    // MARK: User Registration Actions
    
    /// Submits a start registration request to the Salesforce Identity API forgot password endpoint.
    private func onRequestOtpForRegistrationTapped() {
        // Reset the message.
        messageReset()
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Execute for a new reCAPTCHA token.
        reCaptchaClientObservable.reCaptchaClient?.execute(
            withAction: .signup
        ) {reCaptchaExecuteResult, error in
            
            // Guard for the new reCAPTCHA token.
            guard let reCaptchaToken = reCaptchaExecuteResult else {
                SalesforceLogger.e(AppDelegate.self, message: "Could not obtain a reCAPTCHA signup action token due to error with description '\(error?.localizedDescription ?? "(A description wasn't provided.)")'.")
                return
            }
            
            // Submit the request and act on the response.
            Task {
                // Submit the request.
                let result = await SalesforceManager.shared.nativeLoginManager()
                    .startRegistration(
                        email: email,
                        firstName: firstName,
                        lastName: lastName,
                        username: username,
                        newPassword: password,
                        reCaptchaToken: reCaptchaToken,
                        otpVerificationMethod: otpVerificationMethod)
                
                // Clear the progresss indicator.
                isAuthenticating = false
                
                // Act on the response.
                unwrapResult(result.nativeLoginResult) {
                    requestIdentifier = result.requestIdentifier
                    navigate(.CompleteRegistration)
                }
            }
        }
    }
    
    /// Submits a complete registration request to the Salesforce Identity API registration endpoint.
    private func onCompleteRegistrationTapped() {
        // Reset the message.
        messageReset()
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Submit the request and act on the response.
        Task {
            // Submit the request.
            guard let requestIdentifier = requestIdentifier else { return }
            let result = await SalesforceManager.shared.nativeLoginManager()
                .completeRegistration(
                    otp: otp,
                    requestIdentifier: requestIdentifier,
                    otpVerificationMethod: otpVerificationMethod)
            
            // Clear the progresss indicator.
            isAuthenticating = false
            
            switch result {
            case .success:
                layoutReset()
                break
            default:
                errorMessage("An error occurred.")
            }
        }
    }
    
    // MARK: Passsword Reset User Actions
    
    /// Submits a start password reset request to the Salesforce Identity API forgot password endpoint.
    private func onRequestOtpForResetPasswordTapped() {
        // Reset the message.
        messageReset()
        
        // Clear the user's previous password entry.
        password = ""
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Execute for a new reCAPTCHA token.
        reCaptchaClientObservable.reCaptchaClient?.execute(
            withAction: .init(customAction: "forgot_password")
        ) {reCaptchaExecuteResult, error in
            
            // Guard for the new reCAPTCHA token.
            guard let reCaptchaToken = reCaptchaExecuteResult else {
                SalesforceLogger.e(AppDelegate.self, message: "Could not obtain a reCAPTCHA forgot password action token due to error with description '\(error?.localizedDescription ?? "(A description wasn't provided.)")'.")
                return
            }
            
            // Submit the request and act on the response.
            Task {
                // Submit the request.
                let result = await SalesforceManager.shared.nativeLoginManager()
                    .startPasswordReset(
                        username: username,
                        reCaptchaToken: reCaptchaToken)
                
                // Clear the progresss indicator.
                isAuthenticating = false
                
                // Act on the response.
                unwrapResult(result) {
                    navigate(.CompletePasswordReset)
                }
            }
        }
    }
    
    /// Submits a complete password reset request to the Salesforce Identity API forgot password endpoint.
    private func onResetPasswordTapped() {
        // Reset the message.
        messageReset()
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Submit the request and act on the response.
        Task {
            // Submit the request.
            let result = await SalesforceManager.shared.nativeLoginManager()
                .completePasswordReset(
                    username: username,
                    otp: otp,
                    newPassword: password)
            
            // Clear the progresss indicator.
            isAuthenticating = false
            
            switch result {
            case .success:
                layoutReset()
                message("Password reset successfully.  Log in using the new password.")
                break
            default:
                errorMessage("An error occurred.")
            }
        }
    }
    
    // MARK: Password-Less Login User Actions
    
    ///
    /// Submits the OTP delivery request when the request button is tapped.  This submits a request to the
    /// `init/passwordless/login`endpoint and opens the submit OTP verification view on success.
    ///
    private func onRequestOtpTapped() {
        // Reset the message.
        messageReset()
        
        // Show the progress indicator.
        isAuthenticating = true
        
        // Execute for a new reCAPTCHA token.
        reCaptchaClientObservable.reCaptchaClient?.execute(withAction: .login) {reCaptchaExecuteResult, error in
            
            // Guard for the new reCAPTCHA token.
            guard let reCaptchaToken = reCaptchaExecuteResult else {
                SalesforceLogger.e(AppDelegate.self, message: "Could not obtain a reCAPTCHA login action token due to error with description '\(error?.localizedDescription ?? "(A description wasn't provided.)")'.")
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
                unwrapResult(result.nativeLoginResult) {
                    // Verify parameters.
                    guard let otpIdentifierResult = result.otpIdentifier else { return }
                    
                    // Switch to the OTP submission layout.
                    otpIdentifier = otpIdentifierResult
                    navigate(.CompletePasswordLessLogin)
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
        
        // Reset the message.
        messageReset()
        
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
                layoutReset()
                break
            default:
                errorMessage("An error occurred.")
            }
        }
    }
    
    // MARK: Private User Messsaging Utilities
    
    /// Sets the error message displayed to the user.
    private func errorMessage(_ text: String) {
        messageReset()
        
        messageText = text
        isMessageError = true
    }
    
    /// Sets the informational message displayed to the user.
    private func message(_ text: String) {
        messageReset()
        
        messageText = text
    }
    
    /// Resets the message state.
    private func messageReset() {
        isMessageError = false
        messageText = ""
    }
    
    /// Unwraps a native login result to a success outcome or sets an appropriate error user message.
    /// - Parameters:
    ///   - result: The native login result
    ///   - onSuccess: The success outcome
    private func unwrapResult(
        _ result: NativeLoginResult,
        onSuccess: () -> ())
    {
        switch result {
        case .invalidCredentials:
            errorMessage("Please check your username and password.")
            break
        case .invalidEmail:
            errorMessage("Invalid email address.")
            break
        case .invalidUsername:
            errorMessage("Username format is incorrect.")
            break
        case .invalidPassword:
            errorMessage("Invalid password.")
            break
        case .unknownError:
            errorMessage("An unknown error has occurred.")
            break
        case .success:
            onSuccess()
        }
    }
    
    // MARK: Private Navigation Utilities
    
    /// Resets to the initial layout.
    private func layoutReset() {
        otp = ""
        otpIdentifier = ""
        otpVerificationMethod = .sms
        password = ""
        username = ""
        
        navigate(.Login)
    }
    
    /// Navigates to the specified layout.
    private func navigate(_ identityFlowLayoutType: IdentityFlowLayoutType) {
        messageReset()
        self.identityFlowLayoutType = identityFlowLayoutType
    }
}

///
/// Layouts for the available Salesforce identity flows.
///
enum IdentityFlowLayoutType {
    
    /// A layout to start the user registration flow.
    case StartRegistration
    
    /// A layout to complete the user registration flow.
    case CompleteRegistration
    
    /// A layout to start the password reset flow.
    case StartPasswordReset
    
    /// A layout to complete the password reset flow.
    case CompletePasswordReset
    
    /// A layout to initialize password-less login via one-time-passcode request.
    case StartPasswordLessLogin
    
    /// A layout for authorization code and credentials flow via username and previously requested one-time-passcode.
    case CompletePasswordLessLogin
    
    /// A layout for authorization code and credentials flow via username and password
    case Login
}

// MARK: Private SwiftUI Utilities

private struct LoginField: ViewModifier {
    let paddingTop: CGFloat = 10
    let paddingBottom: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.blue)
            .disableAutocorrection(true)
            .multilineTextAlignment(.center)
            .buttonStyle(.borderless)
            .autocapitalization(.none)
            .frame(maxWidth: 250)
            .padding(.top, paddingTop)
            .zIndex(2.0)
    }
}

extension TextField {
    func loginTextField() -> some View {
            modifier(LoginField())
        }
}

extension SecureField {
    func loginSecureField() -> some View {
            modifier(LoginField())
        }
}

// MARK: Previews

#Preview {
    NativeLoginView()
}
