package com.salesforce.androidnativekotlintemplate

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.registerReceiver
import androidx.core.net.toUri
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanIntentResult.parseActivityResult
import com.journeyapps.barcodescanner.ScanOptions
import com.salesforce.androidnativekotlintemplate.R.string.login_with_qr_code
import com.salesforce.androidsdk.accounts.UserAccountManager.USER_SWITCH_INTENT_ACTION
import com.salesforce.androidsdk.ui.LoginActivity
import com.salesforce.androidsdk.ui.LoginViewModel.BottomBarButton

/**
 * A subclass of Salesforce Mobile SDK's login activity that enables log in via
 * a Salesforce Identity API UI Bridge frontdoor URL obtained from a QR code.
 *
 * This class provides an in-app QR code scanner and can also be started from an
 * intent with the QR code URL.
 *
 * This class provides a default implementation for parsing the format of the QR
 * code login URL. This class can still be used with custom QR code login URL
 * formats.
 *
 * If an app does not wish to use this feature, this class can be removed and
 * the superclass used directly.
 */
// This class is only required when enabling log in via Salesforce UI Bridge API generated QR codes
class QrCodeEnabledLoginActivity : LoginActivity() {

    // region Activity Implementation

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create and register a broadcast intent receiver to finish this activity on successful authentication.
        finishOnUserSwitchBroadcastReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent) {
                /*
                 * Note: When this activity starts the intent for main activity
                 * after scanning the QR code, finishing prior to log in
                 * completion would also finish the activities being used for
                 * the in-progress log in.
                 *
                 * If the main activity intent could be started in such a way
                 * that this activity could finish immediately after starting
                 * the intent, this receiver wouldn't be needed.
                 */
                if (intent.action == USER_SWITCH_INTENT_ACTION) finish()
            }
        }
        registerReceiver(
            this,
            finishOnUserSwitchBroadcastReceiver,
            IntentFilter(USER_SWITCH_INTENT_ACTION),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )

        // Add the Log In With QR Code custom button.
        viewModel.customBottomBarButton.value = BottomBarButton(getString(login_with_qr_code)) {
            onLoginWithQrCodeTapped()
        }
    }

    // endregion
    // region User Interface Events

    /**
     * An action for the "Log In With QR Code" button which starts the QR code reader.
     */
    private fun onLoginWithQrCodeTapped() = loginWithQrCodeActivityResultLauncher.launch(
        ScanContract().createIntent(
            this,
            ScanOptions()
        )
    )

    // endregion
    // region Private Implementation For QR Code Log In

    /** A broadcast intent receiver to finish this activity on successful authentication. */
    private var finishOnUserSwitchBroadcastReceiver: BroadcastReceiver? = null

    /** An activity result launcher that receives the scanned QR code and starts login */
    private var loginWithQrCodeActivityResultLauncher = registerForActivityResult(
        StartActivityForResult()
    ) { resultData: ActivityResult ->
        if (resultData.resultCode == RESULT_OK) {
            parseActivityResult(
                resultData.resultCode,
                resultData.data
            ).contents?.let { qrCodeLoginUrl ->
                startActivity(Intent(
                    this,
                    MainActivity::class.java
                ).apply {
                    data = qrCodeLoginUrl.toUri()
                })
            }
        }
    }

    // endregion
}