//
//  SettingsTableViewController.swift
//  RedAlert
//
//  Created by Elad on 10/17/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit
import MessageUI

class SettingsViewController: IASKAppSettingsViewController, IASKSettingsDelegate {
    var selectCities = false
    
    required init?(coder aDecoder: NSCoder) {
        // Call super        
        super.init(coder: aDecoder)
        
        // Set delegate so we get the callbacks when settings are clicked        
        self.delegate = self
    }
    
    @objc func toggleChanged() {
        // Do something        
        let value = UserSettings.getBool(key: UserSettingsKeys.notifications, defaultValue: true)
        let secondaryValue = UserSettings.getBool(key: UserSettingsKeys.secondaryNotifications, defaultValue: true)
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        
        // Re-subscribe        
        RedAlertAPI.updateNotificationsAsync(primary: value, secondary: secondaryValue) { (err: NSError?) -> () in
            
            // Hide loading dialog            
            MBProgressHUD.hide(for: self.navigationController!.view, animated: true)
            
            // JSON parse error?
            if let theErr = err {
                // Flip value
                UserSettings.setBool(key: UserSettingsKeys.notifications, value: !value)
                
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
    
    override func viewWillDisappear(_ animated: Bool) {
        // Stop listening to events        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Listen to toggle change event        
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsViewController.toggleChanged), name: NSNotification.Name(rawValue: "kAppSettingChanged"), object: nil)
    }
    
    override func viewDidLoad() {
        // Not registered?        
        if (!RedAlertAPI.canReceiveNotifications()) {
            // Show an error            
            Dialogs.error(message: NSLocalizedString("UNREGISTERED_ERROR", comment: "Unregistered error message"))
        }
        
        // Sent here from dialog?        
        if (selectCities) {
            // Prevent accidental trigger            
            selectCities = false
            
            // Show city selection
            showCitySelection()
        }
    }
    
    func settingsViewController(_ sender: IASKAppSettingsViewController!, buttonTappedFor specifier: IASKSpecifier!) {
        // Self test        
        if (specifier.key() == "selfTestButton") {
            requestSelfTest()
        }
        
        // Zone selection
        if (specifier.key() == "zoneSelectionButton") {
            showZoneSelection()
        }
        
        // City selection        
        if (specifier.key() == "citySelectionButton") {
            showCitySelection()
        }
        
        // Sound selection        
        if (specifier.key() == "soundSelectionButton") {
            showSoundSelection()
        }
            
        // Additional settings button        
        if (specifier.key() == "additionalSettingsButton") {
            additionalSettings()
        }
    }
    
    func requestSelfTest() {
        // Show loading dialog        
        let hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)!
        
        // Re-subscribe        
        RedAlertAPI.requestSelfTestAsync() { (err: NSError?) -> () in
            // Error?
            if let theErr = err {
                // Hide loading dialog
                MBProgressHUD.hide(for: self.navigationController!.view, animated: true)
                
                // Default message
                var message = NSLocalizedString("SELF_TEST_ERROR", comment: "Self test error message")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
            
            // Convert to text HUD            
            hud.mode = MBProgressHUDModeText
            
            // Set label margin            
            hud.margin = 10.0
            
            // Tell user to wait            
            hud.labelText = NSLocalizedString("WAIT_FOR_TEST_RESULT", comment: "Message shown after requesting self test")
            
            // Hide after 2 seconds            
            hud.hide(true, afterDelay:2)
        }
    }
    
    func additionalSettings() {
        // Create VC using storyboard ID        
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "AdditionalSettings") as UIViewController
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showSoundSelection() {
        // Pop storyboard into view        
        let items: [SoundItem] = SoundItemGenerator.generateSoundItems()
        
        // Initialize view controller        
        let controller = SoundSelectionViewController()
        
        // Prepare window title        
        let title = NSLocalizedString("SOUND_SELECTION", comment: "Sound selection title")
        
        // Set it up with our items        
        controller.setup(key: UserSettingsKeys.soundSelection, title: title, items:items, defaultValue: UserSettingsDefaults.soundSelection)
        
        // Push it into nav stack        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func showZoneSelection() {
        // Check if we are actually registered first
        if (!RedAlertAPI.isRegistered()) {
            // Show an error
            return Dialogs.error(message: NSLocalizedString("UNREGISTERED_ERROR", comment: "Unregistered error message"))
        }
        
        // Get zones from file
        let items = MultiValueItemGenerator.generateZoneItems()
        
        // Get selected items        
        let selected = self.getSelectedItems(key: UserSettingsKeys.zoneSelection, items: items)
        
        // Prepare window title        
        let title = NSLocalizedString("ZONE_SELECTION", comment: "Zone selection title")
        
        // Show selector control        
        self.showSelection(key: UserSettingsKeys.zoneSelection, title: title, items: items, selected: selected)
    }
    
    func showCitySelection() {
        // Check if we are actually registered first
        if (!RedAlertAPI.isRegistered()) {
            // Show an error
            return Dialogs.error(message: NSLocalizedString("UNREGISTERED_ERROR", comment: "Unregistered error message"))
        }
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        
        // Prepare window title        
        let title = NSLocalizedString("CITY_SELECTION", comment: "City selection title")
        
        // Prepare arrays        
        var items: [KNSelectorItem] = [], selected: [KNSelectorItem] = []
        
        // Run code async        
        Async.worker(label: "citySelection", callback: { () -> () in
            // Get cities            
            items = MultiValueItemGenerator.generateCityItems()
            
            // Get selected items            
            selected = self.getSelectedItems(key: UserSettingsKeys.citySelection, items: items)
        }, uiCallback: { () -> () in
            // Show loading dialog            
            MBProgressHUD.hide(for: self.navigationController!.view, animated: true)
            
            // Show selector control            
            self.showSelection(key: UserSettingsKeys.citySelection, title: title, items: items, selected: selected)
        })
    }
    
    func getSelectedItems(key: String, items: [KNSelectorItem]) -> [KNSelectorItem] {
        // Get saved selection        
        let savedSelection = UserSettings.getStringArray(key: key)
        
        // Filter items and get back only the ones selected        
        return MultiValueItemGenerator.generateSelectedItems(items: items, selection: savedSelection)
    }
    
    func showSelection(key: String, title: String, items: [KNSelectorItem], selected: [KNSelectorItem]) {
        // Prepare selector control        
        let selection = MultiValueSelection(key: key, items:items, preselectedItems: selected, title: title, navigationController: self.navigationController!)
        
        // Show the selector        
        selection.show()
    }
}
