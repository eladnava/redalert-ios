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
        if let url = URL(string: Config.appStoreURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    static func openWebSite() {
        if let url = URL(string: Config.webSiteURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    static func openLifeshieldWebsite() {
        if let url = URL(string: Config.lifeshieldWebSiteURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
