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
import androidx.compose.foundation.shape.CornerSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Warning
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state.WINDOW_SIZE_COMPACT_CUTOFF_DP
import com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.theme.SalesforceMobileSDKAndroidTheme

/**
 * Wraps a [TextField] in a [Surface] with elevation to give it the appearance of floating above the
 * rest of the UI. Restricted to one (1) line.
 */
@Composable
fun FloatingTextEntryBar(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    fieldModifier: Modifier = Modifier,
    elevation: Dp = 4.dp,
    enabled: Boolean = true,
    readOnly: Boolean = false,
    textStyle: TextStyle = LocalTextStyle.current,
    placeholder: @Composable (() -> Unit)? = null,
    leadingIcon: @Composable (() -> Unit)? = null,
    trailingIcon: @Composable (() -> Unit)? = null,
    isError: Boolean = false,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions(),
) {
    val shape = RoundedCornerShape(CornerSize(percent = 50))
    Surface(modifier = modifier, shape = shape, elevation = elevation) {
        TextField(
            value = value,
            onValueChange = onValueChange,
            modifier = fieldModifier,
            enabled = enabled,
            readOnly = readOnly,
            textStyle = textStyle,
            placeholder = placeholder,
            leadingIcon = leadingIcon,
            trailingIcon = trailingIcon,
            isError = isError,
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions,
            maxLines = 1,
            singleLine = true,
            colors = TextFieldDefaults.textFieldColors(backgroundColor = Color.Transparent)
        )
    }
}

@Preview(showBackground = true, widthDp = WINDOW_SIZE_COMPACT_CUTOFF_DP)
@Preview(showBackground = true, widthDp = WINDOW_SIZE_COMPACT_CUTOFF_DP, uiMode = UI_MODE_NIGHT_YES)
@Composable
private fun FloatingSearchBarPreview() {
    SalesforceMobileSDKAndroidTheme {
        Surface {
            Column {
                FloatingTextEntryBar(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    value = "Hello, World!",
                    onValueChange = {},
                    placeholder = { Text("Placeholder") },
                    leadingIcon = { Icon(Icons.Default.Check, contentDescription = "") },
                )

                FloatingTextEntryBar(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    value = "",
                    onValueChange = {},
                    placeholder = { Text("Placeholder") },
                    trailingIcon = {
                        IconButton(onClick = {}) {
                            Icon(Icons.Default.Clear, contentDescription = "")
                        }
                    },
                )

                FloatingTextEntryBar(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    value = "Error!",
                    onValueChange = {},
                    placeholder = { Text("Placeholder") },
                    leadingIcon = { Icon(Icons.Default.Warning, contentDescription = "") },
                    trailingIcon = {
                        IconButton(onClick = {}) {
                            Icon(Icons.Default.Clear, contentDescription = "")
                        }
                    },
                    isError = true
                )
            }
        }
    }
}
