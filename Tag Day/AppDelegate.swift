//
//  AppDelegate.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/27.
//

import UIKit
import ZCCalendar

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        _ = DataManager.shared
        
        BackupManager.shared.registerBGTasks()
        
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleBGTasks), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelBGTasks), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(readSharedData), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSharedData), name: UIApplication.willResignActiveNotification, object: nil)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    @objc
    func cancelBGTasks() {
        BackupManager.shared.cancelBGTasks()
    }
    
    @objc
    func scheduleBGTasks() {
        BackupManager.shared.scheduleBGTasks()
    }
    
    @objc
    func readSharedData() {
        do {
            if let widgetAddDayRecords = try SharedDataManager.read(SharedData.self)?.widgetAddDayRecords, widgetAddDayRecords.count > 0 {
                widgetAddDayRecords.forEach{ _ = DataManager.shared.add(dayRecord: $0) }
                updateSharedData()
            }
        }
        catch {
            print(error)
        }
    }
    
    @objc
    func updateSharedData() {
        do {
            let books = try DataManager.shared.fetchAllBooks()
            let tags = try DataManager.shared.fetchAllTags()
            let dayRecords = try DataManager.shared.fetchAllDayRecords(after: Int64(ZCCalendar.manager.today.julianDay))
            let sharedData = SharedData(version: 1, books: books, tags: tags, dayRecord: dayRecords, widgetAddDayRecords: [])
            try SharedDataManager.write(sharedData)
        }
        catch {
            print(error)
        }
    }
}
