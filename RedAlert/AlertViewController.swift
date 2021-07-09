//
//  AlertsViewController.swift
//  RedAlert
//
//  Created by Elad on 10/14/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit
import MapKit

class AlertViewController: UIViewController, MKMapViewDelegate {
    var alert: Alert?, alertCities: [City] = []
    
    @IBOutlet weak var mapView: MKMapView!
    
    func setAlert(alert: Alert) {
        // Save the alert for later        
        self.alert = alert
        
        // Get alert cities        
        let cities = LocationMetadata.getCities()
        
        // Traverse cities        
        for city in cities {
            // Name match?
            if (city.name == alert.city) {
                // Add alert city                
                alertCities.append(city)
            }
        }
    }
    
    override func viewDidLoad() {
        // Call super first        
        super.viewDidLoad()
        
        // Unwrap alert        
        if let alert = alert {
            // Set window title to localized city name
            self.title = alert.localizedCity
        }
        
        // Load mapview 
        self.loadMap()
    }
    
    func loadMap() {
        // Prepare annotations array        
        var annotations: [MKPointAnnotation] = []
        
        // Check locale first        
        let isEnglish = Localization.isEnglish()
        
        // Traverse alert cities        
        for city in alertCities {
            // Got a geolocation for this city?
            if city.lat > 0 && city.lng > 0 {
                // Create new map marker
                let annotation = MKPointAnnotation()
                
                // Set position as the city's latitude, longitude
                annotation.coordinate = CLLocationCoordinate2DMake(city.lat, city.lng)
                
                // Set title and snippet
                annotation.title = (isEnglish) ? city.name_en : city.name
                
                // Got any shelters for this city?
                if (city.shelters > 0) {
                    annotation.subtitle = NSLocalizedString("LIFESHIELD_SHELTERS", comment: "Lifeshield shelter count") + " " + String(city.shelters)
                }
                
                // Add to annotations
                annotations.append(annotation)
            }
        }
        
        // Got any cities?        
        if annotations.count > 0 {
            // Reposition map to show all of them            
            mapView.showAnnotations(annotations, animated: true)
            
            // Pad the annotations            
            mapView.camera.altitude *= Config.annotationPadding
        }
        else {
            // Set default map center to Config-defined lat,lng            
            let center = CLLocationCoordinate2DMake(Config.defaultMapLat, Config.defaultMapLng)
            
            // Set default zoom            
            let span = MKCoordinateSpanMake(Config.defaultMapZoom, Config.defaultMapZoom)
            
            // Move map and set zoom            
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        // Just call super        
        super.didReceiveMemoryWarning()
    }
}
