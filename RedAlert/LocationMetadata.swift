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
    static var polygonCache: [CityPolygons] = []
    
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
            let id = city["id"] as! Int
            let name = city["name"] as! String
            let name_en = city["name_en"] as! String
            let name_ru = (city["name_ru"] as? String) ?? ""
            let zone = city["zone"] as! String
            let zone_en = city["zone_en"] as! String
            let zone_ru = (city["zone_ru"] as? String) ?? ""
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
            let item = City(id: id, name: name, name_en: name_en, name_ru: name_ru, zone: zone, zone_en: zone_en, zone_ru: zone_ru, countdown: countdown, lat: lat, lng: lng, value: value, shelters: shelters)
            
            // Add it to cache
            cityCache.append(item)
        }
        
        // Return city array
        return cityCache
    }
    
    // Get cities from JSON
    static func getPolygons() -> [CityPolygons] {
        // Return polygon cache, if exists
        if (polygonCache.count > 0) {
            return polygonCache
        }
        
        // Load polygons from JSON
        let polygons = JSON.parseJSONDictionaryFile(file: "Polygons")
        
        // Traverse dictionary
        for polygon in polygons! {
            // Convert dictionary key to String (city polygon ID)
            if let polygonId = polygon.key as? String {
                // Convert value to [Double] array (polygon coordinates)
                if let coordinates = polygon.value as? [[Double]] {
                    // Create new city polygons object
                    let item = CityPolygons(id: Int(polygonId)!, coordinates: coordinates)
                    
                    // Add it to cache
                    polygonCache.append(item)
                }
            }
        }
        
        // Return polygon array
        return polygonCache
    }
    
    static func localizedDisplayName(for city: City) -> String {
        // Return Russian display name when Russian is active
        if Localization.shouldLocalizeToRussian() {
            // Prefer Russian city name and fallback to English
            return city.name_ru.isEmpty ? city.name_en : city.name_ru
        }
        
        // Return English display name when English localization is active
        if Localization.shouldLocalizeToEnglish() {
            // Return English city name
            return city.name_en
        }
        
        // Return Hebrew city name by default
        return city.name
    }
    
    static func localizedZoneLabel(for city: City) -> String {
        // Return Russian zone label when Russian is active
        if Localization.shouldLocalizeToRussian() {
            // Prefer Russian zone name and fallback to English
            return city.zone_ru.isEmpty ? city.zone_en : city.zone_ru
        }
        
        // Return English zone label when English localization is active
        if Localization.shouldLocalizeToEnglish() {
            // Return English zone label
            return city.zone_en
        }
        
        // Return Hebrew zone label by default
        return city.zone
    }
    
    static func russianZoneTitle(forZonesJsonZone zone: NSDictionary) -> String {
        // Extract zone value key used for selection persistence
        let value = zone["value"] as! String

        // Handle the "all" pseudo-zone separately
        if value == "all" {
            // Load cities for fallback lookup
            let cities = getCities()

            // Find "all" item in cities metadata
            if let first = cities.first(where: { $0.value == "all" }), !first.name_ru.isEmpty {
                // Return Russian "all" title from cities JSON
                return first.name_ru
            }
        }
        
        // Find a city that belongs to this Hebrew zone key
        if let c = getCities().first(where: { $0.zone == value }), !c.zone_ru.isEmpty {
            // Return Russian zone title from cities JSON
            return c.zone_ru
        }
        
        // Fallback to English zone title from zones JSON
        return zone["zone_en"] as! String
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
        // Handle Russian zone localization first
        if Localization.shouldLocalizeToRussian() {
            // Localize "all" pseudo-zone using strings table
            if zone == "all" {
                // Return localized "All" value
                return NSLocalizedString("All", comment: "")
            }
            
            // Loop over cities to map Hebrew zone key to Russian label
            for city in getCities() {
                // Match by source Hebrew zone key
                if city.zone == zone {
                    // Return Russian zone and fallback to English
                    return city.zone_ru.isEmpty ? city.zone_en : city.zone_ru
                }
            }
            
            // Fallback to original zone key
            return zone
        }
        
        // Keep existing Hebrew behavior for non-English and non-Russian
        if (!Localization.shouldLocalizeToEnglish()) {
            // Translate "all" pseudo-zone to Hebrew label
            if zone == "all" {
                // Return Hebrew "all" label
                return "הכל"
            }
            
            // Return Hebrew zone key directly
            return zone
        }
        
        // Load cities for English zone lookup
        let cities = getCities()

        // Loop over cities to map Hebrew zone key to English label
        for city in cities {
            // Match by source Hebrew zone key
            if (city.zone == zone) {
                // Return English zone label
                return city.zone_en
            }
        }
        
        // Fallback to original zone key
        return zone
    }
    
    static func getLocalizedCityName(cityName: String) -> String {
        // Handle Russian city localization first
        if Localization.shouldLocalizeToRussian() {
            // Localize "all" pseudo-city using strings table
            if cityName == "all" {
                // Return localized "All" value
                return NSLocalizedString("All", comment: "")
            }
            
            // Loop over cities to map Hebrew city key to Russian label
            for city in getCities() {
                // Match by source Hebrew city key
                if (city.name == cityName) {
                    // Return Russian city name and fallback to English
                    return city.name_ru.isEmpty ? city.name_en : city.name_ru
                }
            }
            
            // Fallback to original city key
            return cityName
        }
        
        // Keep existing Hebrew behavior for non-English and non-Russian
        if (!Localization.shouldLocalizeToEnglish()) {
            // Translate "all" pseudo-city to Hebrew label
            if cityName == "all" {
                // Return Hebrew "all" label
                return "הכל"
            }
            // Return Hebrew city key directly
            return cityName
        }
        
        // Load cities for English city lookup
        let cities = getCities()

        // Loop over cities to map Hebrew city key to English label
        for city in cities {
            // Match by source Hebrew city key
            if (city.name == cityName) {
                // Return English city label
                return city.name_en
            }
        }
        
        // Fallback to original city key
        return cityName
    }
    
    static func getLocalizedZoneByCity(cityName: String) -> String {
        // Load cities for zone lookup
        let cities = getCities()

        // Loop over cities to find matching city
        for city in cities {
            // Match by source Hebrew city key
            if (city.name == cityName) {
                // Return localized zone label for the matched city
                return localizedZoneLabel(for: city)
            }
        }
        
        // Fallback to empty value when city is not found
        return ""
    }
    
    static func getZoneByCity(cityName: String) -> String {
        // Get cities as array
        let cities = getCities()
        
        // Loop over them
        for city in cities {
            // Find by name
            if (city.name == cityName) {
                // Return zone
                return city.zone
            }
        }
        
        // No match, return empty string
        return ""
    }
    
    static func getLocalizedThreat(threat: String) -> String {
        switch threat {
            case "test":
                return NSLocalizedString("TEST", comment: "test")
            case "missiles":
                return NSLocalizedString("MISSILES", comment: "missiles")
            case "radiologicalEvent":
                return NSLocalizedString("RADIOLOGICAL_EVENT", comment: "radiologicalEvent")
            case "earthQuake":
                return NSLocalizedString("EARTHQUAKE", comment: "earthQuake")
            case "tsunami":
                return NSLocalizedString("TSUNAMI", comment: "tsunami")
            case "hostileAircraftIntrusion":
                return NSLocalizedString("HOSTILE_AIRCRAFT_INTRUSION", comment: "hostileAircraftIntrusion")
            case "hazardousMaterials":
                return NSLocalizedString("HAZARDOUS_MATERIALS", comment: "hazardousMaterials")
            case "terroristInfiltration":
                return NSLocalizedString("TERRORIST_INFILTRATION", comment: "terroristInfiltration")
            case "earlyWarning":
                return NSLocalizedString("EARLY_WARNING", comment: "earlyWarning")
            case "leaveShelter":
                return NSLocalizedString("LEAVE_SHELTER", comment: "leaveShelter")
            case "missilesDrill":
                return NSLocalizedString("MISSILES_DRILL", comment: "missilesDrill")
            case "earthQuakeDrill":
                return NSLocalizedString("EARTHQUAKE_DRILL", comment: "earthQuakeDrill")
            case "radiologicalEventDrill":
                return NSLocalizedString("RADIOLOGICAL_EVENT_DRILL", comment: "radiologicalEventDrill")
            case "tsunamiDrill":
                return NSLocalizedString("TSUNAMI_DRILL", comment: "tsunamiDrill")
            case "hostileAircraftIntrusionDrill":
                return NSLocalizedString("HOSTILE_AIRCRAFT_INTRUSION_DRILL", comment: "hostileAircraftIntrusionDrill")
            case "hazardousMaterialsDrill":
                return NSLocalizedString("HAZARDOUS_MATERIALS_DRILL", comment: "hazardousMaterialsDrill")
            case "terroristInfiltrationDrill":
                return NSLocalizedString("TERRORIST_INFILTRATION_DRILL", comment: "terroristInfiltrationDrill")
            case "system":
                return NSLocalizedString("SYSTEM", comment: "system")
            default:
                return NSLocalizedString("UNKNOWN", comment: "unknown")
        }
    }
    
    struct Countdown {
        let countdown: Int
        let time: String
        let time_en: String
        let time_ru: String
        let time_ar: String
    }
    
    static func getLocalizedZoneWithCountdown(cityName: String) -> String {
        // Define translations
        let countdownTranslations: [Int: Countdown] = [
            0: Countdown(countdown: 0, time: "מיידי", time_en: "Immediately", time_ru: "Немедленно", time_ar: "في الحال"),
            15: Countdown(countdown: 15, time: "15 שניות", time_en: "15 seconds", time_ru: "15 секунд", time_ar: "۱٥ ثانية"),
            30: Countdown(countdown: 30, time: "30 שניות", time_en: "30 seconds", time_ru: "30 секунд", time_ar: "۳۰ ثانية"),
            45: Countdown(countdown: 45, time: "45 שניות", time_en: "45 seconds", time_ru: "45 секунд", time_ar: "٤٥ ثانية"),
            60: Countdown(countdown: 60, time: "דקה", time_en: "A minute", time_ru: "Минута", time_ar: "دقيقة"),
            90: Countdown(countdown: 90, time: "דקה וחצי", time_en: "A minute and a half", time_ru: "Полторы минуты", time_ar: "دقيقة ونصف"),
            180: Countdown(countdown: 180, time: "3 דקות", time_en: "3 minutes", time_ru: "3 минуты", time_ar: "۳ دقائق")
        ]
        
        // Get cities as array
        let cities = getCities()
        
        // Loop over them
        for city in cities {
            // Find by name
            if (city.name == cityName) {
                // Handle Russian localized countdown label
                if Localization.shouldLocalizeToRussian() {
                    // Resolve Russian zone name with English fallback
                    let z = city.zone_ru.isEmpty ? city.zone_en : city.zone_ru

                    // Return Russian zone with Russian countdown text
                    return z + " (" + countdownTranslations[city.countdown]!.time_ru + ")"
                }
                
                // Handle English localized countdown label
                if Localization.shouldLocalizeToEnglish() {
                    // Return English zone with English countdown text
                    return city.zone_en + " (" + countdownTranslations[city.countdown]!.time_en + ")"
                }
                
                // Return Hebrew zone with Hebrew countdown text
                return city.zone + " (" + countdownTranslations[city.countdown]!.time + ")"
            }
        }
        
        // No match, return empty string
        return ""
    }
}
