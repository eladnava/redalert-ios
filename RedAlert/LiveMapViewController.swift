//
//  LiveMapViewController.swift
//  RedAlert
//
//

import UIKit
import MapKit

class LiveMapViewController: UIViewController, MKMapViewDelegate {
    // Map view instance that displays alert pins and overlays
    var mapView = MKMapView()

    // Timer reference for periodic alert refresh; invalidated when view disappears
    var reloadTimer: Timer?

    // Currently displayed alerts (cached to detect changes between refresh cycles)
    var alerts: [Alert] = []
    
    // Full alerts list from API before dismiss/restore filtering
    var allAlerts: [Alert] = []

    // Small activity spinner shown while loading network updates; placed in navigation bar
    var activityIndicator = UIActivityIndicatorView()
    
    // Dismiss/restore alerts action button in the navigation bar
    var dismissAlertsButton = UIButton(type: .system)
    
    // App icon overlay shown in bottom-right corner of live map
    var appIconView = UIImageView()
    
    // Sets up UI elements (map view, activity indicator) and loads initial alerts
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure basic UI properties for the view controller
        self.title = NSLocalizedString("LIVE_MAP", comment: "Live map screen title")
        self.view.backgroundColor = UIColor.white

        // Initialize map view with delegate and add to view hierarchy
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add map view as subview
        self.view.addSubview(mapView)

        // Initialize activity indicator (spinner) for network operations
        activityIndicator.hidesWhenStopped = true
        
