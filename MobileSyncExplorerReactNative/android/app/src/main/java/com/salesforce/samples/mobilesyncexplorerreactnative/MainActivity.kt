/*
 * Copyright (c) 2025-present, salesforce.com, inc.
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

package com.salesforce.samples.mobilesyncexplorerreactnative

import android.os.Build
import android.os.Bundle
import com.facebook.react.ReactActivityDelegate
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint.fabricEnabled
import com.facebook.react.defaults.DefaultReactActivityDelegate
import com.salesforce.androidsdk.reactnative.ui.SalesforceReactActivity
import com.salesforce.androidsdk.rest.RestClient

class MainActivity : SalesforceReactActivity() {

    // Tracks whether this activity was paused (e.g. while the Salesforce
    // LoginActivity is on top).  Used with setRestClient() to detect the
    // fresh-login transition.
    private var wasPaused = false

    //react-native-screens override
    @Override
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(null)
    }

    override fun onPause() {
        super.onPause()
        wasPaused = true
    }

    /**
     * Returns the name of the main component registered from JavaScript. This
     * is used to schedule rendering of the component.
     */
    override fun getMainComponentName() = "MobileSyncExplorerReactNative"

    /**
     * Returns the instance of the [ReactActivityDelegate]. We use
     * [DefaultReactActivityDelegate] which allows you to enable New
     * Architecture with a single boolean flags [fabricEnabled]
     */
    override fun createReactActivityDelegate() = DefaultReactActivityDelegate(this, mainComponentName, fabricEnabled)

    /**
     * Determines if login should occur on application launch or not.
     * @return True for login to occur on application launch, false otherwise
     */
    override fun shouldAuthenticate() = true

    /**
     * On Android 12L-14 (API 32-34) with React Native 0.81+ bridgeless
     * architecture, the ReactSurfaceView ends up sized 0x0 after the Salesforce
     * LoginActivity dismisses, producing a black screen.  The SDK's
     * restartReactNativeApp() path does not call back into this activity on
     * the OAuth flow, so we hook setRestClient() instead.  When we detect the
     * transition from "not logged in" to "logged in" after a pause (i.e. the
     * user just completed OAuth on top of this activity), we force a clean
     * activity recreate so React Native mounts fresh with the authenticated
     * user and a properly measured surface.  Subsequent setRestClient() calls
     * (e.g. on the recreated activity, or returning from background) take the
     * "already logged in" branch and do not recreate, so there is no loop.
     *
     * TODO: Remove this workaround when the issue is fixed in Mobile SDK 14.0.
     */
    override fun setRestClient(restClient: RestClient?) {
        val wasLoggedIn = getRestClient() != null
        super.setRestClient(restClient)
        val isBuggyApi = Build.VERSION.SDK_INT in Build.VERSION_CODES.S_V2..Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        if (isBuggyApi && wasPaused && !wasLoggedIn && restClient != null) {
            wasPaused = false
            recreate()
        }
    }
}