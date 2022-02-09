//
//  RecentContactsWidget.swift
//  RecentContacts
//
//  Created by Brianna Birman on 1/21/22.
//  Copyright © 2022 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import WidgetKit
import SwiftUI
import SalesforceSDKCommon.SFSDKDatasharingHelper

struct Provider: TimelineProvider {
    init() {
        DataSharingHelper.shared.appGroupName = "group.com.salesforce.mobilesyncexplorer"
        DataSharingHelper.shared.isAppGroupEnabled = true
    }
    
    func placeholder(in context: Context) -> ContactsEntry {
        let contacts = [ContactSummary(id: "1", firstName: "Michelle", lastName: "Kim"),
                        ContactSummary(id: "2", firstName: "Jon", lastName: "Amos"),
                        ContactSummary(id: "3", firstName: "Howard", lastName: "Jones")]
        return ContactsEntry(date: Date(), contacts: contacts)
    }
    
    func currentEntry(context: Context) -> ContactsEntry {
        guard let contacts = RecentContacts.persistedContacts() else {
            return placeholder(in: context)
        }

        return ContactsEntry(date: Date(), contacts: contacts)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ContactsEntry) -> ()) {
        completion(currentEntry(context: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = ContactsEntry(date: Date(), contacts: RecentContacts.persistedContacts())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct ContactsEntry: TimelineEntry {
    var date: Date
    var contacts: [ContactSummary]?
}

struct Icon : View {
    let text: String?
    let imageName: String?
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 30, height: 30, alignment: .leading)
                .foregroundColor(.init(red: 1/255, green: 118/255, blue: 211/255))
            if let initials = text {
                Text(initials).font(.system(size: 12.0)).foregroundColor(.white)
            } else if let imageName = imageName {
                Image(systemName: imageName).foregroundColor(.white)
            }
        }
    }
}

struct Cell : View {
    let url: URL?
    let iconImageName: String?
    let iconInitials: String?
    let cellText: String?
    
    init(contact: ContactSummary?) {
        if let contact = contact {
            iconInitials =  ContactHelper.initialsStringFromContact(firstName: contact.firstName, lastName: contact.lastName)
            iconImageName = nil
            cellText = contact.firstName ?? contact.lastName ?? ""
            url = URL(string: "mobilesyncexplorerswift://contact/\(contact.id)")
        } else {
            iconImageName = "plus"
            iconInitials = nil
            cellText = "New"
            url = URL(string: "mobilesyncexplorerswift://contact/new")
        }
    }
    
    var body: some View {
        Link(destination: url!) {
            HStack {
                Icon(text: iconInitials, imageName: iconImageName)
                Text(cellText ?? "")
            }.padding(10)
        }
        .frame(minWidth: 125.0, maxWidth: 250.0, idealHeight: 50, alignment: .leading)
        .background(Color(uiColor: .systemFill))
        .cornerRadius(20)
    }
}


struct RecentContactsEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        let columns = [ GridItem(.adaptive(minimum: 125, maximum: 250), spacing: 20, alignment: .center)]

        VStack {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                if let contacts = entry.contacts {
                    ForEach(contacts, id: \.self) { contact in
                        Cell(contact: contact)
                    }
                }
                Cell(contact: nil)
            }
        }.padding()
    }
}

@main
struct RecentContactsWidget: Widget {
    let kind: String = "RecentContacts"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RecentContactsEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Contacts")
        .description("Recently viewed contacts")
        .supportedFamilies([.systemMedium])
    }
}

struct RecentContacts_Previews: PreviewProvider {
    static var previews: some View {
        let contacts =
        [ContactSummary(id: "1", firstName: "Michelle", lastName: "Kim"),
         ContactSummary(id: "2", firstName: "Benji", lastName: "Michaels"),
         ContactSummary(id: "3", firstName: "Edward", lastName: "Stamos"),
       ]
        
        Group {
            RecentContactsEntryView(entry: ContactsEntry(date: Date(), contacts: contacts))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
