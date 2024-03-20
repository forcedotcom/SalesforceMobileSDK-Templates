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

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import android.window.OnBackInvokedDispatcher
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.auth.interfaces.NativeLoginManager
import com.salesforce.androidsdk.auth.interfaces.NativeLoginResult
import kotlinx.coroutines.launch

class NativeLogin : ComponentActivity() {
    private lateinit var nativeLoginManager: NativeLoginManager
    // Start activity for result so we can close this activity if webview login is successful.
    private val handleWebviewFallbackResult = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()) { result ->

        if (result.resultCode == Activity.RESULT_OK) {
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
                        login = { username, password -> Boolean
                            // Call login and handle results.
                            when (val result = nativeLoginManager.login(username, password)) {
                                NativeLoginResult.InvalidUsername -> {
                                    Toast.makeText(baseContext, result.name,Toast.LENGTH_LONG).show()
                                    return@LoginView false
                                }
                                NativeLoginResult.InvalidPassword -> {
                                    Toast.makeText(baseContext, result.name,Toast.LENGTH_LONG).show()
                                    return@LoginView false
                                }
                                NativeLoginResult.InvalidCredentials -> {
                                    Toast.makeText(baseContext, result.name,Toast.LENGTH_LONG).show()
                                    return@LoginView false
                                }
                                NativeLoginResult.UnknownError -> {
                                    Toast.makeText(baseContext, result.name, Toast.LENGTH_LONG).show()
                                    return@LoginView false
                                }
                                NativeLoginResult.Success -> {
                                    finish()
                                }
                            }

                            return@LoginView true
                        },
                        handleWebviewFallbackResult,
                        nativeLoginManager.getFallbackWebAuthenticationIntent(),
                        nativeLoginManager.shouldShowBackButton,
                        backAction = { finish() },
                    )
                }
            }
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
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
}

@Composable
fun LoginView(
    login: suspend (String, String) -> Boolean,
    handleWebviewFallbackResult: ActivityResultLauncher<Intent>? = null,
    webviewLoginIntent: Intent? = null,
    shouldShowBack: Boolean = false,
    backAction: () -> Unit,
) {
    LoginTheme {
        Scaffold(
            topBar = {
                Row(modifier = Modifier.statusBarsPadding()) {

                    // Back button should only be shown if there is a user already logged in.  But not
                    // in the case of Biometric Authentication.
                    if (shouldShowBack) {
                        TextButton(onClick = { backAction() }) {
                            Image(
                                painter = painterResource(id = com.salesforce.androidsdk.R.drawable.sf__action_back),
                                colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.primary),
                                contentDescription = "Back",
                                modifier = Modifier.padding(start = 16.dp)
                            )
                        }
                    }
                }
            },
            bottomBar = {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
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
                horizontalAlignment = Alignment.CenterHorizontally,
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
                    Spacer(modifier = Modifier.height(50.dp))
                    Image(
                        painter = painterResource(id = R.drawable.sf__salesforce_logo),
                        colorFilter = ColorFilter.tint(MaterialTheme.colorScheme.primary),
                        contentDescription = "",
                        modifier = Modifier.align(Alignment.CenterHorizontally),
                    )
                    UserNamePasswordInput(login)
                }
            }
        }
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
        Box(modifier = Modifier
            .fillMaxWidth()
            .height(100.dp)) {
            Column(modifier = Modifier.align(Alignment.Center)) {
                CircularProgressIndicator()
            }
        }
    } else {
        Spacer(modifier = Modifier.height(100.dp))
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceAround,
        modifier = Modifier
            .padding(all = 16.dp)
            .fillMaxWidth(),
    ) {
        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            label = { Text("Username") },
        )

        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(content = {
            Button(
                onClick = {
                    loading = true
                    scope.launch { loading = login(username, password) }
                },
                modifier = Modifier.width(150.dp),
            ) {
                Text(text = "Login")
            }
        }
        )
    }
}

@Composable
fun LoginTheme(composable: @Composable () -> Unit) {
    val dynamicColors = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
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
        LoginView (
            login = { _, _ -> run { return@LoginView true } },
            shouldShowBack = true,
            backAction = {},
        )
    }
}