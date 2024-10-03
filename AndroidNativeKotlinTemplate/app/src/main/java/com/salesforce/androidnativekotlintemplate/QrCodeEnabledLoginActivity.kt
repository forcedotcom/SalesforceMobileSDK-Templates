package com.salesforce.androidnativekotlintemplate

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.View.VISIBLE
import android.widget.Button
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanIntentResult.parseActivityResult
import com.journeyapps.barcodescanner.ScanOptions
import com.salesforce.androidnativekotlintemplate.R.id.qr_code_login_button
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.ui.LoginActivity
import org.json.JSONObject
import java.net.URLDecoder

/**
 * A subclass of Salesforce Mobile SDK's login activity that enables log in via a Salesforce
 * Identity API UI Bridge frontdoor URL obtained from a QR code.
 *
 * This class provides an in-app QR code scanner and can also be started from an intent with the
 * QR code URL.
 *
 * This class provides a default implementation for parsing the format of the QR code login URL.
 * This class can still be used with custom QR code login URL formats.
 *
 * TODO: Document API for custom URL formats. ECJ20241003
 *
 * If an app does not wish to use this feature, this class can be removed and the superclass used
 * directly.
 */
// This class is only required when enabling log in via Salesforce UI Bridge API generated QR codes
class QrCodeEnabledLoginActivity : LoginActivity() {

