//
//  AppDelegate.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/27.
//

import UIKit
import ZCCalendar
import WidgetKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DataManager.shared.syncSharedData()
        
        BackupManager.shared.registerBGTasks()
        
        _ = NotificationManager.shared
        
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleBGTasks), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cancelBGTasks), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSharedData), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSharedData), name: UIApplication.willResignActiveNotification, object: nil)
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        
        return sceneConfig
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
    func updateSharedData() {
        DataManager.shared.syncSharedData()
        reloadWidget()
    }
    
    func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
