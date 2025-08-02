//
//  AppDelegate.swift
//  Tag Day
//
//  Created by Ci Zi on 2025/4/27.
//

import UIKit
import ZCCalendar
import WidgetKit
import StoreKit

extension UserDefaults {
    enum Support: String {
        case AppReviewRequestDate = "com.zizicici.common.support.AppReviewRequestDate"
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DataManager.shared.syncSharedData()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
            self.requestAppReview()
        }
        
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

extension AppDelegate {
    func requestAppReview() {
        do {
            guard let creationDate = try AppDatabase.getDatabaseCreationDate() else { return }
            guard let daysSinceCreation = Calendar.current.dateComponents([.day], from: creationDate, to: Date()).day else { return }
            guard daysSinceCreation >= 10 else { return }
            
            let userDefaultsFlag: Bool
            let userDefaultsKey = UserDefaults.Support.AppReviewRequestDate.rawValue
            if let storedJDN = UserDefaults.standard.getInt(forKey: userDefaultsKey) {
                userDefaultsFlag = (ZCCalendar.manager.today.julianDay - storedJDN) >= 180
            } else {
                userDefaultsFlag = true
            }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, userDefaultsFlag {
                UserDefaults.standard.set(ZCCalendar.manager.today.julianDay, forKey: userDefaultsKey)
                AppStore.requestReview(in: windowScene)
            }
        } catch {
            print("\(error.localizedDescription)")
        }
    }
}
