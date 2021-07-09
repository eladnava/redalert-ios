//
//  City.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class City {
    var name: String, name_en: String, zone: String, zone_en: String, time: String, time_en: String, countdown: Int, lat: Double, lng: Double, value: String, shelters: Int
    
    // Main INIT function    
    init(name: String, name_en: String, zone: String, zone_en: String, time: String, time_en: String, countdown: Int, lat: Double, lng: Double, value: String, shelters: Int) {
        self.name = name
        self.name_en = name_en
        self.zone = zone
        self.zone_en = zone_en
        self.time = time
        self.time_en = time_en
        self.countdown = countdown
        self.lat = lat
        self.lng = lng
        self.value = value
        self.shelters = shelters
    }
}
