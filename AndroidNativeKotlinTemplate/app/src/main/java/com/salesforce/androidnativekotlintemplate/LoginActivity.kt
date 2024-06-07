package com.salesforce.androidnativekotlintemplate

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanIntentResult
import com.journeyapps.barcodescanner.ScanOptions
import com.salesforce.androidnativekotlintemplate.R.id.qr_login_button

class LoginActivity : com.salesforce.androidsdk.ui.LoginActivity() {

    private var qrReaderLauncher: ActivityResultLauncher<Intent>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        findViewById<Button>(qr_login_button).visibility = View.VISIBLE
        prepareQRReader()
    }

    fun onQRLoginClick(view: View?) = presentQRReader()

    private fun prepareQRReader() {
        qrReaderLauncher = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { resultData: ActivityResult ->
            if (resultData.resultCode == RESULT_OK) {

                val result = ScanIntentResult.parseActivityResult(
                    resultData.resultCode,
                    resultData.data
                )

                if (result.contents != null) {
                    loginFromQR(result.contents)
                }
            }
        }
    }
    private fun presentQRReader() {
        qrReaderLauncher?.launch(ScanContract().createIntent(this, ScanOptions()))
    }

}