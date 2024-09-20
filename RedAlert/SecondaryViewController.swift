//
//  SettingsTableViewController.swift
//  RedAlert
//
//  Created by Elad on 10/17/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit
import MessageUI

class SecondaryViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    required init?(coder aDecoder: NSCoder) {
        // Call super        
        super.init(coder: aDecoder)
        
        // Load additional settings        
        self.settingsFile = "Secondary"
        
        // Set delegate so we get the callbacks when settings are clicked        
        self.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop listening to events        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Listen to toggle change event        
        NotificationCenter.default.addObserver(self, selector: #selector(SecondaryViewController.toggleChanged), name: NSNotification.Name(rawValue: "kAppSettingChanged"), object: nil)
    }
    
    @objc func toggleChanged() {
        // Do something
        let value = UserSettings.getBool(key: UserSettingsKeys.notifications, defaultValue: true)
        let secondaryValue = UserSettings.getBool(key: UserSettingsKeys.secondaryNotifications, defaultValue: true)
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        
        // Re-subscribe        
        RedAlertAPI.updateNotificationsAsync(primary: value, secondary: secondaryValue) { (err: NSError?) -> () in
            
            // Hide loading dialog            
            MBProgressHUD.hide(for: self.navigationController?.view, animated: true)
            
            // Error?
            if let theErr = err {
                // Flip value
                UserSettings.setBool(key: UserSettingsKeys.secondaryNotifications, value: !secondaryValue)
                
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
        // City selection
        if (specifier.key() == "citySelectionButton") {
            showCitySelection()
        }
        
        // Sound selection        
        if (specifier.key() == "soundSelectionButton") {
            showSoundSelection()
        }
    }
    
    func showSoundSelection() {
        // Pop storyboard into view        
        let items: [SoundItem] = SoundItemGenerator.generateSoundItems()
        
        // Initialize view controller        
        let controller = SoundSelectionViewController()
        
        // Prepare window title        
        let title = NSLocalizedString("SOUND_SELECTION", comment: "Sound selection title")
        
        // Set it up with our items        
        controller.setup(key: UserSettingsKeys.secondarySoundSelection, title: title, items:items, defaultValue: UserSettingsDefaults.secondarySoundSelection)
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showCitySelection() {
        // Check if we are actually registered first
        if (!RedAlertAPI.isRegistered()) {
            // Show an error
            return Dialogs.error(message: NSLocalizedString("UNREGISTERED_ERROR", comment: "Unregistered error message"))
        }
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        
        // Prepare window title        
        let title = NSLocalizedString("CITY_SELECTION", comment: "City selection title")
        
        // Prepare arrays        
        var items: [KNSelectorItem] = [], selected: [KNSelectorItem] = []
        
        // Run code async        
        Async.worker(label: "secondaryCitySelection", callback: { () -> () in
            // Get cities            
            items = MultiValueItemGenerator.generateCityItems()
            
            // Get selected items            
            selected = self.getSelectedItems(key: UserSettingsKeys.secondaryCitySelection, items: items)
            
            }, uiCallback: { () -> () in
                // Show loading dialog                
                MBProgressHUD.hide(for: self.navigationController?.view, animated: true)
                
                // Show selector control                
                self.showSelection(key: UserSettingsKeys.secondaryCitySelection, title: title, items: items, selected: selected)
        })
    }
    
    func getSelectedItems(key: String, items: [KNSelectorItem]) -> [KNSelectorItem] {
        // Get saved selection        
        let savedSelection = UserSettings.getStringArray(key: key)
        
        // Filter items and get back only the ones selected        
        return MultiValueItemGenerator.generateSelectedItems(items: items, selection: savedSelection)
    }
    
    func showSelection(key: String, title: String, items: [KNSelectorItem], selected: [KNSelectorItem]) {
        // Unwrap safely
        if let navigationController = self.navigationController {
            // Prepare selector control
            let selection = MultiValueSelection(key: key, items:items, preselectedItems: selected, title: title, navigationController: navigationController)
            
            // Show the selector
            selection.show()
        }
    }
}
