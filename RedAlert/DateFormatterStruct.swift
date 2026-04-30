//
//  DateFormatter.swift
//  RedAlert
//
//  Created by Elad on 10/16/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct DateFormatterStruct {
    static func ConvertUnixTimestampToDateTime(unixTimestamp: Double!) -> String {
        // Convert Unix timestamp to Date() object
        let date = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))

        // Prepare date formatter for generating alert time string
        let dateFormatter = DateFormatter()
        
        // iOS 13+ required to access RelativeDateTimeFormatter
        if #available(iOS 13.0, *) {
            // Initialize formatter
            let relativeFormatter = RelativeDateTimeFormatter()

            // Calculate relative time ago
            let relativeDate = relativeFormatter.localizedString(for: date, relativeTo: Date())
            
            // Convert relative time digits to Arabic-Indic numerals when Arabic is active
            let localizedRelativeDate = localizeDigitsForCurrentLanguage(value: relativeDate)
            
            // Set hours and minutes format (13:30:01)
            dateFormatter.dateFormat = "(HH:mm:ss)"
            
            // Convert unix timestamp to string using format above
            let time = dateFormatter.string(from: date)
            
            // Convert time digits to Arabic-Indic numerals when Arabic is active
            let localizedTime = localizeDigitsForCurrentLanguage(value: time)

            // Return relative date
            return localizedRelativeDate + " " + localizedTime
        } else {
            // Set hours and minutes format without parenthesis
            dateFormatter.dateFormat = "HH:mm:ss"
            
            // Convert unix timestamp to string using format above
            let time = dateFormatter.string(from: date)
            
            // Convert time digits to Arabic-Indic numerals when Arabic is active
            let localizedTime = localizeDigitsForCurrentLanguage(value: time)
            
            // Fallback to just displaying the hours and minutes on earlier iOS versions
            return localizedTime
        }

    }
    
    static func ConvertUnixTimestampRangeToDateTime(minTimestamp: Double, maxTimestamp: Double) -> String {
        // Convert timestamps to Date objects
        let minDate = Date(timeIntervalSince1970: TimeInterval(minTimestamp))
        let maxDate = Date(timeIntervalSince1970: TimeInterval(maxTimestamp))

        // Prepare date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        let minTime = dateFormatter.string(from: minDate)
        let maxTime = dateFormatter.string(from: maxDate)
        
        // Convert min time digits to Arabic-Indic numerals when Arabic is active
        let localizedMinTime = localizeDigitsForCurrentLanguage(value: minTime)
        
        // Convert max time digits to Arabic-Indic numerals when Arabic is active
        let localizedMaxTime = localizeDigitsForCurrentLanguage(value: maxTime)
        
        // iOS 13+ required to access RelativeDateTimeFormatter
        if #available(iOS 13.0, *) {
            // Initialize formatter
            let relativeFormatter = RelativeDateTimeFormatter()

            // Calculate relative time ago (use min date)
            let relativeDate = relativeFormatter.localizedString(for: minDate, relativeTo: Date())
            
            // Convert relative time digits to Arabic-Indic numerals when Arabic is active
            let localizedRelativeDate = localizeDigitsForCurrentLanguage(value: relativeDate)
            
            // Return relative date with time range
            return localizedRelativeDate + " (" + localizedMinTime + " - " + localizedMaxTime + ")"
        } else {
            // Fallback to just displaying the time range
            return localizedMinTime + " - " + localizedMaxTime
        }
    }
    
    static func localizeDigitsForCurrentLanguage(value: String) -> String {
        // Arabic not active? keep original digits
        if !Localization.shouldLocalizeToArabic() {
            return value
        }
        
        // Convert each ASCII digit to Arabic-Indic digit deterministically
        let mapped = value.map { char -> Character in
            switch char {
            case "0": return "٠"
            case "1": return "١"
            case "2": return "٢"
            case "3": return "٣"
            case "4": return "٤"
            case "5": return "٥"
            case "6": return "٦"
            case "7": return "٧"
            case "8": return "٨"
            case "9": return "٩"
            default: return char
            }
        }
        
        // Return localized string with Arabic-Indic numerals
        return String(mapped)
    }
}
