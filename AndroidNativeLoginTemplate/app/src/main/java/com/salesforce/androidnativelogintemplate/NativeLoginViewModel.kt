package com.salesforce.androidnativelogintemplate

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.salesforce.androidnativelogintemplate.NativeLoginViewModel.IdentityFlowLayoutType.Login
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
    val identifyFlowlayoutType = mutableStateOf(Login)

    /** The user-entered username for the complete password reset identity flow layout type */
    val usernameForCompletePasswordReset: MutableState<String?> = mutableStateOf(null)

    /**
     * Layouts for the available Salesforce identity flows.
     */
    enum class IdentityFlowLayoutType {

        /** A layout to start a user registration */
        StartRegistration,

        /** A layout to complete a user registration */
        CompleteRegistration,

        /** A layout to start a password reset */
        StartPasswordReset,

        /** A layout to complete a password reset */
        CompletePasswordReset,

        /**
         * A layout to initialize password-less login via one-time-passcode
         * request
         */
        StartPasswordLessLogin,

        /**
         * A layout to complete password-less login with the authorization code
         * and credentials flow via username and previously requested one-time-
         * passcode
         */
        CompletePasswordLessLogin,

        /** A layout for authorization code and credentials flow via username and password */
        Login
    }
}
