//
//  Tabs.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 8/12/24.
//  Copyright © 2024 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import SwiftUI
import SalesforceSDKCore

struct Tabs: View {
    var sObjectDataManager: SObjectDataManager
    let notificationListModel = NotificationListModel()
    
    var body: some View {
        TabView {
            ContactListView(sObjectManager: sObjectDataManager)
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .toolbarBackground(.visible, for: .tabBar)
            
            NotificationList(model: notificationListModel, sObjectDataManager: sObjectDataManager)
                .tabItem {
                    Label(title: {
                        Text("Notifications")
                    }, icon: {
                        NotificationBell(notificationModel:notificationListModel, sObjectDataManager: sObjectDataManager)
                    })
                }
                .toolbarBackground(.visible, for: .tabBar)
            
            Settings(sObjectDataManager: sObjectDataManager)
                .tabItem {
                    Label(title: {
                        Text("Settings")
                    }, icon: {
                        Image("setting").renderingMode(.template)
                    })
                }
                .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

#Preview {
    let credentials = OAuthCredentials(identifier: "test", clientId: "", encrypted: false)!
    let userAccount = UserAccount(credentials: credentials)
    let sObjectManager = SObjectDataManager.sharedInstance(for: userAccount)
    
    return Tabs(sObjectDataManager: sObjectManager)
}
