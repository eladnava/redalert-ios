//
//  Async.swift
//  RedAlert
//
//  Created by Elad on 11/4/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation
import Dispatch

struct Async {
    static func worker(label: String, callback: @escaping () -> (), uiCallback: @escaping () -> ()) {
        // Run code async        
        DispatchQueue.global().async(
            execute: {
            // Run code on async thread            
            callback()
            
            // Run code on UI thread            
            DispatchQueue.main.async(
                execute: {
                // Update the UI                
                uiCallback()
            })
        })
    }
}
