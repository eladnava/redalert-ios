//
//  SoundItemGenerator.swift
//  RedAlert
//
//  Created by Elad on 10/18/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct SoundItemGenerator {
    static func generateSoundItems() -> [SoundItem] {
        // Create items array        
        var items: [SoundItem] = []
        
        // Get items as array        
        let sounds = JSON.parseJSONFile(file: "Sounds")
        
        // Error?        
        if (sounds == nil) {
            return items
        }
        
        // Loop over them        
        for item in sounds as! [NSDictionary] {
            // Add city name to list            
            items.append(SoundItem(title: item["name"] as! String, value: item["value"] as! String ))
        }
        
        // Join items into string        
        return items
    }

}
