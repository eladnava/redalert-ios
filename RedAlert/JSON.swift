//
//  JSON.swift
//  RedAlert
//
//  Created by Elad on 10/18/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct JSON
{
    static func parseJSONFile(file: String) -> NSArray? {
        // Construct physical path to json file        
        let path = Bundle.main.path(forResource: file, ofType: "json")
        
        // Load file into memory        
        let jsonData = try! NSData(contentsOfFile:path!, options: .mappedIfSafe)
        
        // Prepare as JSON array        
        var json: NSArray?
        
        do {
            // Serialize request JSON into string            
            json = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSArray
        }
        catch {
            // Return nil            
            return nil
        }
        
        // Return zones array        
        return json
    }
}
