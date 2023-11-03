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
        
        // Traverse grouped alert cities
        for cityName in alert.groupedCities {
            // Traverse cities
            for city in cities {
                // Name match?
                if (city.name == cityName) {
                    // Add alert city
                    alertCities.append(city)
                }
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
        
        // Reposition map to show annotations
        mapView.showAnnotations(annotations, animated: true)
        
        // Got any cities?        
        if annotations.count > 1 {
            // Center around all annotations but add padding from edges of screen
            mapView.camera.altitude *= Config.annotationPadding
        }
        else if annotations.count == 1 {
            // Set map center to single city/settlement coordinates
            let center = CLLocationCoordinate2DMake(annotations[0].coordinate.latitude, annotations[0].coordinate.longitude)
            
            // Close-up zoom
            let span = MKCoordinateSpanMake(0.1, 0.1)
            
            // Move map and set zoom
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
        else {
            // Set default map center to config-defined lat,lng (Israel)
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
