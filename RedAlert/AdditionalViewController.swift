//
//  SettingsTableViewController.swift
//  RedAlert
//
//  Created by Elad on 10/17/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit

class AdditonalViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    required init?(coder aDecoder: NSCoder) {
        // Call super        
        super.init(coder: aDecoder)
        
        // Load additional settings        
        self.settingsFile = "Additional"
        
        // Set delegate so we get the callbacks when settings are clicked        
        self.delegate = self
    }
    
    override func viewDidLoad() {
        // Listen to toggle change event        
        NotificationCenter.default.addObserver(self, selector: #selector(AdditonalViewController.settingChanged(notif:)), name: NSNotification.Name(rawValue: "kAppSettingChanged"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        // Stop listening to events        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func settingChanged(notif: NSNotification) {
        // Handle langauge changes        
        if (notif.object as! String != "language") {
            return
        }
        
        // Update server        
        self.saveAppLanguage()
    }
    
    func saveAppLanguage() {
        // Get new language        
        let language = UserSettings.getString(key: UserSettingsKeys.language, defaultValue: "")
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        
        // Re-subscribe        
        RedAlertAPI.updateLanguageAsync(language: language) { (err: NSError?) -> () in
            
            // Hide loading dialog            
            MBProgressHUD.hide(for: self.navigationController?.view, animated: true)
            
            // Error?
            if let theErr = err {                
                // Default message
                var message = NSLocalizedString("NOTIFICATIONS_SAVE_ERROR", comment: "Error saving notifications")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
            
            // Override the language            
            Localization.overrideAppLanguage()
            
            // Tell user to reopen app            
            self.languageChanged()
        }
    }
    
    func languageChanged() {
        // Create new alert view        
        let alert = UIAlertView()
        
        // Set delegate so we can capture tap event        
        alert.delegate = delegate
        
        // Set tag so we can identify it later in event handler        
        alert.tag = 100
        
        // Set title        
        alert.title = NSLocalizedString("LANGUAGE_DIALOG_TITLE", comment: "Language dialog title")
        
        // Set dialog message        
        alert.message = NSLocalizedString("LANGUAGE_DIALOG_MESSAGE", comment: "Language dialog message")
        
        // Add button        
        alert.addButton(withTitle: NSLocalizedString("OK_BUTTON", comment: "OK button text"))
        
        // Show alert view        
        alert.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        // Language change dialog?        
        if (alertView.tag == 100) {
            // Close app                
            exit(0)
        }
    }
    
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        // Dismiss view controller when it's time to go        
        self.dismiss(animated: true, completion: nil)
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        // Secondary settings button        
        if (specifier.key() == "secondarySettingsButton") {
            secondarySettings()
        }
        
        // Contact button        
        if (specifier.key() == "contactButton") {
            contactMe()
        }
        
        // Rate button        
        if (specifier.key() == "rateButton") {
            rateApp()
        }
        
        // Visit us button
        if (specifier.key() == "visitUsButton") {
            visitUs()
        }
        
        // Visit us button
        if (specifier.key() == "learnAboutLifeshield") {
            learnAboutLifeshield()
        }
    }
    
    func rateApp() {
        // Open app store page        
        App.openAppStore()
    }
    
    func visitUs() {
        // Open Web site        
        App.openWebSite()
    }
    
    func learnAboutLifeshield() {
        App.openLifeshieldWebsite()
    }
    
    func secondarySettings() {
        // Create VC using storyboard ID        
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "SecondarySettings") as UIViewController
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func contactMe() {
        // No e-mail capability?        
        if (!MFMailComposeViewController.canSendMail()) {
            Dialogs.error(message: NSLocalizedString("CONTACT_ERROR", comment: "Can't send contact e-mail."))
            return
        }
        
        // Prepare title        
        let emailTitle = NSLocalizedString("EMAIL_TITLE", comment: "Title of contact e-mail")
        
        // Initialize body with error description        
        var messageBody = NSLocalizedString("EMAIL_BODY_ERROR_DESC", comment: "Error description in e-mail body")
        
        // Add some line breaks        
        messageBody += "\n\n\n\n\n"
        
        // Get primary & secondary selection
        var cities = UserSettings.getStringArray(key: UserSettingsKeys.citySelection)
        var zones = UserSettings.getStringArray(key: UserSettingsKeys.zoneSelection)
        var secondaryCities = UserSettings.getStringArray(key: UserSettingsKeys.secondaryCitySelection)
        
        // Localize cities
        for (i, city) in cities.enumerated() {
            cities[i] = LocationMetadata.getLocalizedCityName(cityName: city)
        }
        
        // Localize zones
        for (i, zone) in zones.enumerated() {
            zones[i] = LocationMetadata.getLocalizedZone(zone: zone)
        }
        
        // Localize secondary cities
        for (i, city) in secondaryCities.enumerated() {
            secondaryCities[i] = LocationMetadata.getLocalizedCityName(cityName: city)
        }
        
        // Add selected cities
        messageBody += NSLocalizedString("CITIES", comment: "City info in e-mail body") + ": " + cities.joined(separator: ", ").capitalized + "\n"
        
        // Add selected zones
        messageBody += NSLocalizedString("ZONES", comment: "Zone info in e-mail body") + ": " + zones.joined(separator: ", ").capitalized + "\n\n"
        
        // Add selected secondary cities
        messageBody += NSLocalizedString("SECONDARY_CITIES", comment: "Secondary city info in e-mail body") + ": " + secondaryCities.joined(separator: ", ").capitalized + "\n\n"
        
        // Add additional debug info
        messageBody += NSLocalizedString("MORE_INFO", comment: "Additional debug info in e-mail body") + ": "

        // Add UID
        messageBody += "user.id=" + UserSettings.getString(key: UserSettingsKeys.userID, defaultValue: "") + ", "

        // Add user hash
        messageBody += "user.hash=" + UserSettings.getString(key: UserSettingsKeys.userHash, defaultValue: "") + ", "
        
        // Add primary enabled
        messageBody += "primary.enabled=" + String(UserSettings.getBool(key: UserSettingsKeys.notifications, defaultValue: true)) + ", "
        
        // Add secondary enabled
        messageBody += "secondary.enabled=" + String(UserSettings.getBool(key: UserSettingsKeys.secondaryNotifications, defaultValue: true)) + ", "
        
        // Add primary sound
        messageBody += "primary.sound=" + UserSettings.getString(key: UserSettingsKeys.soundSelection, defaultValue: UserSettingsDefaults.soundSelection) + ", "
        
        // Add secondary sound
        messageBody += "secondary.sound=" + UserSettings.getString(key: UserSettingsKeys.secondarySoundSelection, defaultValue: UserSettingsDefaults.secondarySoundSelection) + ", "
        
        // Add APNs registration status
        messageBody += "apns=" + String(UserSettings.getString(key: UserSettingsKeys.deviceToken, defaultValue: "") != "") + ", "
        
        // Add APNs token
        messageBody += "apns.token=" + UserSettings.getString(key: UserSettingsKeys.deviceToken, defaultValue: "") + ", "
        
        // Add iOS version
        messageBody += "ios.version=" + UIDevice.current.systemVersion + ", "
        
        // Add iOS model
        messageBody += "ios.model=" + UIDevice.current.localizedModel + "ֿ\n\n"
        
        // Add sent via info for debugging purposes        
        messageBody += String.localizedStringWithFormat(NSLocalizedString("EMAIL_BODY_SENT_VIA", comment: "Application info in e-mail body"), App.getVersion())
        
        // Create mail view controller        
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        
        // Set delegate        
        mc.mailComposeDelegate = self
        
        // Assign its properties        
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        mc.setToRecipients([Config.contactEmail])
        
        // Present view controller        
        self.present(mc, animated: true, completion: nil)
    }
}
