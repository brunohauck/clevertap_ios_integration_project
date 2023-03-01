//
//  AppDelegate.swift
//  clevertappoc
//
//  Created by Bruno Hauck on 13/12/21.
//

/*
import UIKit
import CleverTapSDK
@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        CleverTap.autoIntegrate()
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

}*/

import UIKit
import UserNotifications
import CleverTapSDK
import WatchConnectivity

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, WCSessionDelegate, CleverTapPushNotificationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // register for push notifications
        registerForPush()
        
        // Configure and init the default shared CleverTap instance (add CleverTap Account ID and Account Token in your .plist file)
        CleverTap.autoIntegrate()
        CleverTap.setDebugLevel(CleverTapLogLevel.off.rawValue)
        CleverTap.sharedInstance()?.enableDeviceNetworkInfoReporting(true)
        CleverTap.setPushNotificationDelegate(self)
        // Configure and init an additional instance
        let ctConfig = CleverTapInstanceConfig.init(accountId: "TEST-WRZ-ZW9-8K6Z", accountToken: "TEST-c01-120")
        ctConfig.logLevel = .off
        ctConfig.disableIDFV = true
        let cleverTapAdditionalInstance = CleverTap.instance(with: ctConfig)
        NSLog("additional CleverTap instance created for accountID: %@", cleverTapAdditionalInstance.config.accountId)
        
        cleverTapAdditionalInstance.setPushNotificationDelegate(self)
        
        self.registerPush()
        
        // watchOS session
        checkSession()
        
        return true
    }
    
    
      private func registerPush() {
          
          // register category with actions
          let action1 = UNNotificationAction(identifier: "action_1", title: "Back", options: [])
          let action2 = UNNotificationAction(identifier: "action_2", title: "Next", options: [])
          let action3 = UNNotificationAction(identifier: "action_3", title: "View In App", options: [])
          let category = UNNotificationCategory(identifier: "CTNotification", actions: [action1, action2, action3], intentIdentifiers: [], options: [])
          UNUserNotificationCenter.current().setNotificationCategories([category])
          
          // request permissions
          UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert, .badge]) {
              (granted, error) in
              if (granted) {
                  DispatchQueue.main.async {
                      UIApplication.shared.registerForRemoteNotifications()
                  }
              }
          }
      }
    
    func checkSession() {
        guard WCSession.isSupported() else {
            print("Session is not supported")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
  
    // MARK: - Setup Push Notifications
    
    func registerForPush() {
        // Register for Push notifications
        UNUserNotificationCenter.current().delegate = self
        // request Permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert], completionHandler: {granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        })
    }
    
    // MARK: - Notification Delegates
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("%@: failed to register for remote notifications: %@", self.description, error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("%@: registered for remote notifications: %@", self.description, deviceToken.description)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        NSLog("%@: did receive notification response: %@", self.description, response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        NSLog("%@: will present notification: %@", self.description, notification.request.content.userInfo)
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: notification.request.content.userInfo)
        completionHandler([.badge, .sound, .alert])
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("%@: did receive remote notification completionhandler: %@", self.description, userInfo)
        completionHandler(UIBackgroundFetchResult.noData)
    }
    
    func pushNotificationTapped(withCustomExtras customExtras: [AnyHashable : Any]!) {
        NSLog("pushNotificationTapped: customExtras: ", customExtras)
    }
    
    // MARK: - Handle URL
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        NSLog("%@: open  url: %@ with options: %@", self.description, url.absoluteString, options)
        return true
    }
    
    // MARK: - Application Life cycle

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: - WCSessionDelegate
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // no-op for demo purposes
    }
    
    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        // no-op for demo purposes
    }
    
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        // no-op for demo purposes
    }
    
    /*
    /** Called on the delegate of the receiver. Will be called on startup if the incoming message caused the receiver to launch. */
    @available(iOS 9.0, *)
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let handled = CleverTap.sharedInstance()?.handleMessage(message, forWatch: session)
        if (!handled!) {
            // handle the message as its not a CleverTap Message
        }
    }
    
    /** Called on the delegate of the receiver when the sender sends a message that expects a reply. Will be called on startup if the incoming message caused the receiver to launch. */
    @available(iOS 9.0, *)
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
        let handled = CleverTap.sharedInstance()?.handleMessage(message, forWatch: session)
        if (!handled!) {
            // handle the message as its not a CleverTap Message
        }
    }*/
}



