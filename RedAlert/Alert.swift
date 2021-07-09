//
//  Alert.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class Alert {
    var city: String, date: String, localizedZone: String, localizedCity: String
    
    // Main INIT function    
    init(city: String, date: String) {
        // Assign members        
        self.city = city
        self.date = date
        
        // Get localized names
        self.localizedZone = LocationMetadata.getLocalizedZoneByCity(cityName: city)
        self.localizedCity = LocationMetadata.getLocalizedCityName(cityName: city)
    }
}
