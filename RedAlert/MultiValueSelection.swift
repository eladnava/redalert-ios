//
//  MultiValueSelection.swift
//  RedAlert
//
//  Created by Elad on 10/18/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class MultiValueSelection : NSObject, KNMultiItemSelectorDelegate {
    // Cache navigation control    
    var selector: KNMultiItemSelector?
    var navigationController: UINavigationController
    
    // Main INIT function    
    init(key: String, items: [KNSelectorItem], preselectedItems: [KNSelectorItem], title: String, navigationController: UINavigationController) {
        // Save navcontrol for later        
        self.navigationController = navigationController
        
        // Init object        
        super.init()
        
        // Set search placeholder        
        let placeHolder = NSLocalizedString("SEARCH_PLACEHOLDER", comment: "Multi-value search placeholder")
        
        // Create selector control        
        selector = KNMultiItemSelector(items: items, preselectedItems: preselectedItems, key: key, title: title, placeholderText: placeHolder, delegate: self)
        
        // Allow searching options        
        selector!.allowSearchControl = true
        
        // Display recently selected items for comfort        
        selector!.useRecentItems = true
        selector!.maxNumberOfRecentItems = 5
        selector!.recentItemStorageKey = key + "Recent"
    }
    
    func show() {
        // Push the selector as a new view controller        
        navigationController.pushViewController(selector!, animated: true)
    }
    
    func selectorDidCancelSelection() {
        // Selection cancelled, go back to settings        
        self.navigationController.popViewController(animated: true)
    }
    
    func selector(_ selector: KNMultiItemSelector!, didFinishSelectionWithItems selectedItems: [Any]!) {
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
        
        // Prepare string array of selected values        
        var selected: [String] = []
        
        // Run code async        
        Async.worker(label: "multiValueSelection", callback: { () -> () in
            
            // Loop over selected items            
            for item in selectedItems as! [KNSelectorItem] {
                // Add city name to list                    
                selected.append(item.selectValue)
            }
        }, uiCallback: { () -> () in
            // Define list separator
            let seperator = "|"
            
            // Convert array to CSV list            
            var value = selected.joined(separator: seperator)
            
            // "All" selected?            
            if (value.range(of: "all") != nil) {
                // No need to store the rest                
                value = "all"
            }
            
            // Get primary & secondary selection            
            var cities = UserSettings.getStringArray(key: UserSettingsKeys.citySelection)
            var zones = UserSettings.getStringArray(key: UserSettingsKeys.zoneSelection)
            var secondaryCities = UserSettings.getStringArray(key: UserSettingsKeys.secondaryCitySelection)
            
            // Set temp cities / zones
            cities = (selector.key == UserSettingsKeys.citySelection) ? UserSettings.getStringArrayByValue(value: value) : cities
            zones = (selector.key == UserSettingsKeys.zoneSelection) ? UserSettings.getStringArrayByValue(value: value) : zones
            
            // Support for secondary cities            
            secondaryCities = (selector.key == UserSettingsKeys.secondaryCitySelection) ? UserSettings.getStringArrayByValue(value: value) : secondaryCities
            
            // Re-subscribe            
            RedAlertAPI.updateSubscriptionsAsync(cities: cities, zones: zones, secondaryCities: secondaryCities) { (err: NSError?) -> () in
                
                // Hide loading dialog                
                MBProgressHUD.hide(for: self.navigationController.view, animated: true)
                
                // Error?                
                if let theErr = err {
                    // Default message
                    var message = NSLocalizedString("SAVE_SUBSCRIPTIONS_FAILED", comment: "Error saving subscriptions")
                    
                    // Error provided?
                    if let errMsg = theErr.userInfo["error"] as? String {
                        message += "\n\n" + errMsg
                    }
                    
                    // Show the error                    
                    return Dialogs.error(message: message)
                }
                
                // Save in user defaults by selector key                
                UserDefaults.standard.set(value, forKey: selector.key)
                
                // Go back to settings                
                self.navigationController.popViewController(animated: true)
            }
        })
    }
}
