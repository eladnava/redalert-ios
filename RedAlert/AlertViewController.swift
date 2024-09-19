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
        
        // Prepare array of all polygon points from all cities
        var allPolygonPoints:[CLLocationCoordinate2D] = []
        
        // Check locale first        
        let isEnglish = Localization.isEnglish()
        
        // Load polygons from JSON
        let polygonCache = LocationMetadata.getPolygons()
        
        // Traverse alert cities        
        for city in alertCities {
            // Got a geolocation for this city?
            if city.lat > 0 && city.lng > 0 {
                // Array of polygon points for this city
                var cityPolygonPoints:[CLLocationCoordinate2D] = []
                
                // Find city in polygon cache
                for polygon in polygonCache {
                    // Found city with this ID?
                    if polygon.id == city.id {
                        // Traverse polygon coordinates
                        for coordinate in polygon.coordinates {
                            // Create CLLocationCoordinate2D for each point
                            let coordinate = CLLocationCoordinate2D(latitude: coordinate[0], longitude: coordinate[1])
                            
                            // Add to array of points for this city
                            cityPolygonPoints.append(coordinate)
                            
                            // Add to array of points for entire map
                            allPolygonPoints.append(coordinate)
                        }
                    }
                }
                
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
                
                // Polygon loaded for this city?
                if cityPolygonPoints.count > 0 {
                    // Add polygon to map
                    mapView.add(MKPolygon(coordinates: cityPolygonPoints, count: cityPolygonPoints.count))
                
                    // Set marker location as polygon center point
                    annotation.coordinate = MKCoordinateRegion(coordinates: cityPolygonPoints).center
                }
                
                // Add to annotations
                annotations.append(annotation)
            }
        }
        
        // Reposition map to show annotations
        mapView.showAnnotations(annotations, animated: true)
        
        // Just one city?
        if annotations.count == 1 {
            // Set map center to single city/settlement coordinates
            let center = CLLocationCoordinate2DMake(annotations[0].coordinate.latitude, annotations[0].coordinate.longitude)
            
            // Close-up zoom
            let span = MKCoordinateSpanMake(0.1, 0.1)
            
            // Move map and set zoom
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
        // More than one city & have polygons?
        else if allPolygonPoints.count > 0 {
            // Display all polygons from all cities
            mapView.setRegion(MKCoordinateRegion(coordinates: allPolygonPoints), animated: true)
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
    
    func UIColorFromRGB(_ rgbValue: Int) -> UIColor! {
        // Convert RGB hex code to UICOlor
        return UIColor(
            red: CGFloat((Float((rgbValue & 0xff0000) >> 16)) / 255.0),
            green: CGFloat((Float((rgbValue & 0x00ff00) >> 8)) / 255.0),
            blue: CGFloat((Float((rgbValue & 0x0000ff) >> 0)) / 255.0),
            alpha: 1.0)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Set polygon colors
        if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(overlay: overlay)
            renderer.fillColor = UIColorFromRGB(0xb3ffafaf)
            renderer.strokeColor = UIColorFromRGB(0xffe40000)
            renderer.lineWidth = 1
            return renderer
        }
        
        // Defaul to overlay renderer
        return MKOverlayRenderer()
    }
}

extension MKCoordinateRegion {

  init(coordinates: [CLLocationCoordinate2D]) {
    var minLatitude: CLLocationDegrees = 90.0
    var maxLatitude: CLLocationDegrees = -200.0
    var minLongitude: CLLocationDegrees = 90.0
      var maxLongitude: CLLocationDegrees = -200.0

    for coordinate in coordinates {
      let lat = Double(coordinate.latitude)
      let long = Double(coordinate.longitude)
      if lat < minLatitude {
        minLatitude = lat
      }
      if long < minLongitude {
        minLongitude = long
      }
      if lat > maxLatitude {
        maxLatitude = lat
      }
      if long > maxLongitude {
        maxLongitude = long
      }
    }

    let span = MKCoordinateSpanMake((maxLatitude - minLatitude) / 0.5, (maxLongitude - minLongitude) / 0.5)
    let center = CLLocationCoordinate2DMake((maxLatitude + minLatitude) * 0.5, (maxLongitude + minLongitude) * 0.5)
     
    self.init(center: center, span: span)
  }
}
