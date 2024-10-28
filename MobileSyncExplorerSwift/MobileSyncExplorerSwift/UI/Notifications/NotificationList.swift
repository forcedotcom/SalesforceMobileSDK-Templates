//
//  NotificationList.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 6/20/20.
//  Copyright (c) 2020-present, salesforce.com, inc. All rights reserved.
//
//  Redistribution and use of this software in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright notice, this list of conditions
//  and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials provided
//  with the distribution.
//  * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission of salesforce.com, inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import SwiftUI

struct NotificationList: View {
    @ObservedObject var model: NotificationListModel
    var sObjectDataManager: SObjectDataManager

    var body: some View {
        VStack {
            if model.notifications.count > 0 {
                ListView(model: model, sObjectDataManager: sObjectDataManager)
            } else {
                EmptyNotificationsView()
            }
        }
        .navigationBarTitle("Notifications")
        .onAppear {
            self.model.markNotificationsSeen()
        }
    }
}

struct ListView: View {
    @ObservedObject var model: NotificationListModel
    var sObjectDataManager: SObjectDataManager

    var body: some View {
        List {
            ForEach(model.notifications, id: \.id) { notification in
                VStack {
                    if notification.targetId.starts(with: "003") { // Only contacts are tappable
                        NavigationLink(destination: ContactDetailView(id: notification.targetId, sObjectDataManager: self.sObjectDataManager, onAppear: {
                            self.model.markNotificationRead(notificationId: notification.id)
                        })) {
                            NotificationCell(notification: notification)
                        }
                    } else {
                        NotificationCell(notification: notification)
                    }
                }
                .listRowBackground(notification.read ? Color.clear : Color.unreadNotificationBackground)
            }
        }
    }
}

struct NotificationCell: View {
    var notification: Notification

    var body: some View {
        HStack {
            Image(uiImage: notification.image).resizable().frame(width: 40, height: 40, alignment: .trailing)
            VStack(alignment: .leading) {
                Text(notification.title).bold()
                Text(notification.body).lineLimit(10).fixedSize(horizontal: false, vertical: true)
                Text(notification.prettyDate).font(.subheadline).foregroundColor(.secondaryLabelText)
            }
        }
    }
}

struct EmptyNotificationsView: View {
    var body: some View {
        VStack {
            Image(systemName: "bell").resizable().frame(width: 150, height: 175, alignment: .center)
            Text("No Notifications").font(.system(size: 18))
        }
        .foregroundColor(.secondaryLabelText)
        .padding(.bottom, 200)
    }
}
