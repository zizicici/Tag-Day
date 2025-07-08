//
//  NotificationManager.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/6/27.
//

import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    struct Config: Hashable {
        var id: String
        var bookTitle: String
        var bookID: Int64
        var notificationTime: Int64?
        var notificationText: String?
        var repeatWeekday: String?
        
        init?(bookConfig: BookConfig) {
            guard let book = try? DataManager.shared.fetchBook(id: bookConfig.bookID) else { return nil }
            self.id = "book_\(bookConfig.bookID)"
            self.bookTitle = book.title
            self.bookID = bookConfig.bookID
            self.notificationTime = bookConfig.notificationTime
            self.notificationText = bookConfig.notificationText
            self.repeatWeekday = bookConfig.repeatWeekday
        }
    }
    
    static let shared = NotificationManager()
    
    private var notificationConfig: [Config] {
        didSet {
            if oldValue != notificationConfig {
                udpateBookNotifications()
            }
        }
    }
    
    init() {
        notificationConfig = (try? DataManager.shared.fetchAllBookConfigs().compactMap({ Config(bookConfig: $0) })) ?? []
        udpateBookNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .DatabaseUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    @objc
    func reloadData() {
        notificationConfig = (try? DataManager.shared.fetchAllBookConfigs().compactMap({ Config(bookConfig: $0) })) ?? []
    }
}

extension NotificationManager {
    func udpateBookNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for config in notificationConfig {
            setupNotification(for: config)
        }
    }
    
    func setupNotification(for config: Config) {
        guard let notificationTime = config.notificationTime else { return }
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = config.bookTitle
        content.body = config.notificationText ?? String(localized: "notification.placeholder")
        content.sound = .default
        content.userInfo["bookID"] = config.bookID
        
        var dateComponents = DateComponents()
        dateComponents.hour = Int(notificationTime) / 3600 / 1000
        dateComponents.minute = Int(notificationTime) % (3600 * 1000) / 60000
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: config.id,
                                            content: content,
                                            trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            }
        }
    }
}
