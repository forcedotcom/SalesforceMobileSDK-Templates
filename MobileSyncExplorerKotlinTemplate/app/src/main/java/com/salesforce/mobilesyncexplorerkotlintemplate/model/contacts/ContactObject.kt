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
package com.salesforce.mobilesyncexplorerkotlintemplate.model.contacts

import com.salesforce.androidsdk.mobilesync.util.Constants
import com.salesforce.mobilesyncexplorerkotlintemplate.core.extensions.optStringOrNull
import com.salesforce.mobilesyncexplorerkotlintemplate.core.salesforceobject.*
import org.json.JSONObject

/**
 * The runtime data model of the Salesforce Standard Contact Object. The _constructor_ of this class
 * throws [ContactValidationException] if the provided value for a property is not valid, as determined
 * by this class' business logic.
 */
data class ContactObject
@Throws(ContactValidationException::class) constructor(
    val firstName: String?,
    val lastName: String,
    val title: String?,
    val department: String?,
) : SObject {
    init {
        validateLastName(lastName)
        validateFirstName(firstName)
    }

    override val objectType: String = Constants.CONTACT

    val fullName = formatFullName(firstName = firstName, lastName = lastName)

    override fun JSONObject.applyObjProperties() = this.apply {
        putOpt(KEY_FIRST_NAME, firstName)
        putOpt(KEY_LAST_NAME, lastName)
        putOpt(KEY_TITLE, title)
        putOpt(KEY_DEPARTMENT, department)
        putOpt(Constants.NAME, fullName)
    }

    /**
     * [SObjectDeserializer] for the [ContactObject] SObject, implemented as the companion object
     * of [ContactObject] for logical encapsulation of data validation.
     */
    companion object : SObjectDeserializerBase<ContactObject>(objectType = Constants.CONTACT) {
        const val KEY_FIRST_NAME = "FirstName"
        const val KEY_LAST_NAME = "LastName"
        const val KEY_TITLE = "Title"
        const val KEY_DEPARTMENT = "Department"

        @Throws(CoerceException::class)
        override fun buildModel(fromJson: JSONObject): ContactObject = try {
            // Leverage the ContactObject constructor for property validation and rethrow the
            // corresponding CoerceException:
            ContactObject(
                firstName = fromJson.optStringOrNull(KEY_FIRST_NAME),
                lastName = fromJson.optString(KEY_LAST_NAME),
                title = fromJson.optStringOrNull(KEY_TITLE),
                department = fromJson.optStringOrNull(KEY_DEPARTMENT),
            )
        } catch (ex: ContactValidationException) {
            when (ex) {
                ContactValidationException.LastNameCannotBeBlank -> InvalidPropertyValue(
                    propertyKey = KEY_LAST_NAME,
                    allowedValuesDescription = "Contact Last Name cannot be blank",
                    offendingJsonString = fromJson.toString()
                )
                is ContactValidationException.FieldContainsIllegalText -> InvalidPropertyValue(
                    propertyKey = ex.fieldName,
                    allowedValuesDescription = "Contact ${ex.fieldName} contained invalid characters: ${ex.illegalText}",
                    offendingJsonString = fromJson.toString()
                )
            }.let { throw it } // exhaustive when
        }

        @Throws(ContactValidationException::class)
        fun validateLastName(lastName: String?) {
            if (lastName.isNullOrBlank())
                throw ContactValidationException.LastNameCannotBeBlank

            val matchingIllegalChar = illegalCharacterRegex.find(lastName)
            if (matchingIllegalChar != null)
                throw ContactValidationException.FieldContainsIllegalText(
                    fieldName = KEY_LAST_NAME,
                    illegalText = matchingIllegalChar.value
                )
        }

        @Throws(ContactValidationException.FieldContainsIllegalText::class)
        fun validateFirstName(firstName: String?) {
            if (firstName == null) return
            val matchingIllegalChar = illegalCharacterRegex.find(firstName)
            if (matchingIllegalChar != null)
                throw ContactValidationException.FieldContainsIllegalText(
                    fieldName = KEY_FIRST_NAME,
                    illegalText = matchingIllegalChar.value
                )
        }

        fun formatFullName(firstName: String?, lastName: String?) = buildString {
            if (firstName != null) append("$firstName ")
            if (lastName != null) append(lastName)
        }.trim()

        private val illegalCharacterRegex by lazy { Regex("\\R|\\t") }
    }
}

/**
 * Sealed class representing all possible property validation exceptions for the [ContactObject].
 */
sealed class ContactValidationException(override val message: String?) : Exception() {
    object LastNameCannotBeBlank : ContactValidationException("Contact Last Name cannot be blank")

    data class FieldContainsIllegalText(
        val fieldName: String,
        val illegalText: String,
    ) : ContactValidationException("Found illegal text \"$illegalText\" in $fieldName")
}

typealias ContactRecord = SObjectRecord<ContactObject>