        // Configure dismiss/restore button
        dismissAlertsButton.addTarget(self, action: #selector(dismissAlertsTapped), for: .touchUpInside)
        
        // Set width & height of button
        NSLayoutConstraint.activate([
            dismissAlertsButton.widthAnchor.constraint(equalToConstant: 25),
            dismissAlertsButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        // Place action buttons in the navigation bar
        let dismissAlertsBarButton = UIBarButtonItem(customView: dismissAlertsButton)
        
        // Wrap activity indicator view in a bar button item
        let activityBarButton = UIBarButtonItem(customView: activityIndicator)
        
        // Show dismiss/restore first, then loading indicator on the right side
        self.navigationItem.rightBarButtonItems = [dismissAlertsBarButton, activityBarButton]
        
        // Set the initial icon based on current dismiss/restore state
        self.updateDismissAlertsButtonIcon()

        // Activate Auto Layout constraints for map view
        // Map view fills entire view (top/bottom/leading/trailing)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),      // Map left edge to view left
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),    // Map right edge to view right
            mapView.topAnchor.constraint(equalTo: view.topAnchor),              // Map top edge to view top
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)         // Map bottom edge to view bottom
        ])
        
        // Add app icon overlay in bottom-right corner of the map
        self.setupMapAppIcon()

        // Load the initial set of alerts immediately
        reloadLiveAlerts()
    }
    
    func setupMapAppIcon() {
        // Prefer AppIcon asset name and fall back to alert icon if unavailable
        appIconView.image = UIImage(named: "AppIcon") ?? UIImage(named: "AlertIcon")
        
        // Configure image display mode
        appIconView.contentMode = .scaleAspectFit
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Place icon on top of the map view
        mapView.addSubview(appIconView)
        
        // Pin icon to the bottom-right corner
        NSLayoutConstraint.activate([
            appIconView.widthAnchor.constraint(equalToConstant: 54),
            appIconView.heightAnchor.constraint(equalToConstant: 54),
            appIconView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -15),
            appIconView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -18)
        ])
    }

    // Called when the view controller's view is about to be added to the view hierarchy
    // Starts the periodic reload timer for fetching new alerts
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Keep dismiss/restore icon in sync when returning to this screen
        self.updateDismissAlertsButtonIcon()
        
        // Re-apply current filter to existing in-memory map alerts
        self.refreshLiveMap(recenter: false)

        // Start the periodic reload timer when view appears on screen
        startReloadTimer()
    }

    // Called when the view controller's view is about to be removed from the view hierarchy
    // Stops the periodic reload timer to avoid unnecessary background network activity
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Stop timer and clear reference to prevent timer from firing in background
        reloadTimer?.invalidate()
        reloadTimer = nil
    }

    // Deinitializer ensures timer is cleaned up when object is deallocated
    deinit {
        // Ensure timer is invalidated on deinit to prevent memory leaks
        reloadTimer?.invalidate()
    }

    // Timer Management
    
    // Start a repeating timer that calls `reloadLiveAlerts` at regular intervals
    // Invalidates existing timer before creating a new one to prevent duplicates
    func startReloadTimer() {
        // Invalidate any existing timer to ensure only one timer is active
        reloadTimer?.invalidate()
        
        // Create a new timer that fires every Config.recentAlertsRefreshIntervalSeconds
        // Uses the selector pattern to call reloadLiveAlerts on this instance
        reloadTimer = Timer.scheduledTimer(
            timeInterval: Config.recentAlertsRefreshIntervalSeconds,  // Interval between refreshes
            target: self,                                              // Target object (this view controller)
            selector: #selector(reloadLiveAlerts),                    // Method to call (reloadLiveAlerts)
            userInfo: nil,                                            // No additional data passed to selector
            repeats: true                                             // Timer repeats indefinitely until invalidated
        )
    }

    // Network Operations
    
    // Fetch the latest alerts from the server and update the map display
    // Shows/hides activity indicator and handles network errors
    // Runs on the main queue to ensure UI updates are thread-safe
    @objc func reloadLiveAlerts() {
        // Start the loading spinner if it's not already animating
        // Shows activity indicator in the navigation bar
        if !activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }

        // Use API helper to fetch recent alerts from the server
        RedAlertAPI.getRecentAlerts { err, alerts in
            // Dispatch UI updates back to the main thread
            DispatchQueue.main.async {
                // Stop spinner regardless of success or failure and hide from navigation bar
                self.activityIndicator.stopAnimating()

                // Check if an error occurred during the network request
                if let theErr = err {
                    // Construct error message starting with localized base message
                    var message = NSLocalizedString("RECENT_ALERTS_ERROR", comment: "Recent alerts error")
                    
                    // Append detailed error message from the error object if available
                    if let errMsg = theErr.userInfo["error"] as? String {
                        message += "\n\n" + errMsg
                    }
                    
                    // Display error dialog to the user
                    Dialogs.error(message: message)
                    return
                }

                // If server returned nil alerts, clear the map and don't recenter
                guard let alerts = alerts else {
                    self.allAlerts = []
                    self.refreshLiveMap(recenter: true)
                    return
                }

                // Determine whether to re-center the map based on whether alerts changed
                let shouldRecenter = self.didReceiveNewAlerts(alerts)
                                
                // Cache unfiltered alerts for comparisons and local dismiss/restore filtering
                self.allAlerts = alerts
                                
                // Update map from local filtered state
                self.refreshLiveMap(recenter: shouldRecenter)
            }
        }
    }

    // Data Comparison
    
    // Check whether newly fetched alerts are different from the currently displayed ones
    // Returns true when number of alerts changed or any alert content (city/threat/date) changed
    //
    // - Parameter alerts: New alerts array from server
    // - Returns: True if alerts differ from cached alerts, false if identical
    func didReceiveNewAlerts(_ alerts: [Alert]) -> Bool {
        // First, check if the count of alerts changed
        // If counts differ, definitely recenter since alert set changed
        if self.allAlerts.count != alerts.count {
            return true
        }

        // Compare each alert's content with the cached version
        // Iterate through all alerts and check for differences
        for i in 0..<alerts.count {
            // Get current (new) and previous (cached) alert at index i
            let current = alerts[i]
            let previous = self.allAlerts[i]
            
            // Compare city name, threat level, and date timestamp
            // Return true if any field differs (indicating a change)
            if current.city != previous.city || 
               current.threat != previous.threat || 
               current.date != previous.date {
                return true
            }
        }

        // If nothing changed and we had no alerts before, return whether cache was empty
        // This prevents unnecessary recentering if alerts list was already empty
        return self.allAlerts.isEmpty
    }
    
    func refreshLiveMap(recenter: Bool) {
        // Default to all alerts
        var filteredAlerts = self.allAlerts
        
        // Filter by dismissed timestamp if set
        if let cutoff = UserDefaults.standard.object(forKey: UserSettingsKeys.dismissAlertsTimestamp) as? Double {
            filteredAlerts = filteredAlerts.filter { $0.date > cutoff }
        }
        
        // Cache filtered alerts currently displayed on map
        self.alerts = filteredAlerts
        
        // Update map annotations immediately from local state
        self.updateMap(with: filteredAlerts, recenter: recenter)
    }
    
    @objc func dismissAlertsTapped() {
        // Read existing dismiss cutoff timestamp
        let ts = UserDefaults.standard.object(forKey: UserSettingsKeys.dismissAlertsTimestamp) as? Double
        
        // Existing cutoff means this tap is restore
        if ts != nil {
            // Remove dismiss cutoff to restore all visible alerts
            UserDefaults.standard.removeObject(forKey: UserSettingsKeys.dismissAlertsTimestamp)
            
            // Update the button icon to the clear state
            self.updateDismissAlertsButtonIcon()
            
            // Rebuild map and recenter to fit restored annotations
            self.refreshLiveMap(recenter: true)
            
            // Stop here because restore flow is complete
            return
        }
        
        // Ask user to confirm dismissing currently shown alerts
        let alert = UIAlertController(title: NSLocalizedString("DISMISS_ALERTS_CONFIRM_TITLE", comment: "Dismiss alerts title"), message: NSLocalizedString("DISMISS_ALERTS_CONFIRM_MESSAGE", comment: "Dismiss alerts message"), preferredStyle: .alert)
        
        // Add cancel action so user can back out safely
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL_BUTTON", comment: "Cancel"), style: .cancel, handler: nil))
        
        // Add destructive action to apply dismiss cutoff
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK_BUTTON", comment: "OK"), style: .destructive, handler: { _ in
            // Capture current time as dismiss cutoff
            let now = Date().timeIntervalSince1970
            
            // Persist cutoff so older alerts are filtered out
            UserDefaults.standard.set(now, forKey: UserSettingsKeys.dismissAlertsTimestamp)
            
            // Update the button icon to the restore state
            self.updateDismissAlertsButtonIcon()
            
            // Refresh map from local data without forced recenter
            self.refreshLiveMap(recenter: false)
        }))
        
        // Present confirmation alert to the user
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateDismissAlertsButtonIcon() {
        // Read dismiss cutoff to determine current mode
        let ts = UserDefaults.standard.object(forKey: UserSettingsKeys.dismissAlertsTimestamp) as? Double
        
        // Pick clear icon when active or restore icon when dismissed
        let imageName = ts == nil ? "ClearIcon" : "RestoreIcon"
        
        // Apply selected icon to dismiss/restore button
        dismissAlertsButton.setImage(UIImage(named: imageName), for: .normal)
    }

    // Map Updates
    
    // Replace current non-user annotations with new alert annotations and optionally re-center map
    // Removes old annotations, creates new ones from alerts, and adjusts map region
    //
    // - Parameters:
    //   - alerts: Array of Alert objects to display on the map
    //   - recenter: If true, adjust map region to fit all annotations
    func updateMap(with alerts: [Alert], recenter: Bool) {
        // Remove existing annotations except user's location annotation (MKUserLocation)
        // Filter out the user location annotation which should remain on map
        let nonUserAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        
        // Remove all old annotations
        mapView.removeAnnotations(nonUserAnnotations)
        
        // Remove old polygon overlays so map matches current alert set
        mapView.removeOverlays(mapView.overlays)

        // Array to store newly created point annotations for all alerts
        var annotations: [MKPointAnnotation] = []
        
        // Track cities for which we already added polygon overlays
        var polygonCityIds = Set<Int>()
        
        // Get cached city metadata (coordinates and localized names) for all cities
        let cityCache = LocationMetadata.getCities()
        
        // Get cached polygon metadata for city boundary overlays
        let polygonCache = LocationMetadata.getPolygons()

        // Convert each alert into a map point annotation
        // Iterate through all alerts and create annotations using city coordinates
        for alert in alerts {
            // Skip alerts with threat types that should not be shown on the live map
            // Filter out "earlyWarning" (early warning alerts) and "leaveShelter" (all-clear alerts)
            if alert.threat == "earlyWarning" || alert.threat == "leaveShelter" {
                // Skip this alert and move to the next one
                continue
            }
            
            // Search city cache for matching city name from the alert
            if let city = cityCache.first(where: { $0.name == alert.city }) {
                // Add city polygon once so overlapping alerts don't duplicate overlays
                if !polygonCityIds.contains(city.id) {
                    // Find polygon data for this city ID
                    if let polygon = polygonCache.first(where: { $0.id == city.id }) {
                        // Convert raw polygon coordinates to CLLocationCoordinate2D points
                        let polygonPoints = polygon.coordinates.map {
                            CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
                        }
                        
                        // Add polygon overlay when at least one point was loaded
                        if !polygonPoints.isEmpty {
                            mapView.add(MKPolygon(coordinates: polygonPoints, count: polygonPoints.count))
                            polygonCityIds.insert(city.id)
                        }
                    }
                }
                
                // Create a new point annotation for this alert
                let annotation = MKPointAnnotation()
                
                // Set the coordinate using city's latitude and longitude
                annotation.coordinate = CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng)
                
                // Set the title to localized city name (English or Hebrew based on settings)
                annotation.title = LocationMetadata.localizedDisplayName(for: city)
                
                // Set the subtitle to threat level and formatted date/time string
                annotation.subtitle = alert.localizedThreat + " " + DateFormatterStruct.ConvertUnixTimestampToDateTime(unixTimestamp: alert.date)
                
                // Add the newly created annotation to the collection
                annotations.append(annotation)
            }
        }

        // Add all newly created annotations to the map view
        mapView.addAnnotations(annotations)

        // Re-center map to show all annotations if recenter flag is true or no annotations exist
        if recenter || mapView.annotations.isEmpty {
            zoomToFit(annotations: annotations)
        }
    }

    // Map Region Adjustment
    
    // Adjust map region to fit given annotations with appropriate zoom level
    // - If no annotations: set default region from Config
    // - If single annotation: zoom in to a small span around that point
    // - Otherwise use showAnnotations to fit all annotations in view
    //
    // - Parameter annotations: Array of point annotations to fit in the map view
    func zoomToFit(annotations: [MKPointAnnotation]) {
        // BRANCH 1: No annotations case - show default region
        // If there are no annotations to display, use hardcoded default region
        if annotations.count == 0 {
            // Create center coordinate from Config default latitude and longitude
            let center = CLLocationCoordinate2DMake(Config.defaultMapLat, Config.defaultMapLng)
            
            // Create a coordinate span from Config default zoom values (latitude and longitude delta)
            let span = MKCoordinateSpanMake(Config.defaultMapZoom, Config.defaultMapZoom)
            
            // Set the map region with the default center and span, animating to it
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
            return
        }

        // BRANCH 2: Single annotation case - zoom in to that point
        // If there is exactly one alert, zoom in closely to that location
        if annotations.count == 1 {
            // Extract the coordinate from the single annotation
            let coordinate = annotations[0].coordinate
            
            // Create a tight zoom span (0.1 degrees on each side)
            let span = MKCoordinateSpanMake(0.1, 0.1)
            
            // Set the map region centered on the single alert with close zoom, animating to it
            mapView.setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: true)
            return
        }

        // BRANCH 3: Multiple annotations case - fit all in view
        // If there are multiple alerts, let MapKit compute a region that fits all annotations
        // This automatically calculates the best region to show all points
        var zoomRect = MKMapRectNull

        // Traverse annotations
        for annotation in annotations {
            let point = MKMapPointForCoordinate(annotation.coordinate)
            let rect = MKMapRectMake(point.x, point.y, 0.1, 0.1)
            zoomRect = MKMapRectUnion(zoomRect, rect)
        }

        // Add extra padding
        let padding = UIEdgeInsets(top: 180, left: 140, bottom: 180, right: 140)

        // Zoom map to fit all annotations
        mapView.setVisibleMapRect(zoomRect, edgePadding: padding, animated: true)
    }

    // MKMapViewDelegate
    
    // Provide a custom renderer for polygon overlays on the map
    // Returns red semi-transparent fill with red stroke for polygon regions
    // Used by other map screens to display region boundaries
    //
    // - Parameters:
    //   - mapView: The map view requesting the renderer
    //   - overlay: The overlay object (polygon or other type)
    // - Returns: MKOverlayRenderer instance configured for the overlay type
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // Check if the overlay is a polygon type (used for region boundaries)
        if overlay is MKPolygon {
            // Create a polygon renderer for this overlay
            let renderer = MKPolygonRenderer(overlay: overlay)
            
            // Set the fill color to red with 40% opacity (semi-transparent)
            // Red components: 0.7 (70% red), 0.0 (0% green), 0.0 (0% blue), 0.4 (40% alpha)
            renderer.fillColor = UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 0.4)
            
            // Set the stroke (border) color to bright red with 60% opacity
            // Red components: 1.0 (100% red), 0.0 (0% green), 0.0 (0% blue), 0.6 (60% alpha)
            renderer.strokeColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.6)
            
            // Set the line width for the polygon border (1.0 point width)
            renderer.lineWidth = 1.0
            
            // Return the configured polygon renderer
            return renderer
        }

        // For non-polygon overlays, return a generic overlay renderer
        return MKOverlayRenderer(overlay: overlay)
    }
}
