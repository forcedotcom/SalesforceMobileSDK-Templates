package com.salesforce.androidnativelogintemplate

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.LoginViaUsernamePassword
import com.salesforce.androidsdk.auth.interfaces.OtpVerificationMethod.Sms

/**
 * An Android view model for the login activity.
 */
class NativeLoginViewModel : ViewModel() {

    /** The one-time-password identifier returned by the Salesforce Identity API */
    val otpIdentifier: MutableState<String?> = mutableStateOf(null)

    /** The user-selected one-time-password verification method */
    val otpVerificationMethod = mutableStateOf(Sms)

    /** The active identity flow layout type */
    val identifyFlowlayoutType = mutableStateOf(LoginViaUsernamePassword)

    /**
     * Layouts for the available Salesforce identity flows.
     */
    enum class IdentityFlowLayoutType {

        /** A layout to initialize password-less login via one-time-passcode request. */
        InitializePasswordLessLoginViaOtp,

        /** A layout for authorization code and credentials flow via username and previously requested one-time-passcode. */
        LoginViaUsernameAndOtp,

        /** A layout for authorization code and credentials flow via username and password. */
        LoginViaUsernamePassword
    }
}
