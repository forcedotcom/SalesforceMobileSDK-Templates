/*
 * Copyright (c) 2026-present, salesforce.com, inc.
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
package com.salesforce.androidnativekotlintemplate

import android.Manifest.permission.POST_NOTIFICATIONS
import android.app.PendingIntent.FLAG_IMMUTABLE
import android.app.PendingIntent.getBroadcast
import android.content.Intent
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Build.VERSION_CODES.Q
import android.os.Bundle
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.BigTextStyle
import androidx.core.app.NotificationCompat.PRIORITY_DEFAULT
import androidx.core.app.NotificationManagerCompat
import com.salesforce.androidnativekotlintemplate.MainApplication.Companion.BROADCAST_INTENT_ACTION_INVOKE_SALESFORCE_NOTIFICATION_ACTION
import com.salesforce.androidsdk.R.drawable.sf__salesforce_logo
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.push.PushNotificationInterface
import com.salesforce.androidsdk.push.SalesforceActionableNotificationContent
import java.util.UUID.randomUUID

/**
 * An implementation of Salesforce Mobile SDK's push notifications interface
 * which adapts to receiving actionable notifications.
 *
 * Much of this class is focused on routine push notifications set up.  Apps
 * are free to implement this as they see fit.  Where set up is more specific
 * to actionable notifications additional details are provided in the comments.
 */
/* Actionable Notifications Template: When not using [PushNotificationsAdapter] and Actionable Notifications, this could be removed. */
internal class PushNotificationsAdapter : PushNotificationInterface {

    @RequiresApi(Q)
    override fun onPushMessageReceived(
        data: Map<String?, String?>?,
    ) {

        val salesforceSdkManager = SalesforceSDKManager.getInstance()
        val context = salesforceSdkManager.appContext
        val notificationManager = NotificationManagerCompat.from(context)

        // Guard such that no notification will be attempted when notifications are disabled.
        if (!notificationManager.areNotificationsEnabled()) return

        // Marshall the Salesforce actionable notification content.
        /*
         * Actionable Notifications: Apps can use
         * `SalesforceActionableNotificationContent` marshal the content of a
         * Salesforce Actionable Notification into a convenient object.
         */
        val actionableNotificationContent = data?.get("content")?.let {
            SalesforceActionableNotificationContent.fromJson(it)
        }?.sfdc ?: return

        // Fetch the actionable notifications type.
        /*
         * Actionable Notifications: Salesforce SDK Manager provides a method to
         * resolve the Salesforce Actionable Notification Type from the
         * content of the notification.  This will be used to determine the
         * Android notification channel id.
         */
        val actionableNotificationsType = actionableNotificationContent.notifType?.let { actionableNotificationsType ->
            salesforceSdkManager.getNotificationsType(actionableNotificationsType)
        }

        // Verify required notification properties.
        val alertTitle = actionableNotificationContent.alertTitle ?: return
        val alert = actionableNotificationContent.alert ?: return
        val alertBody = actionableNotificationContent.alertBody ?: return

        // Initialize a notification builder for the notification.
        /*
         * Actionable Notifications: The notification builder uses the
         * Salesforce Actionable Notification Type to determine the Android
         * notification channel id.
         */
        NotificationCompat.Builder(
            context,
            actionableNotificationsType?.type ?: return
        ).apply {
            priority = PRIORITY_DEFAULT
            // Add actions to the notification.
            /*
             * Actionable Notifications: The Salesforce Actionable Notification
             * Type provides the actions to add to the notification.
             */
            actionableNotificationsType
                .actionGroups
                ?.firstOrNull { actionGroup ->
                    actionGroup.name == actionableNotificationContent.act?.group
                }?.let { actionGroup ->
                    actionGroup.actions?.forEach { action ->
                        addAction(
                            sf__salesforce_logo,
                            action.label ?: return@forEach,
                            getBroadcast(
                                context,
                                0,
                                /*
                                 * Actionable Notifications: The two extras in
                                 * this intent are used by the app to invoke the
                                 * matching Salesforce Actionable Notification
                                 * Action.
                                 */
                                Intent(BROADCAST_INTENT_ACTION_INVOKE_SALESFORCE_NOTIFICATION_ACTION).apply {
                                    identifier = randomUUID().toString()
                                    putExtras(Bundle().apply {
                                        putString(
                                            NOTIFICATION_EXTRAS_KEY_SALESFORCE_ACTIONABLE_NOTIFICATION_ID,
                                            actionableNotificationContent.nid
                                        )
                                        putString(
                                            NOTIFICATION_EXTRAS_KEY_SALESFORCE_ACTIONABLE_NOTIFICATION_ACTION_KEY,
                                            action.actionKey
                                        )
                                    })
                                },
                                FLAG_IMMUTABLE
                            )
                        )
                    }
                }
            setContentTitle(alertTitle)
            setContentText(alert)
            setSmallIcon(sf__salesforce_logo)
            setStyle(BigTextStyle().bigText(alertBody))
        }.also { builder ->

            // Build and display the notification, if possible.
            if (context.checkSelfPermission(POST_NOTIFICATIONS) == PERMISSION_GRANTED) {
                notificationManager.notify(
                    actionableNotificationContent.nid?.hashCode() ?: 0,
                    builder.build()
                )
            }
        }
    }

    override fun supplyFirebaseMessaging() = null

    // region Companion

    companion object {

        // region Notifications

        /** Notification Intent Extra Keys: Salesforce actionable notification id */
        internal const val NOTIFICATION_EXTRAS_KEY_SALESFORCE_ACTIONABLE_NOTIFICATION_ID = "SALESFORCE_ACTIONABLE_NOTIFICATION_ID"

        /** Notification Intent Extra Keys: Salesforce actionable notification action key */
        internal const val NOTIFICATION_EXTRAS_KEY_SALESFORCE_ACTIONABLE_NOTIFICATION_ACTION_KEY = "SALESFORCE_ACTIONABLE_NOTIFICATION_ACTION_KEY"

        // endregion
    }
}
