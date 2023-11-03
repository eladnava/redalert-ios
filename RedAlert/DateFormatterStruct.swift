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
            
            // Set hours and minutes format (13:30:01)
            dateFormatter.dateFormat = "(HH:mm:ss)"
            
            // Convert unix timestamp to string using format above
            let time = dateFormatter.string(from: date);

            // Return relative date
            return relativeDate + " " + time
        } else {
            // Set hours and minutes format without parenthesis
            dateFormatter.dateFormat = "HH:mm:ss"
            
            // Convert unix timestamp to string using format above
            let time = dateFormatter.string(from: date);
            
            // Fallback to just displaying the hours and minutes on earlier iOS versions
            return time
        }

    }
}
