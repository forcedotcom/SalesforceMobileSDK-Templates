/*
 * Copyright (c) 2024-present, salesforce.com, inc.
 * All rights reserved.
 * Redistribution and use of this software in source and binary forms, with or
 * without modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * - Neither the name of salesforce.com, inc. nor the names of its contributors
 * may be used to endorse or promote products derived from this software without
 * specific prior written permission of salesforce.com, inc.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package com.salesforce.androidnativelogintemplate

import android.content.Intent
import android.os.Build.VERSION.SDK_INT
import android.os.Build.VERSION_CODES.S
import android.os.Build.VERSION_CODES.TIRAMISU
import android.os.Bundle
import android.widget.Toast
import android.widget.Toast.LENGTH_LONG
import android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement.SpaceAround
import androidx.compose.foundation.layout.Arrangement.SpaceEvenly
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults.buttonColors
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MaterialTheme.colorScheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment.Companion.Center
import androidx.compose.ui.Alignment.Companion.CenterHorizontally
import androidx.compose.ui.Alignment.Companion.CenterVertically
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color.Companion.LightGray
import androidx.compose.ui.graphics.Color.Companion.Red
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.input.KeyboardType.Companion.Password
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.google.android.recaptcha.RecaptchaAction.Companion.LOGIN
import com.google.android.recaptcha.RecaptchaAction.Companion.SIGNUP
import com.google.android.recaptcha.RecaptchaAction.Companion.custom
import com.salesforce.androidnativelogintemplate.MainApplication.Companion.executeReCaptchaAction
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.CompletePasswordLessLogin
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.CompletePasswordReset
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.CompleteRegistration
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.Login
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.StartPasswordLessLogin
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.StartPasswordReset
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.StartRegistration
import com.salesforce.androidnativelogintemplate.R.drawable.radio_button_checked_24px
import com.salesforce.androidnativelogintemplate.R.drawable.radio_button_unchecked_24px
import com.salesforce.androidnativelogintemplate.R.drawable.sf__salesforce_logo
import com.salesforce.androidsdk.R.drawable.sf__action_back
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.auth.interfaces.NativeLoginManager
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult.InvalidCredentials
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult.InvalidEmail
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult.InvalidPassword
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult.InvalidUsername
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult.Success
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult.UnknownError
import com.salesforce.androidsdk.auth.interfaces.OtpVerificationMethod
import com.salesforce.androidsdk.auth.interfaces.OtpVerificationMethod.Email
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

class NativeLogin : ComponentActivity() {

    private val viewModel: NativeLoginViewModel by viewModels()

    private lateinit var nativeLoginManager: NativeLoginManager

    // Start activity for result so we can close this activity if webview login is successful.
    private val handleWebviewFallbackResult = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->

        if (result.resultCode == RESULT_OK) {
            finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        nativeLoginManager = SalesforceSDKManager.getInstance().nativeLoginManager!!

        setContentView(
            ComposeView(this).apply {
                setContent {

                    // We pass all NativeLoginManager related functions here so that Jetpack Compose Preview works.
                    // If we don't SalesforceSDKManager.getInstance() will complain it has not be setup.
                    LoginView(
                        // Pass this inline login function to be executed within the composable.
                        login = { username, password ->
                            Boolean
                            // Call login and handle results.
                            return@LoginView nativeLoginManager.login(
                                username,
                                password
                            ).mapResultTo(
                                success = true,
                                failure = false
                            )
                        },
                        handleWebviewFallbackResult = handleWebviewFallbackResult,
                        webviewLoginIntent = nativeLoginManager.getFallbackWebAuthenticationIntent(),
                        shouldShowBack = nativeLoginManager.shouldShowBackButton,
                        backAction = { finish() },
                    )
                }
            }
        )

        if (SDK_INT >= TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                PRIORITY_DEFAULT
            ) {
                if (nativeLoginManager.shouldShowBackButton) {
                    when (SalesforceSDKManager.getInstance().userAccountManager.authenticatedUsers) {
                        null -> moveTaskToBack(false)
                        else -> finish()
                    }
                }
            }
        }
    }

    /**
     * Submits a start registration request to the Salesforce Identity API
     * registration endpoint.
     * @param email The user-entered email address
     * @param firstName The user-entered first name
     * @param lastName The user-entered last name
     * @param username The user-entered username
     * @param newPassword The user-entered new password
     * @param otpVerificationMethod The user-selected OTP verification method
     * the OTP will be delivered to
     * @return The request identifier provided by the Salesforce Identity API
     */
    private suspend fun submitStartRegistrationRequest(
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        newPassword: String,
        otpVerificationMethod: OtpVerificationMethod
    ): String? {

        // Obtain a new signup action reCAPTCHA token.
        var reCaptchaToken: String? = null
        runBlocking {
            executeReCaptchaAction(SIGNUP) { reCaptchaTokenNew ->
                when {
                    reCaptchaTokenNew != null -> reCaptchaToken = reCaptchaTokenNew
                    else -> runOnUiThread {
                        Toast.makeText(
                            baseContext,
                            "A reCAPTCHA signup action token could not be obtained.  Try again.",
                            LENGTH_LONG
                        ).show()
                    }
                }
            }.join()
        }

        // Submit the start registration request and respond to the result.
        val startRegistrationResult = nativeLoginManager.startRegistration(
            email = email,
            firstName = firstName,
            lastName = lastName,
            username = username,
            newPassword = newPassword,
            reCaptchaToken = reCaptchaToken ?: return null,
            otpVerificationMethod = otpVerificationMethod
        )
        return startRegistrationResult.nativeLoginResult.mapResultTo(
            success = startRegistrationResult.requestIdentifier,
            failure = null
        )
    }

    /**
     * Submits a complete registration request to the Salesforce Identity API
     * authorization and token endpoints.
     * @param otp The user-entered one-time-password
     * @param requestIdentifier The request identifier provided by the Salesforce
     * Identity API
     * @param otpVerificationMethod The OTP verification method used to obtain
     * the request identifier
     * @return Boolean true if the authorization request is successful - false
     * otherwise
     */
    private suspend fun submitCompleteRegistrationRequest(
        otp: String,
        requestIdentifier: String,
        otpVerificationMethod: OtpVerificationMethod
    ) = nativeLoginManager.completeRegistration(
        otp = otp,
        requestIdentifier = requestIdentifier,
        otpVerificationMethod = otpVerificationMethod
    ).mapResultTo(
        success = true,
        failure = false
    )

    /**
     * Submits a start password reset request to the Salesforce Identity
     * API forgot password endpoint.
     * @param username The user-entered username
     * @return A native login result
     */
    private suspend fun submitStartPasswordResetRequest(
        username: String
    ): NativeLoginResult? {

        // Obtain a new login action reCAPTCHA token.
        var reCaptchaToken: String? = null
        runBlocking {
            executeReCaptchaAction(custom("forgot_password")) { reCaptchaTokenNew ->
                when {
                    reCaptchaTokenNew != null -> reCaptchaToken = reCaptchaTokenNew
                    else -> runOnUiThread {
                        Toast.makeText(
                            baseContext,
                            "A reCAPTCHA forgot password action token could not be obtained.  Try again.",
                            LENGTH_LONG
                        ).show()
                    }
                }
            }.join()
        }

        // Submit the start password reset request and respond to the result.
        val startPasswordResetResult = nativeLoginManager.startPasswordReset(
            username = username,
            reCaptchaToken = reCaptchaToken ?: return null
        )
        return startPasswordResetResult.mapResultTo(
            success = startPasswordResetResult,
            failure = null
        )
    }

    /**
     * Submits a complete password reset request to the Salesforce Identity
     * API forgot password endpoint.
     * @param username The Salesforce username
     * @param otp The user-entered one-time-password previously delivered to the
     * user by the Salesforce Identity API forgot password endpoint
     * @param newPassword The user-entered new password
     * @return A native login result
     */
    private suspend fun submitCompletePasswordResetRequest(
        username: String,
        otp: String,
        newPassword: String
    ): NativeLoginResult? {

        // Submit the complete password reset request and respond to the result.
        val completePasswordResetResult = nativeLoginManager.completePasswordReset(
            username = username,
            otp = otp,
            newPassword = newPassword
        )
        return completePasswordResetResult.mapResultTo(
            success = completePasswordResetResult,
            failure = null
        )
    }

    /**
     * Submits a start password-less login request to the Salesforce Identity
     * API initialize headless login endpoint.
     * @param username The user-entered username
     * @param otpVerificationMethod The user-selected OTP verification method
     * the OTP will be delivered to
     * @return The OTP identifier provided by the Salesforce Identity API or
     * null if one could not be obtained.  A toast will already have been shown
     * if null is returned.
     */
    private suspend fun submitStartPasswordLessLoginRequest(
        username: String,
        otpVerificationMethod: OtpVerificationMethod
    ): String? {

        // Obtain a new login action reCAPTCHA token.
        var reCaptchaToken: String? = null
        runBlocking {
            executeReCaptchaAction(LOGIN) { reCaptchaTokenNew ->
                when {
                    reCaptchaTokenNew != null -> reCaptchaToken = reCaptchaTokenNew
                    else -> runOnUiThread {
                        Toast.makeText(
                            baseContext,
                            "A reCAPTCHA login action token could not be obtained.  Try again.",
                            LENGTH_LONG
                        ).show()
                    }
                }
            }.join()
        }

        // Submit the start password-less login request and respond to the result.
        val startPasswordLessLoginResult = nativeLoginManager.submitOtpRequest(
            username = username,
            reCaptchaToken = reCaptchaToken ?: return null,
            otpVerificationMethod = otpVerificationMethod
        )
        return startPasswordLessLoginResult.nativeLoginResult.mapResultTo(
            success = startPasswordLessLoginResult.otpIdentifier,
            failure = null
        )
    }

    /**
     * Submits a complete password-less login request to the Salesforce Identity
     * API authorization and token endpoints.
     * @param otp The user-entered OTP
     * @param otpIdentifier The OTP identifier provided by the Salesforce
     * Identity API
     * @param otpVerificationMethod The OTP verification method used to obtain
     * the OTP identifier
     * @return Boolean true if the authorization request is successful - false
     * otherwise
     */
    private suspend fun submitCompletePasswordLessLoginRequest(
        otp: String,
        otpIdentifier: String,
        otpVerificationMethod: OtpVerificationMethod
    ): Boolean {

        // Submit the complete password-less login request and respond to the result.
        val completePasswordLessLoginResult = nativeLoginManager.submitPasswordlessAuthorizationRequest(
            otp = otp,
            otpIdentifier = otpIdentifier,
            otpVerificationMethod = otpVerificationMethod
        )
        return completePasswordLessLoginResult.mapResultTo(
            success = true,
            failure = false
        )
    }

    /**
     * A layout for the login view, including navigation between layouts for the
     * available identity flows.
     * @param login A function for login via username and password
     * @param handleWebviewFallbackResult An activity for fallback to web login
     * @param shouldShowBack An option to show the back button which cancels login
     * @param backAction A function for the back action which cancels login
     * @param identityFlowLayoutType Optionally, a specific initial identity flow
     * layout type.  Defaults to null and the view model value is used.  This is
     * intended for preview support
     */
    @OptIn(ExperimentalComposeUiApi::class)
    @Composable
    fun LoginView(
        login: suspend (String, String) -> Boolean,
        handleWebviewFallbackResult: ActivityResultLauncher<Intent>? = null,
        webviewLoginIntent: Intent,
        shouldShowBack: Boolean = false,
        backAction: () -> Unit,
        identityFlowLayoutType: IdentityFlowLayoutType? = null
    ) {

        // The layout type for the user's active identity flow, such as registration, forgot password or login
        val identityFlowLayoutTypeActive = runCatching { // This view model reference is guarded to support previews, which don't have view model access.
            viewModel.identifyFlowlayoutType.value
        }.getOrNull() ?: identityFlowLayoutType ?: Login

        LoginTheme {
            Scaffold(
                modifier = Modifier.semantics {
                    // Only needed for UI Testing
                    testTagsAsResourceId = true
                },
                topBar = {
                    Row(modifier = Modifier.statusBarsPadding()) {

                        // Back button should only be shown if there is a user already logged in.  But not
                        // in the case of Biometric Authentication.
                        if (shouldShowBack) {
                            TextButton(onClick = { backAction() }) {
                                Image(
                                    painter = painterResource(id = sf__action_back),
                                    colorFilter = ColorFilter.tint(colorScheme.primary),
                                    contentDescription = "Back",
                                    modifier = Modifier.padding(start = 16.dp)
                                )
                            }
                        }
                    }
                },
                bottomBar = {
                    Column(
                        horizontalAlignment = CenterHorizontally,
                        modifier = Modifier
                            .navigationBarsPadding()
                            .fillMaxWidth(),
                    ) {
                        // Fallback to web based authentication.
                        TextButton(onClick = { handleWebviewFallbackResult?.launch(webviewLoginIntent) }) {
                            Text(text = "Looking for Salesforce Log In?")
                        }
                    }
                },
            ) { innerPadding ->
                Column(
                    horizontalAlignment = CenterHorizontally,
                    modifier = Modifier
                        .verticalScroll(rememberScrollState(), reverseScrolling = true)
                        .navigationBarsPadding()
                        .padding(top = innerPadding.calculateTopPadding())
                        .imePadding()
                        .fillMaxSize(),
                ) {
                    Spacer(modifier = Modifier.height(75.dp))
                    ElevatedCard(
                        modifier = Modifier
                            .padding(16.dp)
                            .navigationBarsPadding()
                            .widthIn(350.dp, 500.dp),
                        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp)
                    ) {
                        Spacer(modifier = Modifier.height(25.dp))
                        if (identityFlowLayoutTypeActive != StartRegistration) {
                            Image(
                                painter = painterResource(id = sf__salesforce_logo),
                                colorFilter = ColorFilter.tint(colorScheme.primary),
                                contentDescription = "",
                                modifier = Modifier.align(CenterHorizontally),
                            )
                        }

                        // Switch the layout to match the selected identity flow.
                        when (identityFlowLayoutTypeActive) {
                            StartRegistration -> StartRegistrationInput()

                            CompleteRegistration -> CompleteRegistrationInput()

                            StartPasswordReset -> StartPasswordResetInput()

                            CompletePasswordReset -> CompletePasswordResetInput()

                            Login -> UserNamePasswordInput(login)

                            StartPasswordLessLogin -> StartPasswordLessLoginInput()

                            CompletePasswordLessLogin -> CompletePasswordLessLoginInput()
                        }

                        // Layout navigation buttons between the available identity flow layouts according to the current layout.
                        when (identityFlowLayoutTypeActive) {
                            Login -> {
                                // Allow the user to switch to login via username and OTP.
                                Button(
                                    onClick = {
                                        viewModel.identifyFlowlayoutType.value = StartPasswordLessLogin
                                    },
                                    modifier = Modifier.align(CenterHorizontally)
                                ) { Text(text = "Use One Time Password Instead") }

                                // Allow the user to switch to reset password via username and OTP.
                                Button(
                                    onClick = {
                                        viewModel.identifyFlowlayoutType.value = StartPasswordReset
                                    },
                                    modifier = Modifier.align(CenterHorizontally)
                                ) { Text(text = "Reset Password") }

                                // Allow the user to switch to registration
                                Button(
                                    onClick = {
                                        viewModel.identifyFlowlayoutType.value = StartRegistration
                                    },
                                    modifier = Modifier.align(CenterHorizontally)
                                ) { Text(text = "Register") }
                            }

                            else -> {
                                // From all the other layouts, allow the user to cancel back to the initial username and password layout.
                                Button(
                                    onClick = {
                                        viewModel.identifyFlowlayoutType.value = Login
                                    },
                                    colors = buttonColors().copy(
                                        containerColor = LightGray,
                                        contentColor = Red
                                    ),
                                    modifier = Modifier.align(CenterHorizontally)
                                ) {
                                    Text(text = "Cancel")
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(25.dp))
                    }
                }
            }
        }
    }

    @Composable
    fun StartRegistrationInput() {
        var email by remember { mutableStateOf("") }
        var firstName by remember { mutableStateOf("") }
        var lastName by remember { mutableStateOf("") }
        var username by remember { mutableStateOf("") }
        var newPassword by remember { mutableStateOf("") }
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        val otpVerificationMethod = runCatching { // This view model reference is guarded to support previews, which don't have view model access.
            viewModel.otpVerificationMethod.value
        }.getOrNull() ?: Email

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(0.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 8.dp)
                .fillMaxWidth(),
        ) {
            OutlinedTextField(
                value = email,
                onValueChange = {
                    email = it
                },
                label = { Text("Email") },
            )

            OutlinedTextField(
                value = firstName,
                onValueChange = {
                    firstName = it
                },
                label = { Text("First Name") }
            )

            OutlinedTextField(
                value = lastName,
                onValueChange = {
                    lastName = it
                },
                label = { Text("Last Name") }
            )

            OutlinedTextField(
                value = username,
                onValueChange = {
                    username = it
                },
                label = { Text("Username") },
            )

            OutlinedTextField(
                value = newPassword,
                onValueChange = { newPassword = it },
                label = { Text("Password") },
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = Password),
                modifier = Modifier.testTag("newPassword"),
            )

            Row(horizontalArrangement = SpaceEvenly) {
                OtpVerificationMethod.entries.forEach { otpVerificationMethodNext ->
                    Row(Modifier.clickable {
                        viewModel.otpVerificationMethod.value = otpVerificationMethodNext
                    }) {
                        Image(
                            painter = painterResource(
                                id = when (otpVerificationMethodNext == otpVerificationMethod) {
                                    true -> radio_button_checked_24px
                                    false -> radio_button_unchecked_24px
                                }
                            ),
                            colorFilter = ColorFilter.tint(colorScheme.primary),
                            contentDescription = "",
                            modifier = Modifier.align(CenterVertically),
                        )
                        Text(
                            text = otpVerificationMethodNext.name,
                            modifier = Modifier
                                .padding(8.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch {
                            CoroutineScope(IO).launch {
                                submitStartRegistrationRequest(
                                    email,
                                    firstName,
                                    lastName,
                                    username,
                                    newPassword,
                                    viewModel.otpVerificationMethod.value
                                )?.let { requestIdentifier ->
                                    viewModel.otpIdentifier.value = requestIdentifier
                                    viewModel.identifyFlowlayoutType.value = CompletePasswordLessLogin
                                }
                                viewModel.identifyFlowlayoutType.value = CompleteRegistration
                            }

                            loading = false
                        }
                    }
                ) {
                    Text(text = "Request One Time Password")
                }
            }
            )
        }
    }

    @Composable
    fun CompleteRegistrationInput() {
        var otp by remember { mutableStateOf("") }
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(100.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 16.dp)
                .fillMaxWidth(),
        ) {
            OutlinedTextField(
                value = otp,
                onValueChange = { otp = it },
                label = { Text("One-Time-Password") },
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch {
                            CoroutineScope(IO).launch IO@{
                                submitCompleteRegistrationRequest(
                                    otp,
                                    viewModel.otpIdentifier.value ?: return@IO,
                                    viewModel.otpVerificationMethod.value
                                )
                                loading = false
                            }
                        }
                    }
                ) {
                    Text(text = "Complete Registration")
                }
            }
            )
        }
    }

    @Composable
    fun StartPasswordResetInput() {
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(100.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 16.dp)
                .fillMaxWidth(),
        ) {
            OutlinedTextField(
                value = viewModel.usernameForCompletePasswordReset.value ?: "",
                onValueChange = {
                    viewModel.usernameForCompletePasswordReset.value = it
                },
                label = { Text("Username") },
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch {
                            CoroutineScope(IO).launch IO@{
                                submitStartPasswordResetRequest(
                                    viewModel.usernameForCompletePasswordReset.value ?: return@IO
                                )?.let {
                                    viewModel.identifyFlowlayoutType.value = CompletePasswordReset
                                }

                                loading = false
                            }
                        }
                    }
                ) {
                    Text(text = "Request One Time Password")
                }
            }
            )
        }
    }

    @Composable
    fun CompletePasswordResetInput() {
        var otp by remember { mutableStateOf("") }
        var newPassword by remember { mutableStateOf("") }
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(100.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 16.dp)
                .fillMaxWidth(),
        ) {
            Text(viewModel.usernameForCompletePasswordReset.value ?: "")

            OutlinedTextField(
                value = otp,
                onValueChange = { otp = it },
                label = { Text("One-Time-Password") },
            )

            OutlinedTextField(
                value = newPassword,
                onValueChange = { newPassword = it },
                label = { Text("New Password") },
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = Password),
                modifier = Modifier.testTag("newPassword"),
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch {
                            CoroutineScope(IO).launch IO@{
                                when (submitCompletePasswordResetRequest(
                                    viewModel.usernameForCompletePasswordReset.value ?: return@IO,
                                    otp,
                                    newPassword
                                )) {
                                    Success -> {
                                        viewModel.identifyFlowlayoutType.value = Login
                                        runOnUiThread {
                                            Toast.makeText(
                                                baseContext,
                                                "Password reset successfully.  Log in using the new password.",
                                                LENGTH_LONG
                                            ).show()
                                        }
                                    }

                                    else -> {
                                        runOnUiThread {
                                            Toast.makeText(
                                                baseContext,
                                                "Password could not be reset.  Try again.",
                                                LENGTH_LONG
                                            ).show()
                                        }
                                    }
                                }
                                loading = false
                            }
                        }
                    }
                ) {
                    Text(text = "Reset Password")
                }
            }
            )
        }
    }

    @Composable
    fun StartPasswordLessLoginInput() {
        var username by remember { mutableStateOf("") }
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        val otpVerificationMethod = runCatching { // This view model reference is guarded to support previews, which don't have view model access.
            viewModel.otpVerificationMethod.value
        }.getOrNull() ?: Email

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(100.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 16.dp)
                .fillMaxWidth(),
        ) {
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                label = { Text("Username") },
            )

            Row(horizontalArrangement = SpaceEvenly) {
                OtpVerificationMethod.entries.forEach { otpVerificationMethodNext ->
                    Row(Modifier.clickable {
                        viewModel.otpVerificationMethod.value = otpVerificationMethodNext
                    }) {
                        Image(
                            painter = painterResource(
                                id = when (otpVerificationMethodNext == otpVerificationMethod) {
                                    true -> radio_button_checked_24px
                                    false -> radio_button_unchecked_24px
                                }
                            ),
                            colorFilter = ColorFilter.tint(colorScheme.primary),
                            contentDescription = "",
                            modifier = Modifier.align(CenterVertically),
                        )
                        Text(
                            text = otpVerificationMethodNext.name,
                            modifier = Modifier
                                .padding(8.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch {
                            CoroutineScope(IO).launch {
                                submitStartPasswordLessLoginRequest(
                                    username,
                                    viewModel.otpVerificationMethod.value
                                )?.let { otpIdentifier ->
                                    viewModel.otpIdentifier.value = otpIdentifier
                                    viewModel.identifyFlowlayoutType.value = CompletePasswordLessLogin
                                }

                                loading = false
                            }
                        }
                    }
                ) {
                    Text(text = "Request One Time Password")
                }
            }
            )
        }
    }

    @Composable
    fun CompletePasswordLessLoginInput() {
        var otp by remember { mutableStateOf("") }
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(100.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 16.dp)
                .fillMaxWidth(),
        ) {
            OutlinedTextField(
                value = otp,
                onValueChange = { otp = it },
                label = { Text("One-Time-Password") },
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch {
                            CoroutineScope(IO).launch IO@{
                                submitCompletePasswordLessLoginRequest(
                                    otp,
                                    viewModel.otpIdentifier.value ?: return@IO,
                                    viewModel.otpVerificationMethod.value
                                )
                                loading = false
                            }
                        }
                    }
                ) {
                    Text(text = "Log In Using One Time Password")
                }
            }
            )
        }
    }

    @Composable
    fun UserNamePasswordInput(
        login: suspend (String, String) -> Boolean
    ) {
        var username by remember { mutableStateOf("") }
        var password by remember { mutableStateOf("") }
        val scope = rememberCoroutineScope()
        var loading by remember { mutableStateOf(false) }

        if (loading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(100.dp)
            ) {
                Column(modifier = Modifier.align(Center)) {
                    CircularProgressIndicator()
                }
            }
        } else {
            Spacer(modifier = Modifier.height(100.dp))
        }

        Column(
            horizontalAlignment = CenterHorizontally,
            verticalArrangement = SpaceAround,
            modifier = Modifier
                .padding(all = 16.dp)
                .fillMaxWidth(),
        ) {
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                label = { Text("Username") },
                modifier = Modifier.testTag("username"),
            )

            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = Password),
                modifier = Modifier.testTag("password"),
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(content = {
                Button(
                    onClick = {
                        loading = true
                        scope.launch { loading = login(username, password) }
                    },
                    modifier = Modifier
                        .width(150.dp)
                        .testTag("Login"),
                ) {
                    Text(text = "Login")
                }
            }
            )
        }
    }

    @Composable
    fun LoginTheme(composable: @Composable () -> Unit) {
        val dynamicColors = SDK_INT >= S
        val isDarkTheme = isSystemInDarkTheme()
        val colorScheme = when {
            dynamicColors && isDarkTheme -> {
                dynamicDarkColorScheme(LocalContext.current)
            }

            dynamicColors && !isDarkTheme -> {
                dynamicLightColorScheme(LocalContext.current)
            }

            !dynamicColors && isDarkTheme -> {
                darkColorScheme()
            }

            else -> lightColorScheme()
        }

        MaterialTheme(colorScheme = colorScheme, content = composable)
    }

    @Preview
    @Composable
    fun LoginPreview() {
        Column {
            LoginView(
                login = { _, _ -> run { return@LoginView true } },
                webviewLoginIntent = Intent(),
                shouldShowBack = true,
                backAction = {}
            )
        }
    }

    @Preview
    @Composable
    fun LoginViewInitializePasswordLessLoginViaOtpPreview() {
        Column {
            LoginView(
                login = { _, _ -> run { return@LoginView true } },
                webviewLoginIntent = Intent(),
                shouldShowBack = true,
                backAction = {},
                identityFlowLayoutType = StartPasswordLessLogin
            )
        }
    }

    @Preview
    @Composable
    fun LoginViewLoginViaUsernameAndOtpPreview() {
        Column {
            LoginView(
                login = { _, _ -> run { return@LoginView true } },
                webviewLoginIntent = Intent(),
                shouldShowBack = true,
                backAction = {},
                identityFlowLayoutType = CompletePasswordLessLogin
            )
        }
    }

    @Preview
    @Composable
    fun LoginViewStartRegistrationPreview() {
        Column {
            LoginView(
                login = { _, _ -> run { return@LoginView true } },
                webviewLoginIntent = Intent(),
                shouldShowBack = true,
                backAction = {},
                identityFlowLayoutType = StartRegistration
            )
        }
    }

    // region Private Utilities

    /**
     * Maps a native login result to either the provided success or failure
     * value.  A toast is also displayed for failure.
     * @param success The value to return for successful native login results
     * @param failure The value to return for native login results other than
     * success
     * @return The success value for successful native login results - The
     * failure result otherwise
     */
    private fun <MappedType> NativeLoginResult.mapResultTo(
        success: MappedType,
        failure: MappedType
    ): MappedType = when (this) {
        InvalidEmail -> {
            runOnUiThread { Toast.makeText(baseContext, "Invalid email address.", LENGTH_LONG).show() }
            failure
        }

        InvalidUsername -> {
            runOnUiThread { Toast.makeText(baseContext, "Invalid user name.", LENGTH_LONG).show() }
            failure
        }

        InvalidPassword -> {
            runOnUiThread { Toast.makeText(baseContext, "Invalid password", LENGTH_LONG).show() }
            failure
        }

        InvalidCredentials -> {
            runOnUiThread { Toast.makeText(baseContext, "Invalid credentials.", LENGTH_LONG).show() }
            failure
        }

        UnknownError -> {
            runOnUiThread { Toast.makeText(baseContext, "An error occurred.", LENGTH_LONG).show() }
            failure
        }

        Success -> success
    }

    // endregion
}
