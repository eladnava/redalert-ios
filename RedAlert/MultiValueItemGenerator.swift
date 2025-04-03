//
//  MultiValueItemGenerator.swift
//  RedAlert
//
//  Created by Elad on 10/18/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct MultiValueItemGenerator {
    static func generateZoneItems() -> [KNSelectorItem] {
        // Create items array        
        var items: [KNSelectorItem] = []
        
        // Get zones as array
        let zones = LocationMetadata.getZones()
        
        // Error?        
        if (zones == nil) {
            return items
        }
        
        // Check locale first        
        let isEnglish = Localization.shouldLocalizeToEnglish()
        
        // Loop over them        
        for zone in zones as! [NSDictionary] {
            // Get localized name            
            let name = (isEnglish) ? zone["name_en"] as! String : zone["name"] as! String
            
            // Add city name to list            
            items.append(KNSelectorItem(displayValue: name, displayDetail: "", selectValue: (zone["value"] as! String)))
        }
        
        // Join items into string
        return items
    }
    
    static func generateCityItems() -> [KNSelectorItem] {
        // Create items array        
        var items: [KNSelectorItem] = []
        
        // Get cities as array        
        let cities = LocationMetadata.getCities()
        
        // Error?        
        if (cities.count == 0) {
            return items
        }
        
        // Check locale first        
        let isEnglish = Localization.shouldLocalizeToEnglish()
        
        // Loop over them        
        for city in cities {
            // Get localized name            
            let name = (isEnglish) ? city.name_en : city.name
            
            // Get localized zone
            let zone = (isEnglish) ? city.zone_en : city.zone
            
            // Add city to list            
            items.append(KNSelectorItem(displayValue: name, displayDetail: zone, selectValue: city.value))
        }
        
        // Join cities into string        
        return items
    }
    
    static func generateSelectedItems(items: [KNSelectorItem], selection: [String]) -> [KNSelectorItem] {
        // Create items array        
        var selected: [KNSelectorItem] = []
        
        // Loop over them        
        for item in items as [KNSelectorItem] {
            // Is it a selected item?            
            if (selection.contains(item.selectValue )) {
                // Add item to selected            
                selected.append(item)
            }
        }
        
        // Return selected items        
        return selected
    }
}
