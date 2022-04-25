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
package com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject

sealed class CoerceException(message: String?) : Exception(message) {
    abstract val offendingJsonString: String
}

data class IncorrectObjectType(
    val expectedObjectType: String,
    val foundObjectType: String,
    override val offendingJsonString: String,
) : CoerceException(
    buildString {
        appendLine("CoerceException - IncorrectObjectType")
        appendLine("This JSON had the incorrect object type. Expected $expectedObjectType but found $foundObjectType")
        appendLine("Offending JSON = '$offendingJsonString'")
    }
)

data class InvalidPropertyValue(
    val propertyKey: String,
    val allowedValuesDescription: String,
    override val offendingJsonString: String
) : CoerceException(
    buildString {
        appendLine("CoerceException - InvalidPropertyValue")
        appendLine("This JSON had an invalid value for key $propertyKey.")
        appendLine(allowedValuesDescription)
        appendLine("Offending JSON = '$offendingJsonString'")
    }
)

class MissingRequiredProperties(
    override val offendingJsonString: String,
    vararg val propertyKeys: String,
) : CoerceException(
    buildString {
        appendLine("CoerceException - MissingRequiredProperty")
        appendLine("This JSON was missing one or more of the required properties: $propertyKeys")
        appendLine("Offending JSON = '$offendingJsonString'")
    }
)
