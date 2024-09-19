//
//  Alert.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class Alert {
    var city: String, date: Double, threat: String, localizedThreat: String, localizedZone: String, localizedZoneWithCountdown: String, localizedCity: String, groupedCities: [String]
    
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
        self.localizedZoneWithCountdown = LocationMetadata.getLocalizedZoneWithCountdown(cityName: city)

        // Initialize empty grouped cities array
        self.groupedCities = []
    }
}
