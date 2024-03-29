/*
 * Copyright (c) 2022-present, salesforce.com, inc.
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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.components

import android.content.res.Configuration.UI_MODE_NIGHT_YES
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme

/**
 * A text field which extends the built-in [OutlinedTextField] to also have a "helper" text below
 * the input field.
 */
@Composable
fun OutlinedTextFieldWithHelp(
    value: String,
    isEditEnabled: Boolean,
    isError: Boolean,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    fieldModifier: Modifier = Modifier,
    label: (@Composable () -> Unit)? = null,
    placeholder: (@Composable () -> Unit)? = null,
    help: String? = null,
    maxLines: UInt = UInt.MAX_VALUE,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default
) {
    // This implementation is very similar to the built-in OutlinedTextField
    var textFieldValueState by remember { mutableStateOf(TextFieldValue(value)) }
    val textFieldValue = textFieldValueState.copy(text = value)

    OutlinedTextFieldWithHelp(
        value = textFieldValue,
        isEditEnabled = isEditEnabled,
        isError = isError,
        onValueChange = {
            textFieldValueState = it
            if (it.text != value) {
                onValueChange(it.text)
            }
        },
        modifier = modifier,
        fieldModifier = fieldModifier,
        label = label,
        placeholder = placeholder,
        help = help,
        maxLines = maxLines,
        keyboardActions = keyboardActions,
        keyboardOptions = keyboardOptions
    )
}

/**
 * A text field which extends the built-in [OutlinedTextField] to also have a "helper" text below
 * the input field.
 */
@Composable
fun OutlinedTextFieldWithHelp(
    value: TextFieldValue,
    isEditEnabled: Boolean,
    isError: Boolean,
    onValueChange: (TextFieldValue) -> Unit,
    modifier: Modifier = Modifier,
    fieldModifier: Modifier = Modifier,
    label: (@Composable () -> Unit)? = null,
    placeholder: (@Composable () -> Unit)? = null,
    help: String? = null,
    maxLines: UInt = UInt.MAX_VALUE,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default
) {
    val safeMaxLines = maxLines.coerceIn(0u..Int.MAX_VALUE.toUInt()).toInt()

    Column(modifier = modifier) {
        OutlinedTextField(
            modifier = fieldModifier,
            value = value,
            onValueChange = onValueChange,
            label = label,
            placeholder = placeholder,
            readOnly = !isEditEnabled,
            isError = isError,
            enabled = isEditEnabled,
            maxLines = safeMaxLines,
            singleLine = safeMaxLines == 1,
            keyboardActions = keyboardActions,
            keyboardOptions = keyboardOptions
        )

        val localContentColor = when {
            isError -> MaterialTheme.colors.error
            isEditEnabled -> LocalContentColor.current
            else -> LocalContentColor.current.copy(ContentAlpha.disabled)
        }

        val textStyle = MaterialTheme.typography.caption.copy(color = localContentColor)

        CompositionLocalProvider(
            LocalContentColor provides localContentColor,
            LocalTextStyle provides textStyle
        ) {
            Text(help ?: "")
        }
    }
}

@Preview(showBackground = true)
@Preview(showBackground = true, uiMode = UI_MODE_NIGHT_YES)
@Composable
private fun LabeledTextFieldPreview() {
    SalesforceMobileSDKAndroidTheme {
        Surface {
            Column {
                var isEditEnabled = true
                var isError = true
                OutlinedTextFieldWithHelp(
                    modifier = Modifier.padding(8.dp),
                    fieldModifier = Modifier.fillMaxWidth(),
                    value = "isEditEnabled = $isEditEnabled, isError = $isError",
                    isEditEnabled = isEditEnabled,
                    isError = isError,
                    label = { Text("Label") },
                    placeholder = { Text("Hint") },
                    help = "Help Text Goes Here",
                    onValueChange = {}
                )

                isError = false

                OutlinedTextFieldWithHelp(
                    modifier = Modifier.padding(8.dp),
                    fieldModifier = Modifier.fillMaxWidth(),
                    value = "isEditEnabled = $isEditEnabled, isError = $isError",
                    isEditEnabled = isEditEnabled,
                    isError = isError,
                    label = { Text("Label") },
                    placeholder = { Text("Hint") },
                    help = "Help Text Goes Here",
                    onValueChange = {}
                )

                isError = true
                isEditEnabled = false

                OutlinedTextFieldWithHelp(
                    modifier = Modifier.padding(8.dp),
                    fieldModifier = Modifier.fillMaxWidth(),
                    value = "isEditEnabled = $isEditEnabled, isError = $isError",
                    isEditEnabled = isEditEnabled,
                    isError = isError,
                    label = { Text("Label") },
                    placeholder = { Text("Hint") },
                    help = "Help Text Goes Here",
                    onValueChange = {}
                )

                isError = false

                OutlinedTextFieldWithHelp(
                    modifier = Modifier.padding(8.dp),
                    fieldModifier = Modifier.fillMaxWidth(),
                    value = "isEditEnabled = $isEditEnabled, isError = $isError",
                    isEditEnabled = isEditEnabled,
                    isError = isError,
                    label = { Text("Label") },
                    placeholder = { Text("Hint") },
                    help = "Help Text Goes Here",
                    onValueChange = {}
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun OverflowPreview() {
    OutlinedTextFieldWithHelp(
        value = "OverflowOverflowOverflowOverflowOverflowOverflowOverflowOverflowOverflowOverflowOverflow",
        isEditEnabled = false,
        isError = false,
        onValueChange = {},
        maxLines = 1u
    )
}
