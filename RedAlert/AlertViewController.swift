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
    var threatIconView = UIImageView()
    
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
        
        // Add threat icon overlay in bottom-right corner of map
        self.setupThreatIcon()
    }
    
    func loadMap() {
        // Prepare annotations array        
        var annotations: [MKPointAnnotation] = []
        
        // All-clear alerts should show polygons only (no map markers)
        let isAllClearAlert = alert?.threat.contains("leaveShelter") ?? false
        
        // Prepare array of all polygon points from all cities
        var allPolygonPoints:[CLLocationCoordinate2D] = []
        
        
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
                annotation.title = LocationMetadata.localizedDisplayName(for: city)
                
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
                
                // Add marker only when current alert is not all-clear
                if !isAllClearAlert {
                    // Append configured city marker to annotations list
                    annotations.append(annotation)
                }
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
    
    func setupThreatIcon() {
        // Resolve current threat icon image
        let image = getThreatImage(alert?.threat ?? "")
        
        // Skip setup when image asset is unavailable
        if image == nil {
            return
        }
        
        // Configure icon view
        threatIconView.image = image
        threatIconView.contentMode = .scaleAspectFit
        threatIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add on top of map
        mapView.addSubview(threatIconView)
        
        // Position in bottom-right corner
        NSLayoutConstraint.activate([
            threatIconView.widthAnchor.constraint(equalToConstant: 54),
            threatIconView.heightAnchor.constraint(equalToConstant: 54),
            threatIconView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -15),
            threatIconView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -18)
        ])
    }
    
    func getThreatImage(_ threat: String) -> UIImage? {
        // Fall back to generic alert icon when threat value is missing
        if threat.isEmpty {
            return UIImage(named: "AlertIcon")
        }
        
        // Radiological event threat icon
        if threat.contains("radiologicalEvent") {
            return UIImage(named: "RadiologicalEventIcon")
        }
        // Hostile aircraft intrusion threat icon
        else if threat.contains("hostileAircraftIntrusion") {
            return UIImage(named: "HostileAircraftIntrusionIcon")
        }
        // Hazardous materials threat icon
        else if threat.contains("hazardousMaterials") {
            return UIImage(named: "HazardousMaterialsIcon")
        }
        // Tsunami threat icon
        else if threat.contains("tsunami") {
            return UIImage(named: "TsunamiIcon")
        }
        // Missile alerts use the generic alert icon
        else if threat.contains("missiles") {
            return UIImage(named: "AlertIcon")
        }
        // Terrorist infiltration threat icon
        else if threat.contains("terroristInfiltration") {
            return UIImage(named: "TerroristInfiltrationIcon")
        }
        // Earthquake threat icon
        else if threat.contains("earthQuake") {
            return UIImage(named: "EarthquakeIcon")
        }
        // Leave shelter (incident ended) threat icon
        else if threat.contains("leaveShelter") {
            return UIImage(named: "LeaveShelterIcon")
        }
        // Early warning threat icon
        else if threat.contains("earlyWarning") {
            return UIImage(named: "EarlyWarningIcon")
        }
        
        // Unknown threat types fall back to generic alert icon
        return UIImage(named: "AlertIcon")
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
            // Use green for all-clear alerts, red for all other threats
            let isAllClearAlert = alert?.threat.contains("leaveShelter") ?? false
            
            // Set polygon fill color based on all-clear state
            renderer.fillColor = isAllClearAlert ? UIColorFromRGB(0xb3afffaf) : UIColorFromRGB(0xb3ffafaf)
            
            // Make polygon background translucent at 40% opacity
            renderer.fillColor = renderer.fillColor?.withAlphaComponent(0.4)
            
            // Set polygon stroke color based on all-clear state
            renderer.strokeColor = isAllClearAlert ? UIColorFromRGB(0xff00a000) : UIColorFromRGB(0xffe40000)
            
            // Keep polygon border width at one point
            renderer.lineWidth = 1
            
            // Return configured polygon renderer to MapKit
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
