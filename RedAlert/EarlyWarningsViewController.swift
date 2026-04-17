//
//  EarlyWarningsViewController.swift
//  RedAlert
//
//  Created by Elad on 10/17/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit
import MessageUI

class EarlyWarningsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    required init?(coder aDecoder: NSCoder) {
        // Call super        
        super.init(coder: aDecoder)
        
        // Load early warnings settings        
        self.settingsFile = "EarlyWarnings"
        
        // Set delegate so we get the callbacks when settings are clicked        
        self.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop listening to events        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {        
        // Listen to toggle change event        
        NotificationCenter.default.addObserver(self, selector: #selector(EarlyWarningsViewController.settingChanged), name: NSNotification.Name(rawValue: "kAppSettingChanged"), object: nil)
    }
    
    @objc func settingChanged(notif: NSNotification) {
        // Handle toggle changes
        if (notif.object as! String == UserSettingsKeys.earlyWarningsNotifications) {
            // Update toggle
            self.earlyWarningsToggleChanged()
        }
    }
    
    @objc func earlyWarningsToggleChanged() {
        // Get the current setting values
        let value = UserSettings.getBool(key: UserSettingsKeys.notifications, defaultValue: true)
        let secondaryValue = UserSettings.getBool(key: UserSettingsKeys.secondaryNotifications, defaultValue: true)
        let earlyWarningsValue = UserSettings.getBool(key: UserSettingsKeys.earlyWarningsNotifications, defaultValue: true)
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        
        // Update notifications        
        RedAlertAPI.updateNotificationsAsync(primary: value, secondary: secondaryValue, earlyWarnings: earlyWarningsValue) { (err: NSError?) -> () in
            
            // Hide loading dialog            
            MBProgressHUD.hide(for: self.navigationController?.view, animated: true)
            
            // Error?
            if let theErr = err {
                // Flip value
                UserSettings.setBool(key: UserSettingsKeys.earlyWarningsNotifications, value: !earlyWarningsValue)
                
                // Default message
                var message = NSLocalizedString("NOTIFICATIONS_SAVE_ERROR", comment: "Error saving notifications")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                Dialogs.error(message: message)
                
                // Reload table view to reflect new setting
                self.tableView?.reloadData()
            }
        }
    }
    
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        // Dismiss view controller when it's time to go        
        self.dismiss(animated: true, completion: nil)
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        // Early warning sound selection        
        if (specifier.key() == "earlyWarningSoundSelectionButton") {
            showEarlyWarningSoundSelection()
        }
    }
    
    func showEarlyWarningSoundSelection() {
        // Pop storyboard into view        
        let items: [SoundItem] = SoundItemGenerator.generateSoundItems()
        
        // Initialize view controller        
        let controller = SoundSelectionViewController()
        
        // Prepare window title        
        let title = NSLocalizedString("SOUND_SELECTION", comment: "Early warning sound selection title")
        
        // Set it up with our items        
        controller.setup(key: UserSettingsKeys.earlyWarningsSoundSelection, title: title, items: items, defaultValue: UserSettingsDefaults.earlyWarningsSoundSelection)
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
