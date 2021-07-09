//
//  Config.swift
//  RedAlert
//
//  Created by Elad on 10/15/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation
import MapKit

struct Config {
    // API server    
//    static let apiBaseURL = "http://127.0.0.1:3000"
    static let apiBaseURL = "https://redalert.me"
    
    // URLs    
    static let webSiteURL = "https://redalert.me"
    static let lifeshieldWebSiteURL = "http://www.operationlifeshield.org/"
    static let appStoreURL = "itms-apps://itunes.apple.com/app/id937914925"
    
    // Contact info    
    static let contactEmail = "support@redalert.me"
    
    // Recent Alerts screen    
    static let imSafeButtonHeight = 50 as CGFloat
    static let recentAlertsRefreshIntervalSeconds = 25 as TimeInterval
    
    // MapKit    
    static let annotationPadding = 300.0
    
    static let defaultMapZoom = 2.9
    static let defaultMapLat = 31.4117256 as CLLocationDegrees
    static let defaultMapLng = 35.0818155 as CLLocationDegrees
}
