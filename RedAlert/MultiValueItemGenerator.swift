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
        
        // Loop over them        
        for zone in zones as! [NSDictionary] {
            // Prepare localized zone title
            let name: String

            // Use Russian names when Russian is active
            if Localization.shouldLocalizeToRussian() {
                // Build Russian zone title from city metadata
                name = LocationMetadata.russianZoneTitle(forZonesJsonZone: zone)
            } else if Localization.shouldLocalizeToArabic() {
                // Build Arabic zone title from city metadata
                name = LocationMetadata.arabicZoneTitle(forZonesJsonZone: zone)
            } else {
                // Check whether the current language should use English labels
                let isEnglish = Localization.shouldLocalizeToEnglish()

                // Choose English or Hebrew zone title
                name = (isEnglish) ? zone["name_en"] as! String : zone["name"] as! String
            }
            
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
        
        // Loop over them        
        for city in cities {
            // Prepare localized city title
            let name: String

            // Prepare localized zone subtitle
            let zone: String

            // Use Russian names when Russian is active
            if Localization.shouldLocalizeToRussian() {
                // Prefer Russian city name and fallback to English
                name = city.name_ru.isEmpty ? city.name_en : city.name_ru

                // Prefer Russian zone name and fallback to English
                zone = city.zone_ru.isEmpty ? city.zone_en : city.zone_ru
            } else if Localization.shouldLocalizeToArabic() {
                // Prefer Arabic city name and fallback to English
                name = city.name_ar.isEmpty ? city.name_en : city.name_ar
                
                // Prefer Arabic zone name and fallback to English
                zone = city.zone_ar.isEmpty ? city.zone_en : city.zone_ar
            } else {
                // Check whether the current language should use English labels
                let isEnglish = Localization.shouldLocalizeToEnglish()

                // Choose English or Hebrew city name
                name = (isEnglish) ? city.name_en : city.name

                // Choose English or Hebrew zone name
                zone = (isEnglish) ? city.zone_en : city.zone
            }
            
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
