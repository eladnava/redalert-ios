//
//  LocationData.swift
//  RedAlert
//
//  Created by Elad on 10/16/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct LocationMetadata {
    // Cache JSON in-memory    
    static var cityCache: [City] = []
    static var zoneCache: NSArray?
    
    // Get cities from JSON    
    static func getCities() -> [City] {
        // Return city cache, if exists        
        if (cityCache.count > 0) {
            return cityCache
        }
        
        // Cache cities for later        
        let cities = JSON.parseJSONFile(file: "Cities")
        
        // Traverse cities        
        for city in cities as! [NSDictionary] {
            // Extract data from JSON
            let name = city["name"] as! String
            let name_en = city["name_en"] as! String
            let zone = city["zone"] as! String
            let zone_en = city["zone_en"] as! String
            let time = city["time"] as! String
            let time_en = city["time_en"] as! String
            let countdown = city["countdown"] as! Int
            let lat = city["lat"] as! Double
            let lng = city["lng"] as! Double
            let value = city["value"] as! String
            var shelters = 0
            
            // Got any shelters?
            if city["shelters"] != nil {
                shelters = city["shelters"] as! Int
            }
            
            // Create new city object            
            let item = City(name: name, name_en: name_en, zone: zone, zone_en: zone_en, time: time, time_en: time_en, countdown: countdown, lat: lat, lng: lng, value: value, shelters: shelters)
            
            // Add it to cache            
            cityCache.append(item)
        }
        
        // Return city array        
        return cityCache
    }
    
    // Get zones from JSON
    static func getZones() -> NSArray? {
        // Return zone cache, if exists
        if (zoneCache != nil) {
            return zoneCache
        }
        
        // Cache zones for later        
        zoneCache = JSON.parseJSONFile(file: "Zones")
        
        // Return zones array
        return zoneCache
    }
    
    static func getLocalizedZone(zone: String) -> String {
        // Create names array
        if (!Localization.isEnglish()) {
            return zone
        }
        
        // Get cities as array
        let cities = getCities()
        
        // Loop over them
        for city in cities {
            // Found a city with this zone?
            if (city.zone == zone) {
                // Return english zone name
                return city.zone_en
            }
        }
        
        // No match, return original zone
        return zone
    }
    
    static func getLocalizedCityName(cityName: String) -> String {
        // Not English?
        if (!Localization.isEnglish()) {
            return cityName
        }
        
        // Get cities as array
        let cities = getCities()
        
        // Loop over them
        for city in cities {
            // Find by name
            if (city.name == cityName) {
                // Return english name
                return city.name_en
                
            }
        }
        
        // No match, return city name in Hebrew
        return cityName
    }
    
    static func getLocalizedZoneByCity(cityName: String) -> String {
        // Get cities as array
        let cities = getCities()
        
        // Loop over them
        for city in cities {
            // Find by name
            if (city.name == cityName) {
                // Return english zone
                return (Localization.isEnglish()) ? city.zone_en : city.zone
            }
        }
        
        // No match, return empty string
        return ""
    }
    
    static func getLocalizedZoneWithCountdown(cityName: String) -> String {
        // Get cities as array
        let cities = getCities()
        
        // Loop over them
        for city in cities {
            // Find by name
            if (city.name == cityName) {
                // Return english zone
                return (Localization.isEnglish()) ? city.zone_en  + " (" + city.time_en + ")" : city.zone + " (" + city.time + ")"
            }
        }
        
        // No match, return empty string
        return ""
    }
}
