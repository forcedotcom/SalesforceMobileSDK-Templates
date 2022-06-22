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

import androidx.annotation.StringRes

/**
 * General UI state for any field rendered in a form. This only allows String values, meaning any
 * complex data (e.g. a date) must first be transformed into string form. Conversely, it is up to
 * higher-level logic to transform the field value back into any complex data structure.
 */
interface FieldUiState {
    val fieldValue: String?
    val isInErrorState: Boolean

    /**
     * One or two words shown next to the field to indicate to the user what the field is for.
     */
    val label: FormattedStringRes?

    /**
     * A short message rendered next to the field, usually used to provide guidance to the user for
     * how to correct an error.
     */
    val helper: FormattedStringRes?

    /**
     * Text shown in the field before the user has entered anything, giving the user an example of
     * what should go in the field.
     */
    val placeholder: FormattedStringRes?
}

/**
 * Encapsulation of a string resource ID and its optional formatting parameters for use in rendering
 * in the UI.
 */
data class FormattedStringRes(@StringRes val resId: Int, val formattingArgs: Array<String> = emptyArray()) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as FormattedStringRes

        if (resId != other.resId) return false
        if (!formattingArgs.contentEquals(other.formattingArgs)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = resId
        result = 31 * result + formattingArgs.contentHashCode()
        return result
    }
}
