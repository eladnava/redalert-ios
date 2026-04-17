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
        // Handle language changes
        if (notif.object as! String == UserSettingsKeys.language) {
            // Update language
            self.saveAppLanguage()
        }
        
        // Handle volume changes
        else if (notif.object as! String == UserSettingsKeys.primaryVolume) {
            // Update volume
            self.saveVolume()
        }
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
    
    func saveVolume() {
        // Show loading dialog
        MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        
        // Update sounds & volume
        RedAlertAPI.updateSoundsAsync(primary: "", secondary: "") { (err: NSError?) -> () in
            // Hide loading dialog
            MBProgressHUD.hide(for: self.navigationController?.view, animated: true)
            
            // Error?
            if let theErr = err {
                // Default message
                var message = NSLocalizedString("SOUND_SAVE_ERROR", comment: "Error saving volume")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
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
        
        // Early warnings settings button
        if (specifier.key() == "earlyWarningsSettingsButton") {
            earlyWarningsSettings()
        }
        
        // Contact button        
        if (specifier.key() == "contactButton") {
            contactMe("")
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
    
    func earlyWarningsSettings() {
        // Create VC using storyboard ID        
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "EarlyWarningsSettings") as UIViewController
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func contactMe(_ message: String) {
        // Create alert
        let alert = UIAlertController(title: NSLocalizedString("REPORT_BUG", comment: "Report a problem"), message: NSLocalizedString("EMAIL_BODY_ERROR_DESC", comment: "Problem description:"), preferredStyle: .alert)
        
        // Create a UITextView
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.layer.borderColor = UIColor.systemGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6
        textView.text = message
        
        // Embed the text view in a view controller
        let textViewController = UIViewController()
        textViewController.preferredContentSize = CGSize(width: 250, height: 100)
        textViewController.view.addSubview(textView)
        
        // Add the view controller to the alert
        alert.setValue(textViewController, forKey: "contentViewController")
        
        // Add actions
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL_BUTTON", comment: "Cancel"), style: .cancel, handler: nil))
        
        // Create send action
        let send = UIAlertAction(title: NSLocalizedString("OK_BUTTON", comment: "OK"), style: .default, handler: { _ in
            // Get problem description
            let message = textView.text ?? ""
            
            // Validation: minimum 10 characters
            if message.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
                // Show an error alert
                let errorAlert = UIAlertController(title: NSLocalizedString("ERROR_DIALOG", comment: "Error"), message: NSLocalizedString("EMAIL_BODY_SHORT_ERROR_DESC", comment: "Please enter a message with at least 10 characters."), preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    // Optional: focus back on the text view
                    textView.becomeFirstResponder()
                    
                    // Re-display dialog with message
                    self.contactMe(message)
                }))
                
                // Show alert dialog
                if let vc = UIApplication.shared.keyWindow?.rootViewController {
                    vc.present(errorAlert, animated: true, completion: nil)
                }
                
                // Stop execution
                return
            }
            
            // Send e-mail with problem description
            self.sendContactEmail(message)
        })
        
        // Add action & set as preferred so it shows up as bold
        alert.addAction(send)
        alert.preferredAction = send

        // Present the alert
        if let vc = UIApplication.shared.keyWindow?.rootViewController {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    func sendContactEmail(_ message: String) {
        // No e-mail capability?
        if (!MFMailComposeViewController.canSendMail()) {
            Dialogs.error(message: NSLocalizedString("CONTACT_ERROR", comment: "Can't send contact e-mail."))
            return
        }
        
        // Prepare title        
        let emailTitle = NSLocalizedString("EMAIL_TITLE", comment: "Title of contact e-mail")
        
        // Initialize body with error description        
        var messageBody = NSLocalizedString("EMAIL_BODY_ERROR_DESC", comment: "Error description in e-mail body") + "\n\n" + message
        
        // Add some line breaks        
        messageBody += "\n\n"
        
        // Add sent via info for debugging purposes
        messageBody += String.localizedStringWithFormat(NSLocalizedString("EMAIL_BODY_SENT_VIA", comment: "Application info in e-mail body"), App.getVersion())
        
        // Add some line breaks
        messageBody += "\n\n"
        
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
        messageBody += "ios.model=" + UIDevice.current.localizedModel + "\n\n"
        
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
