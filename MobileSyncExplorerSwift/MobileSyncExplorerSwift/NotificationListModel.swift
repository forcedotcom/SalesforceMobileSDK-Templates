//
//  NotificationListModel.swift
//  MobileSyncExplorerSwift
//
//  Created by Brianna Birman on 7/9/20.
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
    var image = UIImage(named: "profileDefault")!

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
            }, receiveValue: { [weak self] response in
                if let image = UIImage(data: response.asData()) {
                    self?.image = image
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
        var notificationIds = [String]()
        for index in 0 ..< notifications.count {
            if !notifications[index].seen {
                notificationIds.append(notifications[index].id)
            }
        }

        if notificationIds.count > 0 {
            let builder = UpdateNotificationsRequestBuilder()
            builder.setSeen(true)
            builder.setNotificationIds(notificationIds)
            let request = builder.buildUpdateNotificationsRequest(SFRestDefaultAPIVersion)

            RestClient.shared.publisher(for: request)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                         SalesforceLogger.e(NotificationListModel.self, message: "Error setting notifications seen: \(error)")
                    case .finished:
                        self?.fetchNotifications()
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellableSet)
        }
    }

    public func markNotificationRead(notificationId: String) {
        let notificationIndex = notifications.firstIndex { (notification) -> Bool in
            notification.id == notificationId
        }
        guard let index = notificationIndex, !notifications[index].read else {
           return
        }

        let builder = UpdateNotificationsRequestBuilder()
        builder.setRead(true)
        builder.setNotificationId(notificationId)
        let request = builder.buildUpdateNotificationsRequest(SFRestDefaultAPIVersion)

        RestClient.shared.publisher(for: request)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                     SalesforceLogger.e(NotificationListModel.self, message: "Error setting notification read: \(error)")
                case .finished:
                    self?.fetchNotifications()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellableSet)
    }
}
