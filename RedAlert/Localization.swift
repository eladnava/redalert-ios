//
//  Localization.swift
//  RedAlert
//
//  Created by Elad on 11/3/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct Localization {
    static func isRTL() -> Bool {
        // Return true in case device language is RTL        
        return UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft
    }
    
    static func shouldLocalizeToEnglish() -> Bool {
        // Get language code
        let lang = self.getDeviceLanguageCode()
        
        // English location names (cities, zones) for every language except Hebrew, Russian, and Arabic
        return !lang.starts(with: "he") && !lang.starts(with: "ru") && !lang.starts(with: "ar")
    }
    
    static func shouldLocalizeToRussian() -> Bool {
        // Return true when language is Russian
        return self.getDeviceLanguageCode().starts(with: "ru")
    }
    
    static func shouldLocalizeToArabic() -> Bool {
        // Return true when language is Arabic
        return self.getDeviceLanguageCode().starts(with: "ar")
    }
    
    static func getDeviceLanguageCode() -> String {
        // Return first preferred lang        
        return NSLocale.preferredLanguages.first! as String
    }
    
    static func overrideAppLanguage() {
        // Get overriden language        
        let lang = UserSettings.getString(key: UserSettingsKeys.language, defaultValue: "")
        
        // Automatic?        
        if (lang.isEmpty) {
            // Delete our overriden lang            
            UserDefaults.standard.removeObject(forKey: UserSettingsKeys.appleLanguages)
        }
        else {
            // Save to UserDefaults        
            UserSettings.setStringArray(key: UserSettingsKeys.appleLanguages, value: [lang])
        }
    }
}
