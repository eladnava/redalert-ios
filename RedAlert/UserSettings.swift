//
//  UserSettings.swift
//  RedAlert
//
//  Created by Elad on 10/18/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct UserSettings {
    static func getStringArray(key: String) -> [String] {
        // Get selected items by key
        let selected = self.getString(key: key, defaultValue: "")
        
        // Explode PSV into array
        return selected.components(separatedBy: "|").filter {
            $0.count > 0
        }
    }
    
    static func getStringArrayByValue(value: String) -> [String] {
        // Explode PSV into array
        return value.components(separatedBy: "|").filter {
            $0.count > 0
        }
    }
    
    static func getString(key: String, defaultValue: String) -> String {
        // Get stored value        
        let result = UserDefaults.standard.string(forKey: key)
        
        // Doesn't exist?        
        if (result == nil) {
            return defaultValue
        }
        
        // Return saved result        
        return result!
    }
    
    static func getBool(key: String, defaultValue: Bool) -> Bool {
        // Check if it exists first
        if (UserDefaults.standard.object(forKey: key) != nil) {
            // Return stored value
            return UserDefaults.standard.bool(forKey: key)
        }
        else {
            // Return default value if doesn't exist yet
            return defaultValue
        }
    }
    
    static func setBool(key: String, value: Bool) {
        // Set stored value        
        return UserDefaults.standard.set(value, forKey: key)
    }
    
    static func setString(key: String, value: String) {
        // Just store it        
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func setStringArray(key: String, value: [String]) {
        // Just store it        
        UserDefaults.standard.set(value, forKey: key)
    }
}
