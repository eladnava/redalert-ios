//
//  SoundItem.swift
//  RedAlert
//
//  Created by Elad on 10/18/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

class SoundItem {
    var title: String
    var value: String
    var selected: Bool
    
    init(title: String, value: String) {
        // Set title and value        
        self.title = title
        self.value = value
        self.selected = false
    }
}