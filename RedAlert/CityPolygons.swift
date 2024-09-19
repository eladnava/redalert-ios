//
//  CityPolygons.swift
//  RedAlert
//
//  Created by Elad Nava on 9/19/24.
//  Copyright © 2024 Elad Nava. All rights reserved.
//

import Foundation

class CityPolygons {
    var id: Int, coordinates: [[Double]]
    
    // Main INIT function
    init(id: Int, coordinates: [[Double]]) {
        // Assign members
        self.id = id
        self.coordinates = coordinates
    }
}
