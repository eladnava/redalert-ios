//
//  RedAlertAPI.swift
//  RedAlert
//
//  Created by Elad on 10/15/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit

struct RedAlertAPI {
    static func isRegistered() -> Bool {
        // Do we have a stored ID?
        return !UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "").isEmpty
    }
    
    static func shouldRequestCityReselection() -> Bool {
        // Disable for now
        return false
    }
    
    static func setCityReselectionRequested() {
        // Set key as true to avoid asking user again for this version
        UserSettings.setBool(key: UserSettingsKeys.cityReselectionRequested, value: true)
    }
    
    static func canReceiveNotifications() -> Bool {
        // Did we register and can we receive Badge/Sound/Alert?        
        if (!isRegistered()) {
            return false
        }
        
        // iOS 8 notifications        
        if (UIApplication.shared.responds(to: #selector(getter: UIApplication.isRegisteredForRemoteNotifications))) {
            // iOS version check            
            if #available(iOS 8.0, *) {
                // Not registered?                
                if (!UIApplication.shared.isRegisteredForRemoteNotifications) {
                    return false
                }
            }
        }
        else {
            // < iOS 8            
            return UIApplication.shared.enabledRemoteNotificationTypes() == .alert
        }
        
        // We're good        
        return true
    }
    
    static func isNewToken(token: String) -> Bool {
        // Do we have a stored ID?        
        return UserSettings.getString(key: UserSettingsKeys.deviceToken, defaultValue: "") != token
    }
    
    static func registerAsync(token: String, language: String, delegate: UIAlertViewDelegate) {
        // Store token in user defaults in any case        
        UserSettings.setString(key: UserSettingsKeys.deviceToken, value: token)
        
        // Prepare post data        
        let params = ["token": token, "language": language, "platform": "ios"]
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/register", params: params as [String : AnyObject]) { (err: NSError?, json: NSDictionary?) -> () in
            
            // JSON parse error?            
            if let theErr = err {
                // Default message
                var message = NSLocalizedString("REGISTRATION_ERROR", comment: "Registration error message")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
            
            // Unwrap JSON            
            if let json = json {
                // Get user ID & hash                
                let id = json["id"] as? Int
                let hash = json["hash"] as? String
                
                // Did we get them back?
                if let _ = id {
                    UserSettings.setString(key: UserSettingsKeys.userHash, value: hash!)
                }
                
                // Store them in settings                
                if let _ = hash {
                    UserSettings.setString(key: UserSettingsKeys.userID, value: String(id!))
                }
                
                // Get localized strings                
                let title = NSLocalizedString("REGISTRATION_SUCCESS_TITLE", comment: "Registration success title")
                let message = NSLocalizedString("REGISTRATION_SUCCESS_MESSAGE", comment: "Registration success message")
                
                // Show success message                
                return Dialogs.message(title: title, message: message, delegate: delegate)
            }
        }
    }
        
    static func getAppUpdatesAsync(delegate: UIViewController) {
        // Execute post request        
        HTTP.getAsync(urlString: Config.apiBaseURL + "/update/ios", dictionary: true) { (err: NSError?, json: AnyObject?) -> () in
            
            // JSON parse error?            
            if let _ = err {
                // Fail silently                
                return
            }
            
            // Unwrap JSON            
            if let json = json as? NSDictionary {
                // Get build # and version                
                let showDialog = json["show_dialog"] as? Bool
                let latestVersion = json["version"] as? String
                let latestBuildNumber = json["version_code"] as? Int
                
                // Get our own build number                
                let installedBuild = Int(Bundle.main.infoDictionary!["CFBundleVersion"] as! String)
                
                // Compare build numbers                
                if (showDialog! && installedBuild! < latestBuildNumber!) {
                    // Create new alert view
                    let alert = UIAlertView()
                    
                    // Set delegate so we can capture tap event                    
                    alert.delegate = delegate
                    
                    // Set title, message                    
                    alert.title = NSLocalizedString("UPDATE_DIALOG_TITLE", comment: "Update dialog title")
                    
                    // Set message and insert new version code                    
                    alert.message = String.localizedStringWithFormat(NSLocalizedString("UPDATE_DIALOG_MESSAGE", comment: "Update dialog message"), latestVersion!)
                    
                    // Add buttons                    
                    alert.addButton(withTitle: NSLocalizedString("NOT_NOW_BUTTON", comment: "Not now button text"))
                    alert.addButton(withTitle: NSLocalizedString("UPDATE_BUTTON", comment: "Update button text"))

                    // Show alert view                    
                    alert.show()
                }
            }
        }
    }
    
    static func updateTokenAsync(token: String) {
        // Get credentials        
        let uid = UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "")
        let hash = UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "")
        
        // Prepare post data        
        let params = ["token": token, "uid": uid, "hash": hash]
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/update/token", params: params as [String : AnyObject]) { (err: NSError?, json: NSDictionary?) -> () in
            
            // JSON parse error?            
            if let theErr = err {
                // Default message
                var message = NSLocalizedString("USER_UPDATE_ERROR", comment: "Update error message")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
            
            // Save new token            
            UserSettings.setString(key: UserSettingsKeys.deviceToken, value: token)
        }
    }
    
    static func updateLanguageAsync(language: String, callback: @escaping (_ err: NSError?) -> ()) {
        // Get credentials        
        let uid = UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "")
        let hash = UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "")
        
        // Prepare post data        
        let params = ["language": language, "uid": uid, "hash": hash]
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/update/language", params: params as [String : AnyObject]) { (err: NSError?, json: NSDictionary?) -> () in
            
            // Return callback            
            callback(err)
        }
    }
    
    static func updateNotificationsAsync(primary: Bool, secondary: Bool, callback: @escaping (_ err: NSError?) -> ()) {
        // Get credentials        
        let uid = UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "")
        let hash = UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "")
        
        // Convert to int        
        let primary = (primary) ? "1" : "0"
        let secondary = (secondary) ? "1" : "0"
        
        // Prepare post data        
        let params = ["primary": primary, "secondary": secondary, "uid": uid, "hash": hash]
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/update/notifications", params: params as [String : AnyObject] as [String : AnyObject]) { (err: NSError?, json: NSDictionary?) -> () in
            
            // Return callback            
            callback(err)
        }
    }
    
    static func requestSelfTestAsync(callback: @escaping (_ err: NSError?) -> ()) {
        // Get credentials        
        let uid = UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "")
        let hash = UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "")
        
        // Prepare post data        
        let language = NSLocale.preferredLanguages.first! as String
        
        // Prepare post data
        let params = ["language": language, "uid": uid, "hash": hash, "env": getEnvironmentString()]
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/test", params: params as [String : AnyObject]) { (err: NSError?, json: NSDictionary?) -> () in
            
            // Return callback            
            callback(err)
        }
    }
    
    static func getEnvironmentString() -> String {
        // Support for iOS Simulator (Apple Silicon M1, M2, and T2 Macs)
        #if targetEnvironment(simulator)
            return "development"
        #endif

        // Get embedded provision dictionary
        if let mobileProvision = getMobileProvision() {
            // Get entitlements dictionary
            let entitlements = mobileProvision.object(forKey: "Entitlements") as? NSDictionary
            // Check aps-environment variable for "development" as its value
            if let apsEnvironment = entitlements?["aps-environment"] as? NSString, apsEnvironment.isEqual(to: "development") {
                // This is indeed development
                return "development"
            }
        }
        
        // Default to production (safer this way)
        return "production"
    }
    
    static func getMobileProvision() -> NSDictionary? {
        // Prepare mobile provision
        var mobileProvision : NSDictionary? = nil
        
        // Build path to embedded provision in bundle
        let provisioningPath = Bundle.main.path(forResource:"embedded", ofType: "mobileprovision")
        
        // Can't find for some reason?
        if provisioningPath == nil {
            return nil
        }
        
        // NSISOLatin1 keeps the binary wrapper from being parsed as unicode and dropped as invalid
        let binaryString: NSString?
        
        do {
            // Read file using isoLatin1 encoding
            binaryString = try NSString(contentsOfFile: provisioningPath!, encoding: String.Encoding.isoLatin1.rawValue)
        } catch _ {
            return nil
        }
        
        // Scan the XML file from string
        let scanner = Scanner(string: binaryString! as String)
        
        // Scan up to the <plist
        var ok = scanner.scanUpTo("<plist", into: nil)
        
        // Failed?
        if !ok {
            return nil
        }
        
        // Prepare string of interesting properties
        var plistString : NSString? = ""
        
        // Scan up to the closing </plist> tag
        ok = scanner.scanUpTo("</plist>", into: &plistString)
        
        // Failed?
        if !ok {
            return nil
        }
        
        // Prepare a new string with opening and closing <plist> tags
        let newString = (plistString! as String) + "</plist>"
        
        // Convert latin1 string back to utf-8!
        if let plistdata_latin1 = newString.data(using: .isoLatin1) {
            do {
                // Actually parse the plist XML into a dictionary
                mobileProvision = try PropertyListSerialization.propertyList(from: plistdata_latin1, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? NSDictionary
            }
            catch {
                return nil
            }
        }
        
        // If succeeded, return the provision
        return mobileProvision
    }

    static func updateSoundsAsync(primary: String, secondary: String, callback: @escaping (_ err: NSError?) -> ()) {
        // Get credentials        
        let uid = UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "")
        let hash = UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "")
        
        // Get sound from stored preferences        
        let primary = (primary.isEmpty) ? UserSettings.getString(key: UserSettingsKeys.soundSelection, defaultValue: UserSettingsDefaults.soundSelection) : primary
        let secondary = (secondary.isEmpty) ? UserSettings.getString(key: UserSettingsKeys.secondarySoundSelection, defaultValue: UserSettingsDefaults.secondarySoundSelection) : secondary
        
        // Prepare post data        
        let params = ["primary": primary, "secondary": secondary, "uid": uid, "hash": hash]
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/update/sounds", params: params as [String : AnyObject]) { (err: NSError?, json: NSDictionary?) -> () in
            
            // Return callback            
            callback(err)
        }
    }
    
    static func updateSubscriptionsAsync(cities: [String], zones: [String], secondaryCities: [String], callback: @escaping (_ err: NSError?) -> ()) {
        // Get credentials        
        let uid = UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "")
        let hash = UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "")
        
        // Prepare subscriptions        
        var primarySubscriptions: [String] = []
        var secondarySubscriptions: [String] = []
        
        // Traverse cities        
        for city in cities {
            // New city name?
            if (!primarySubscriptions.contains(city)) {
                // Add it
                primarySubscriptions.append(city)
            }
        }
        
        // Traverse zones
        for zone in zones {
            // New item?            
            if (!primarySubscriptions.contains(zone)) {
                // Add it                
                primarySubscriptions.append(zone)
            }
        }
        
        // Traverse secondary cities        
        for city in secondaryCities {
            // New city?
            if (!secondarySubscriptions.contains(city)) {
                // Add it
                secondarySubscriptions.append(city)
            }
        }
        
        // Prepare post data        
        let params = ["uid": uid, "hash": hash, "primary": primarySubscriptions, "secondary": secondarySubscriptions] as Dictionary<String, AnyObject>
        
        // Execute post request        
        HTTP.postAsync(urlString: Config.apiBaseURL + "/subscribe", params: params) { (err: NSError?, json: NSDictionary?) -> () in
            
            // Return callback            
            callback(err)
        }
    }
    
    // Recent Alerts    
    static func getRecentAlerts(callback: @escaping (_ err: NSError?, _ alerts: [Alert]?) -> ()) {
        // Execute post request        
        HTTP.getAsync(urlString: Config.apiBaseURL + "/alerts", dictionary: false) { (err: NSError?, json: AnyObject?) -> () in
            
            // JSON parse error?            
            if let err = err {
                // Return callback                
                return callback(err, nil)
            }
            
            // Unwrap JSON            
            if let json = json as? NSArray {
                // Prepare alerts array                
                var alerts: [Alert] = []
                
                // Loop over areas                
                for item in json {
                    // Convert to dictionary                    
                    if let item = item as? NSDictionary {
                        // Get city & date
                        let city = item["area"] as! String
                        let date = item["date"] as! Double
                        let threat = item["threat"] as! String

                        // Create new alert                        
                        let alert = Alert(city: city, date: date, threat: threat)
                        
                        // Add it to alerts                        
                        alerts.append(alert)
                    }
                }
                
                // Return callback                
                return callback(nil, alerts)
            }
        }
    }
}
