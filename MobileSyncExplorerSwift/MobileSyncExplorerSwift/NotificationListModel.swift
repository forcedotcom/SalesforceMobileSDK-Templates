//
//  NotificationListModel.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 5/28/20.
//  Copyright © 2020 MobileSyncExplorerSwiftOrganizationName. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import SalesforceSDKCore

class Notification: Decodable {
    let id: String
    let title: String
    let body: String
    let imageURL: String
    let targetId: String
    let prettyDate: String
    var read: Bool
    var seen: Bool
    var image = UIImage(named: "ProfileDefault")!

    private var imageCancellable: AnyCancellable?
    private var cancellableSet: Set<AnyCancellable> = []

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "messageTitle"
        case body = "messageBody"
        case read = "read"
        case seen = "seen"
        case imageURL = "image"
        case targetId = "target"
        case lastModified = "lastModified"
    }

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter
    }()

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.body = try container.decode(String.self, forKey: .body)
        self.imageURL = try container.decode(String.self, forKey: .imageURL)
        self.targetId = try container.decode(String.self, forKey: .targetId)
        self.read = try container.decode(Bool.self, forKey: .read)
        self.seen = try container.decode(Bool.self, forKey: .seen)

        let dateString = try container.decode(String.self, forKey: .lastModified)
        if let date = FormatUtils.getDateFromIsoDateString(dateString) {
            self.prettyDate = Notification.dateFormatter.string(from: date)
        } else {
            self.prettyDate = ""
        }
        fetchPhoto()
    }

    func fetchPhoto() {
        let request = RestRequest.init(method: .GET, path: imageURL, queryParams: nil)
        RestClient.shared.publisher(for: request)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    SalesforceLogger.e(Notification.self, message: "Error getting image: \(error)")
                }
            }, receiveValue: { response in
                if let image = UIImage(data: response.asData()) {
                    self.image = image
                } else {
                    SalesforceLogger.e(Notification.self, message: "Unable create UIImage from response")
                }
            })
            .store(in: &cancellableSet)
    }
}

struct NotificationResponse: Decodable {
    var notifications: [Notification]
}

class NotificationListModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var image: UIImage?
    private var cancellableSet: Set<AnyCancellable> = []

    func unreadCount() -> Int {
        return notifications.filter { !$0.read }.count
    }

    func fetchNotifications() {
        let builder = FetchNotificationsRequestBuilder.init()
        builder.setBefore(Date())
        builder.setSize(5)
        let request = builder.buildFetchNotificationsRequest(SFRestDefaultAPIVersion)

        RestClient.shared.publisher(for: request)
            .receive(on: RunLoop.main)
            .tryMap { $0.asData() }
            .decode(type: NotificationResponse.self, decoder: JSONDecoder())
            .map { response -> [Notification] in
                response.notifications
            }
            .catch { error -> Just<[Notification]> in
                SalesforceLogger.e(NotificationListModel.self, message: "Error getting notifications: \(error)")
                return Just([Notification]())
            }
            .assign(to: \.notifications, on: self)
            .store(in: &cancellableSet)
    }

    func markNotificationsSeen() {
        for index in 0 ..< notifications.count {
            notifications[index].seen = false
        }

        let notificationIds = notifications.map({ $0.id })
        if notificationIds.count > 0 {
            let builder = UpdateNotificationsRequestBuilder()
            builder.setSeen(true)
            builder.setNotificationIds(notificationIds)
            let request = builder.buildUpdateNotificationsRequest(SFRestDefaultAPIVersion)

            RestClient.shared.publisher(for: request)
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        SalesforceLogger.e(NotificationListModel.self, message: "Error setting notifications seen: \(error)")
                    }
                }, receiveValue: {_ in})
                .store(in: &cancellableSet)
        }
    }
}
