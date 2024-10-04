package com.salesforce.androidnativekotlintemplate

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
import com.salesforce.androidsdk.ui.LoginActivity

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
                loginWithFrontdoorBridgeUrlFromQrCode(qrCodeLoginUrl)
            }
        }
    }

    // endregion
}
