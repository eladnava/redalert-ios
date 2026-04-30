//
//  City.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class City {
    var id: Int, name: String, name_en: String, name_ru: String, name_ar: String, zone: String, zone_en: String, zone_ru: String, zone_ar: String, countdown: Int, lat: Double, lng: Double, value: String, shelters: Int
    
    // Main INIT function    
    init(id: Int, name: String, name_en: String, name_ru: String, name_ar: String, zone: String, zone_en: String, zone_ru: String, zone_ar: String, countdown: Int, lat: Double, lng: Double, value: String, shelters: Int) {
        self.id = id
        self.name = name
        self.name_en = name_en
        self.name_ru = name_ru
        self.name_ar = name_ar
        self.zone = zone
        self.zone_en = zone_en
        self.zone_ru = zone_ru
        self.zone_ar = zone_ar
        self.countdown = countdown
        self.lat = lat
        self.lng = lng
        self.value = value
        self.shelters = shelters
    }
}
