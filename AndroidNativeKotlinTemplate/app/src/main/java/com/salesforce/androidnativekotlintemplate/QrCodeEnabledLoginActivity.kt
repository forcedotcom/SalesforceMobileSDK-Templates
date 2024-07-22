//package com.salesforce.androidnativekotlintemplate
//
//import android.content.Intent
//import android.os.Bundle
//import android.view.View
//import android.view.View.VISIBLE
//import android.widget.Button
//import androidx.activity.result.ActivityResult
//import androidx.activity.result.ActivityResultLauncher
//import androidx.activity.result.contract.ActivityResultContracts
//import com.journeyapps.barcodescanner.ScanContract
//import com.journeyapps.barcodescanner.ScanIntentResult
//import com.journeyapps.barcodescanner.ScanOptions
//import com.salesforce.androidnativekotlintemplate.R.id.qr_login_button
//import com.salesforce.androidsdk.ui.LoginActivity
//
///**
// * A subclass of Salesforce Mobile SDK's login activity that enables log in via
// * a Salesforce UI Bridge API generated QR code.  If an app wishes not to use
// * this feature, this class can be removed and use the superclass directly.
// *
// */
// // Uncomment when enabling log in via Salesforce UI Bridge API generated QR codes
//class QrCodeEnabledLoginActivity : LoginActivity() {
//
//    // region Activity Implementation
//
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//
//        findViewById<Button>(qr_login_button).visibility = VISIBLE
//        prepareQRReader()
//    }
//
//    // endregion
//    // region User Interface Events
//
//    /**
//     * An action for the "Log In With QR" button.
//     * @param view The button that the user tapped
//     */
//    fun onQRLoginClick(@Suppress("UNUSED_PARAMETER") view: View?) = startQrCodeReader()
//
//    // endregion
//    // region Private Implementation For QR Code Log In
//
//    private var qrCodeReaderActivityResultLauncher: ActivityResultLauncher<Intent>? = null
//
//    private fun prepareQRReader() {
//        qrCodeReaderActivityResultLauncher = registerForActivityResult(
//            ActivityResultContracts.StartActivityForResult()
//        ) { resultData: ActivityResult ->
//            if (resultData.resultCode == RESULT_OK) {
//
//                val result = ScanIntentResult.parseActivityResult(
//                    resultData.resultCode,
//                    resultData.data
//                )
//
//                result.contents?.let { qrCodeContent ->
//                    loginFromQrCode(qrCodeContent)
//                }
//            }
//        }
//    }
//
//    private fun startQrCodeReader() {
//        qrCodeReaderActivityResultLauncher?.launch(ScanContract().createIntent(this, ScanOptions()))
//    }
//
//    // endregion
//}
