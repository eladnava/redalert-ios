//
//  App.swift
//  RedAlert
//
//  Created by Elad on 10/29/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct App {
    static func getVersion() -> String {
        // Retrieve it from infoDictionary        
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    
    static func openAppStore() {
        // Open app store page        
        UIApplication.shared.openURL(URL(string: Config.appStoreURL)!)
    }
    
    static func openWebSite() {
        // Open official Web site
        UIApplication.shared.openURL(URL(string: Config.webSiteURL)!)
    }
    
    static func openLifeshieldWebsite() {
        // Open Lifeshield official Web site
        UIApplication.shared.openURL(URL(string: Config.lifeshieldWebSiteURL)!)
    }
}
