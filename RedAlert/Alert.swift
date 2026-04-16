//
//  Alert.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class Alert {
    var city: String, date: Double, threat: String, localizedThreat: String, localizedZone: String, localizedCity: String, groupedCities: [String], groupedLocalizedCities: [String], groupedDescriptions: [String], isExpanded = false, minDate: Double, maxDate: Double
    
    // Main INIT function
    init(city: String, date: Double, threat: String) {
        // Assign members        
        self.city = city
        self.date = date
        self.threat = threat

        // Get localized names
        self.localizedCity = LocationMetadata.getLocalizedCityName(cityName: city)
        self.localizedThreat = LocationMetadata.getLocalizedThreat(threat:threat)
        self.localizedZone = LocationMetadata.getLocalizedZoneByCity(cityName: city)

        // Initialize empty arrays
        self.groupedCities = []
        self.groupedDescriptions = []
        self.groupedLocalizedCities = []

        // Initialize date range
        self.minDate = date
        self.maxDate = date
    }
}
