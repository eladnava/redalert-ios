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
        // Prepare date formatter for time of alert        
        let dateFormatter = DateFormatter()
        
        // Set format (13:30:01)        
        dateFormatter.dateFormat = "(dd/MM/yy) HH:mm:ss"
        
        // Convert unix timestamp to readable human time and override timestamp        
        return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(unixTimestamp )) as Date)
    }
}
