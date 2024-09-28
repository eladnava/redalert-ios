//
//  AppDelegate.swift
//  RedAlert
//
//  Created by Elad on 10/14/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // iOS 12+ support (Critical Alerts)
        if #available(iOS 12, *) {
            // For in-app notifications
            UNUserNotificationCenter.current().delegate = self
            
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound, .criticalAlert]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
        // iOS 10+ support
        else if #available(iOS 10, *) {
            // For in-app notifications
            UNUserNotificationCenter.current().delegate = self
            
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
        // iOS 8+ support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        // Fallback (iOS 7 and under)
        else {
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
        
        // All done        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Get device token        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Get device language        
        let language = Localization.getDeviceLanguageCode()
        
        // First time?        
        if (!RedAlertAPI.isRegistered()) {
            // Create a new user            
            RedAlertAPI.registerAsync(token: token, language: language, delegate: self)
        }
        else {
            // Check whether token changed            
            if (RedAlertAPI.isNewToken(token: token)) {
                // Update it                
                RedAlertAPI.updateTokenAsync(token: token)
            }
            
            // Check if we need to ask user to reselect cities due to HFC changes
            if (RedAlertAPI.shouldRequestCityReselection()) {
                // Get localized strings
                let title = NSLocalizedString("REGISTRATION_SUCCESS_TITLE", comment: "Registration success title")
                let message = NSLocalizedString("REGISTRATION_SUCCESS_RESELECT_MESSAGE", comment: "Registration success reselect message")
                
                // Show success message
                Dialogs.message(title: title, message: message, delegate: self)
                
                // Asked user to reselect cities
                return RedAlertAPI.setCityReselectionRequested()
            }
        }
    }
    
    // Display in-app notification banners (iOS 10+)
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {        
        // Show in-app banner & play sound
        completionHandler([.alert, .sound])
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        // OK clicked?        
        if (buttonIndex == 0) {
            // Take user to city selection
            showZoneSelection()
        }
    }
    
    func showZoneSelection() {
        // Show selector control        
        if let controller = self.window?.rootViewController! as! UINavigationController? {
            // Create VC using storyboard ID            
            let settings = controller.storyboard!.instantiateViewController(withIdentifier: "Settings") as! SettingsViewController
            
            // Ask to show city selection
            settings.selectCities = true
            
            // Push it into nav stack            
            controller.pushViewController(settings, animated: true)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Show the error        
        Dialogs.error(message: NSLocalizedString("PUSH_ERROR", comment: "Push registration error message"))
    }
}

