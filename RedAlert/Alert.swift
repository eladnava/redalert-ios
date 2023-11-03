//
//  Alert.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class Alert {
    var city: String, date: Double, localizedZone: String, localizedCity: String, groupedCities: [String]
    
    // Main INIT function    
    init(city: String, date: Double) {
        // Assign members        
        self.city = city
        self.date = date
        
        // Get localized names
        self.localizedCity = LocationMetadata.getLocalizedCityName(cityName: city)
        self.localizedZone = LocationMetadata.getLocalizedZoneByCity(cityName: city)
        
        // Initialize empty grouped cities array
        self.groupedCities = []
    }
}
