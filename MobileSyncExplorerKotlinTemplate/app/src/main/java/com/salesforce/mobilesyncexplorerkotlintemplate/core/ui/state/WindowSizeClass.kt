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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.ui.state

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp

/**
 * The different logical sizes of the app window, applicable to both horizontal and vertical axes.
 */
enum class WindowSizeClass {
    Compact,
    Medium,
    Expanded
}

/**
 * A simple data holder representing the horizontal and vertical [WindowSizeClass].
 */
data class WindowSizeClasses(val horiz: WindowSizeClass, val vert: WindowSizeClass)

fun DpSize.toWindowSizeClasses() = WindowSizeClasses(
    horiz = width.toWindowSizeClass(),
    vert = height.toWindowSizeClass()
)

fun Dp.toWindowSizeClass(): WindowSizeClass {
    val safeDp = this.coerceAtLeast(0.dp)
    return when {
        safeDp < WINDOW_SIZE_COMPACT_CUTOFF_DP.dp -> WindowSizeClass.Compact
        safeDp < WINDOW_SIZE_MEDIUM_CUTOFF_DP.dp -> WindowSizeClass.Medium
        else -> WindowSizeClass.Expanded
    }
}

const val WINDOW_SIZE_COMPACT_CUTOFF_DP = 600
const val WINDOW_SIZE_MEDIUM_CUTOFF_DP = 840
