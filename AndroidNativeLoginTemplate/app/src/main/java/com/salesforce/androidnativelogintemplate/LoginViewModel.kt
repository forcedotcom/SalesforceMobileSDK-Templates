package com.salesforce.androidnativelogintemplate

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.salesforce.androidsdk.auth.interfaces.OtpVerificationMethod.Sms

/**
 * An Android view model for the login activity.
 */
internal class LoginViewModel : ViewModel() {

    /** The one-time-password identifier returned by the Salesforce Identity API */
    val otpIdentifier: MutableState<String?> = mutableStateOf(null)

    /** The user-selected one-time-password verification method */
    val otpVerificationMethod = mutableStateOf(Sms)
}
