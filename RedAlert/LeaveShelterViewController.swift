//
//  LeaveShelterViewController.swift
//  RedAlert
//
//  Created by Elad on 10/17/14.
//

import UIKit
import MessageUI

class LeaveShelterViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    required init?(coder aDecoder: NSCoder) {
        // Call super        
        super.init(coder: aDecoder)
        
        // Load leave shelter settings        
        self.settingsFile = "LeaveShelter"
        
        // Set delegate so we get the callbacks when settings are clicked        
        self.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop listening to events        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Listen to toggle change event        
        NotificationCenter.default.addObserver(self, selector: #selector(LeaveShelterViewController.settingChanged), name: NSNotification.Name(rawValue: "kAppSettingChanged"), object: nil)
    }
    
    @objc func settingChanged(notif: NSNotification) {
        // Handle toggle changes
        if (notif.object as! String == UserSettingsKeys.leaveShelterNotifications) {
            // Update the leave shelter notification setting
            self.leaveShelterToggleChanged()
        }
    }
    
    @objc func leaveShelterToggleChanged() {
        // Read current notification settings
        let value = UserSettings.getBool(key: UserSettingsKeys.notifications, defaultValue: true)
        let secondaryValue = UserSettings.getBool(key: UserSettingsKeys.secondaryNotifications, defaultValue: true)
        let earlyWarningsValue = UserSettings.getBool(key: UserSettingsKeys.earlyWarningsNotifications, defaultValue: true)
        let leaveShelterValue = UserSettings.getBool(key: UserSettingsKeys.leaveShelterNotifications, defaultValue: true)
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        
        // Update notification settings on backend        
        RedAlertAPI.updateNotificationsAsync(primary: value, secondary: secondaryValue, earlyWarnings: earlyWarningsValue, leaveShelter: leaveShelterValue) { (err: NSError?) -> () in
            // Hide loading dialog            
            MBProgressHUD.hide(for: self.navigationController?.view, animated: true)
            
            // Error? revert the local setting and show message
            if let theErr = err {
                UserSettings.setBool(key: UserSettingsKeys.leaveShelterNotifications, value: !leaveShelterValue)
                var message = NSLocalizedString("NOTIFICATIONS_SAVE_ERROR", comment: "Error saving notifications")
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                Dialogs.error(message: message)
                self.tableView?.reloadData()
            }
        }
    }
    
    func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
        // Dismiss view controller when it's time to go        
        self.dismiss(animated: true, completion: nil)
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        // Leave shelter sound selection button        
        if (specifier.key() == "leaveShelterSoundSelectionButton") {
            showLeaveShelterSoundSelection()
        }
    }
    
    func showLeaveShelterSoundSelection() {
        // Pop storyboard into view        
        let items: [SoundItem] = SoundItemGenerator.generateSoundItems()
        
        // Initialize view controller        
        let controller = SoundSelectionViewController()
        
        // Prepare window title        
        let title = NSLocalizedString("SOUND_SELECTION", comment: "Leave shelter sound selection title")
        
        // Set it up with our items        
        controller.setup(key: UserSettingsKeys.leaveShelterSoundSelection, title: title, items: items, defaultValue: UserSettingsDefaults.leaveShelterSoundSelection)
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