    // region Activity Implementation

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Find and show the layout's QR code login button.
        findViewById<Button>(qr_code_login_button).visibility = VISIBLE
    }

    // endregion
    // region User Interface Events

    /**
     * An action for the "Log In With QR Code" button which starts the QR code reader.
     * @param view The button the user tapped
     */
    fun onLoginWithQrCodeTapped(
        @Suppress("UNUSED_PARAMETER") view: View?
    ) = loginWithQrCodeActivityResultLauncher.launch(
        ScanContract().createIntent(
            this,
            ScanOptions()
        )
    )

    // endregion
    // region Public Implementation For QR Code Log In

    /**
     * Automatically log in using a QR code login URL and Salesforce Identity API UI Bridge.
     * @param qrCodeLoginUrl The QR code login URL
     * @return Boolean true if a log in attempt is possible using the provided QR code log in URL,
     * false otherwise
     */
    private fun useQrCodeLoginUrl(
        qrCodeLoginUrl: String?
    ) = uiBridgeApiParametersFromQrCodeLoginUrl(
        qrCodeLoginUrl
    )?.let { uiBridgeApiParameters ->
        loginWithFrontdoorBridgeUrl(
            uiBridgeApiParameters.frontdoorBridgeUrl,
            uiBridgeApiParameters.pkceCodeVerifier
        )
        true
    } ?: false

    // endregion
    // region Private Implementation For QR Code Log In

    /** An activity result launcher that receives the scanned QR code and starts login */
    private var loginWithQrCodeActivityResultLauncher = registerForActivityResult(
        StartActivityForResult()
    ) { resultData: ActivityResult ->
        if (resultData.resultCode == RESULT_OK) {
            parseActivityResult(
                resultData.resultCode,
                resultData.data
            ).contents?.let { qrCodeLoginUrl ->
                useQrCodeLoginUrl(qrCodeLoginUrl)
            }
        }
    }

    // endregion
    // region Companion

    companion object {

        // region QR Code Login Via Salesforce Identity API UI Bridge Public Implementation

        /**
         * For QR code login URLs, the URL path which distinguishes them from other URLs provided by
         * the app's internal QR code reader or deep link intents from external QR code readers.
         *
         * Apps may customize this so long as it matches the server-side Apex class or other code
         * generating the QR code.
         *
         * Apps need not use the QR code login URL structure provided in this companion object if
         * they wish to entirely customize the QR code login URL format and implement a custom
         * parsing scheme.
         *
         * TODO: Document API for custom parsing. ECJ20241003
         */
        private var qrCodeLoginUrlPath = "/login/qr"

        /**
         * For QR code login URLs, the URL query string parameter name for the Salesforce Identity
         * API UI Bridge parameters JSON object.
         *
         * Apps may customize this so long as it matches the server-side Apex class or other code
         * generating the QR code.
         */
        private var qrCodeLoginUrlJsonParameterName = "bridgeJson"

        /**
         * For QR code login URLs, the Salesforce Identity API UI Bridge parameters JSON key for the
         * frontdoor URL.
         *
         * Apps may customize this so long as it matches the server-side Apex class or other code
         * generating the QR code.
         */
        private var qrCodeLoginUrlJsonFrontdoorBridgeUrlKey = "frontdoor_bridge_url"

        /**
         * For QR code login URLs, the Salesforce Identity API UI Bridge parameters JSON key for the
         * PKCE code verifier, which is only used when the front door URL was generated for the web
         * server authorization flow.  The user agent flow does not require a value for this
         * parameter.
         *
         * Apps may customize this so long as it matches the server-side Apex class or other code
         * generating the QR code.
         */
        private var qrCodeLoginUrlJsonPkceCodeVerifierKey = "pkce_code_verifier"

        // endregion
        // region QR Code Login Via Salesforce Identity API UI Bridge Private Implementation

        /**
         * For QR code login URLs, a regular expression to extract the Salesforce Identity API UI
         * Bridge parameter JSON string.
         *
         * Apps may need to customize this if the format of the QR code login URL is customized.
         */
        private val qrCodeLoginJsonRegexExternal by lazy {
            """\?$qrCodeLoginUrlJsonParameterName=(\{.*\})""".toRegex()
        }

        /**
         * For QR code login URLs, a regular expression to extract the Salesforce Identity API UI
         * Bridge parameter JSON string.
         *
         * Apps may need to customize this if the format of the QR code login URL is customized.
         */
        // TODO: Determine if this is needed. ECJ20241003
        private val qrCodeLoginJsonRegexInternal by lazy {
            """\?$qrCodeLoginUrlJsonParameterName=(%7B.*%7D)""".toRegex()
        }

        /**
         * When QR code log in is enabled, determines if the provided intent has QR code login
         * parameters.
         * @param intent The intent to determine QR code login enablement for
         * @return Boolean true if the intent has QR code login parameters or false otherwise
         */
        fun isQrCodeLoginIntent(
            intent: Intent
        ) = SalesforceSDKManager.getInstance().isQrCodeLoginEnabled
                && intent.data?.path?.contains(qrCodeLoginUrlPath) == true

        /**
         * Parses Salesforce Identity API UI Bridge parameters from the provided login QR code login
         * URL.
         * @param qrCodeLoginUrl The QR code login URL
         * @return The UI Bridge API parameters or null if the QR code login URL cannot provide them
         * for any reason
         */
        internal fun uiBridgeApiParametersFromQrCodeLoginUrl(
            qrCodeLoginUrl: String?
        ) = qrCodeLoginUrl?.let { qrCodeLoginUrlUnwrapped ->
            uiBridgeApiJsonFromQrCodeLoginUrl(qrCodeLoginUrlUnwrapped)?.let { uiBridgeApiJson ->
                uiBridgeApiParametersFromUiBridgeApiJson(uiBridgeApiJson)
            }
        }

        /**
         * Parses Salesforce Identity API UI Bridge parameters JSON string from the provided QR code
         * login URL.
         *
         * @param qrCodeLoginUrl The QR code login URL
         * @return String: The UI Bridge API parameter JSON or null if the QR code login URL cannot
         * provide the JSON for any reason
         */
        private fun uiBridgeApiJsonFromQrCodeLoginUrl(
            qrCodeLoginUrl: String
        ) = qrCodeLoginJsonRegexExternal.find(qrCodeLoginUrl)?.groups?.get(1)?.value
            ?: qrCodeLoginJsonRegexInternal.find(qrCodeLoginUrl)?.groups?.get(1)?.value?.let {
                URLDecoder.decode(it, "UTF-8")
            }

        /**
         * Creates Salesforce Identity API UI Bridge parameters from the provided JSON string.
         * @param uiBridgeApiParameterJsonString The UI Bridge API parameters JSON string
         * @return The UI Bridge API parameters
         */
        private fun uiBridgeApiParametersFromUiBridgeApiJson(
            uiBridgeApiParameterJsonString: String
        ) = JSONObject(uiBridgeApiParameterJsonString).let { uiBridgeApiParameterJson ->
            UiBridgeApiParameters(
                uiBridgeApiParameterJson.getString(qrCodeLoginUrlJsonFrontdoorBridgeUrlKey),
                when (uiBridgeApiParameterJson.has(qrCodeLoginUrlJsonPkceCodeVerifierKey)) {
                    true -> uiBridgeApiParameterJson.optString(qrCodeLoginUrlJsonPkceCodeVerifierKey)
                    else -> null
                }
            )
        }

        /**
         * A data class representing Salesforce Identity API UI Bridge parameters.
         */
        internal data class UiBridgeApiParameters(

            /** The front door bridge URL */
            val frontdoorBridgeUrl: String,

            /** The PKCE code verifier */
            val pkceCodeVerifier: String?
        )

        // endregion
    }

    // endregion
}
