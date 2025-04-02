//
//  RecentAlertsTableViewController.swift
//  RedAlert
//
//  Created by Elad on 10/14/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit

class AlertTableViewController: UITableViewController, UIAlertViewDelegate {
    // Class members    
    var reloading = false, imSafe = UIView(), noAlerts = UIView(), pullToRefresh = UIRefreshControl(), alerts: [Alert] = [], currentScrollPos : CGFloat?
    
    override func viewWillAppear(_ animated: Bool) {
        // Do we have any alerts being displayed?
        if (self.alerts.count > 0) {
            // Refresh display of alerts to update bold styling in case selected cities/zones changed
            self.refreshAlertsTable()
        }
    }
    
    // View loaded initially (called once)
    override func viewDidLoad() {
        // Call super function        
        super.viewDidLoad()
        
        // Allow pulling the table to reload it        
        self.addPullToRefresh()
        
        // Add i'm safe button        
        self.addSafeButton()
        
        // Add default view in case of no alerts        
        self.addDefaultView()
        
        // Hide the empty separators before content loads        
        self.hideEmptyCellSeparators()
        
        // Programatic pull to refresh        
        self.initialPullToRefresh()
        
        // Reload recent alerts (Timer does not tick when initialized)        
        self.reloadRecentAlerts()
        
        // Create timer to refresh recent alerts list        
        self.startReloadTimer()
        
        // Make sure we can  receive alerts        
        self.verifyPushCapability()
        
        // Check for updates        
        self.checkForUpdates()
        
        // Auto cell height
        self.tableView.estimatedRowHeight = 85.5
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func checkForUpdates() {
        // Let the API handle it        
        RedAlertAPI.getAppUpdatesAsync(delegate: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Only handle alertview segue        
        if (segue.identifier != "AlertViewSegue") {
            return
        }
        
        // Unwrap variable        
        if let tableView = self.tableView {
            // Get selected index            
            let path = tableView.indexPathForSelectedRow
            
            // Unwrap variable            
            if let path = path {
                // Make sure index is valid
                if path.row < self.alerts.count {
                    // Get alert at index
                    let alert = self.alerts[path.row]
                    
                    // Let the API handle it
                    let vc = segue.destination as! AlertViewController
                    
                    // Pass the alert
                    vc.setAlert(alert: alert)
                }
            }
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        // Update clicked?        
        if (buttonIndex == 1) {
            // Take user to app page            
            App.openAppStore()
        }
    }
    
    func verifyPushCapability() {
        // User turned off push in  iOS settings?        
        if (RedAlertAPI.isRegistered() && !RedAlertAPI.canReceiveNotifications()) {
            // Show an error            
            return Dialogs.error(message: NSLocalizedString("UNREGISTERED_ERROR", comment: "Unregistered error message"))
        }
    }
    
    func addDefaultView() {
        // Get view from nib        
        let xib = Bundle.main.loadNibNamed("NoAlertsView", owner: self, options: nil)! as NSArray
        
        // Fail-safe        
        if (xib.count == 0) {
            return
        }
        
        // Get UI view        
        self.noAlerts = xib.object(at: 0) as! UIView
        
        // Unwrap safely
        if let navigationController = self.navigationController {
            // Set frame without navbar
            self.noAlerts.frame = CGRect(0, 0, tableView.frame.width, tableView.frame.height - navigationController.navigationBar.frame.height - UIApplication.shared.statusBarFrame.size.height - Config.imSafeButtonHeight)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Fix iPad white background        
        cell.backgroundColor = UIColor.clear
    }
    
    func hideEmptyCellSeparators() {
        // Dirty hack to hide empty cell separators        
        tableView.tableFooterView = UIView()
    }
    
    func initialPullToRefresh() {
        // Account for navbar height        
        self.tableView.contentOffset = CGPoint(0, -pullToRefresh.frame.size.height)
    }
    
    func addSafeButton() {
        // Get view from nib        
        let xib = Bundle.main.loadNibNamed("SafeButtonView", owner: self, options: nil)! as NSArray
        
        // Fail-safe        
        if (xib.count == 0) {
            return
        }
        
        // Get UI view        
        self.imSafe = xib.object(at: 0) as! UIView
        
        // Set auto resize mode when rotating phone so only width changes        
        self.imSafe.autoresizingMask = UIViewAutoresizing.flexibleWidth
        
        // Onclick-handler        
        self.imSafe.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AlertTableViewController.safeButtonTapped(recognizer:))))
        
        // Account for navbar height        
        if let tableView = self.tableView {
            // Add subview to table            
            tableView.addSubview(self.imSafe)
            
            // Calculate margin from bottom of screen            
            let insets = UIEdgeInsetsMake(0, 0, Config.imSafeButtonHeight, 0)
            
            // Prevent tableView contents from being hidden by overlay (also for scrollbar)            
            tableView.contentInset = insets
            tableView.scrollIndicatorInsets = insets
        }
        
        // Calculate the height and frame of safe button        
        self.recalculateViewHeights()
        
        // Make sure we don't get overriden by default no alerts screen        
        self.imSafe.layer.zPosition = 100
    }
    
    func recalculateViewHeights() {
        // Unwrap variable        
        if let tableView = self.tableView {
            // Get button height from config            
            let height = Config.imSafeButtonHeight
            
            // Set view frame to appear X pixels away from the bottom of the screen            
            self.imSafe.frame = CGRect(0, tableView.frame.height - height, tableView.frame.width, height)
            
            // Must call this, otherwise it gets shoved off the screen            
            self.scrollViewDidScroll(tableView)
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // Recalculate frames        
        self.recalculateViewHeights()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Reposition the safe button by placing it at bottom of table, minus its height and adding the scroll amount        
        self.imSafe.frame.origin.y = scrollView.frame.height - self.imSafe.frame.height + scrollView.contentOffset.y
        
        // Force the tableView to stay at same scroll position when reloading data
        if currentScrollPos != nil {
            tableView.setContentOffset(CGPoint(x: 0, y: currentScrollPos!), animated: false)
        }
    }
    
    @objc func safeButtonTapped(recognizer: UITapGestureRecognizer) {
        // Create share extension controller        
        let controller = UIActivityViewController(activityItems: [NSLocalizedString("IM_SAFE_MESSAGE", comment: "Default share message for I'm safe button")], applicationActivities: nil)
        
        // Show it        
        self.present(controller, animated: true, completion: nil)
        
        // Is method supported? (iOS 8)        
        if controller.responds(to: #selector(getter: UIViewController.popoverPresentationController)) {
            // iOS 8 and up            
            if #available(iOS 8.0, *) {
                // Unwrap variable                
                if let presentationController = controller.popoverPresentationController {
                    // Must set sourceView to prevent crash                    
                    presentationController.sourceView = view
                }
            }
        }
    }
    
    func addPullToRefresh() {
        // Set selector function to reload alerts        
        pullToRefresh.addTarget(self, action: #selector(AlertTableViewController.reloadRecentAlerts), for: UIControlEvents.valueChanged)
        
        // Unwrap variable        
        if let tableView = tableView {
            // Add control to tableView            
            tableView.addSubview(pullToRefresh)
        }
    }
    
    func startReloadTimer() {
        // Simply start the timer every X seconds        
        Timer.scheduledTimer(timeInterval: Config.recentAlertsRefreshIntervalSeconds, target: self, selector: #selector(AlertTableViewController.reloadRecentAlerts), userInfo: nil, repeats: true)
    }
    
    @objc func reloadRecentAlerts() {
        // Prevent concurrent reload        
        if (self.reloading) {
            return
        }
        
        // Set reloading flag        
        self.reloading = true
        
        // Show spinner        
        self.toggleNetworkActivity(visible: true)
        
        // Get recent alerts async        
        RedAlertAPI.getRecentAlerts(callback: {err, alerts -> Void
            in
            // No longer reloading            
            self.reloading = false
            
            // Did we get an error?            
            if let theErr = err {
                // Hide loading indicator                
                self.toggleNetworkActivity(visible: false)
                
                // Default message
                var message = NSLocalizedString("RECENT_ALERTS_ERROR", comment: "Recent alerts error")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
            
            // Store grouped alerts in member
            self.alerts = self.groupAlerts(alerts!)
            
            // Refresh table with data            
            self.refreshAlertsTable()
            
            // Hide loading indicator            
            self.toggleNetworkActivity(visible: false)
        })
    }
    
    func groupAlerts(_ alerts: [Alert]) -> [Alert] {
        // Prepare grouped alerts list
        var groupedAlerts = [Alert]()

        // Keep track of the last alert item added to the list
        var lastAlert: Alert?

        // Traverse elements
        for i in 0..<alerts.count {
            // Current element
            let currentAlert = alerts[i]
            
            // Initialize city names list for map display
            currentAlert.groupedCities.append(currentAlert.city)
            
            // If current alert desc is not empty, add it to grouped desc list
            if (!currentAlert.localizedZoneWithCountdown.isEmpty) {
                currentAlert.groupedDescriptions.append(currentAlert.localizedZoneWithCountdown)
            }
            
            // Add '@' sign to user-selected cities so they are sorted first
            if (shouldBoldCity(city: currentAlert.city)) {
                currentAlert.localizedCity = "@" + currentAlert.localizedCity;
            }

            // Add current localized city name to grouped cities list
            currentAlert.groupedLocalizedCities.append(currentAlert.localizedCity)
            
            // Check whether this new alert can be grouped with the previous one
            // (Same region + 15 second cutoff threshold in either direction)
            if let previousAlert = lastAlert,
                currentAlert.date >= previousAlert.date - 15,
                currentAlert.date <= previousAlert.date + 15 {
                // Group with the previous alert list item
                previousAlert.groupedLocalizedCities.append(currentAlert.localizedCity)
                
                // Add current alert zone if new
                if !previousAlert.localizedZoneWithCountdown.contains(currentAlert.localizedZone) {
                    // Support for unknown city (no prefixing with comma)
                    if previousAlert.localizedZoneWithCountdown.isEmpty && !currentAlert.localizedZoneWithCountdown.isEmpty {
                        // Occupy previous alert's zone with current alert zone
                        previousAlert.localizedZoneWithCountdown = currentAlert.localizedZoneWithCountdown
                        previousAlert.groupedDescriptions.append(currentAlert.localizedZoneWithCountdown)
                    }
                    else if currentAlert.localizedZoneWithCountdown.isEmpty {
                        // Do nothing
                    }
                    else {
                        // Comma-separated zones and countdowns
                        previousAlert.localizedZoneWithCountdown += ", " + currentAlert.localizedZoneWithCountdown
                        previousAlert.groupedDescriptions.append(currentAlert.localizedZoneWithCountdown)
                    }
                }
                
                previousAlert.groupedCities.append(currentAlert.city)
            } else {
                // New alert (not grouped with the previous item)
                groupedAlerts.append(currentAlert)
                lastAlert = currentAlert
            }
        }
        
        // Sort all grouped alerts
        for alert in groupedAlerts {
            // Sort city & zone names alphabetically
            alert.groupedDescriptions = alert.groupedDescriptions.sorted { $0 < $1 }
            alert.groupedLocalizedCities = alert.groupedLocalizedCities.sorted { $0 < $1 }

            // Join arrays into CSV strings
            alert.localizedCity = alert.groupedLocalizedCities.joined(separator: ", ")
            alert.localizedZoneWithCountdown = alert.groupedDescriptions.joined(separator: ", ")
            
            // Remove @ signs
            alert.localizedCity = alert.localizedCity.replacingOccurrences(of: "@", with: "")
        }

        // All done
        return groupedAlerts
    }
    
    func refreshAlertsTable() {
        // Do we have any alerts?        
        if (self.alerts.count > 0) {
            // Hide default view            
            self.toggleDefaultView(visible: false)
            
            // Unwrap variable            
            if let tableView = self.tableView {
                // Save current scroll position
                self.currentScrollPos = self.tableView.contentOffset.y

                // Reload table view data
                tableView.reloadData()
                
                // Don't animate cell redrawing
                UIView.performWithoutAnimation {
                    // Start updating
                    tableView.beginUpdates()
                    
                    // Done updating table
                    tableView.endUpdates()
                }
                
                // No longer lock the table at same scroll position
                self.currentScrollPos = nil
            }
        }
        else {
            // Show default view            
            self.toggleDefaultView(visible: true)
        }
    }
    
    func toggleDefaultView(visible: Bool) {
        // Trying to show it?        
        if (visible) {
            // Show default screen            
            tableView.tableHeaderView = noAlerts
        }
        else {
            // Hide header view            
            tableView.tableHeaderView = nil
        }
    }
    
    func toggleNetworkActivity(visible: Bool) {
        // Toggle iOS status bar network activity indicator
        UIApplication.shared.isNetworkActivityIndicatorVisible = visible
        
        // Pulled to refresh?
        if pullToRefresh.isRefreshing && !visible {
            // Hide loading indicator
            pullToRefresh.endRefreshing()
        }
    }
    
    // Out-of-memory    
    override func didReceiveMemoryWarning() {
        // Call super function        
        super.didReceiveMemoryWarning()
    }
    
    // Table sections count    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // We don't need to split up the rows into sections        
        return 1
    }
    
    // Table row count    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Let iOS know how many rows we want to display        
        return alerts.count
    }
    
    func shouldBoldCity(city: String) -> Bool {
        // Get selected cities, zones, and secondary cities
        let cities = UserSettings.getStringArray(key: UserSettingsKeys.citySelection)
        let zones = UserSettings.getStringArray(key: UserSettingsKeys.zoneSelection)
        let secondaryCities = UserSettings.getStringArray(key: UserSettingsKeys.secondaryCitySelection)
        
        // City selected primarily?
        if cities.contains(city) {
            return true
        }
        
        // City selected secondarily?
        if secondaryCities.contains(city) {
            return true
        }
        
        // Get zone for city
        let zone = LocationMetadata.getZoneByCity(cityName: city)
        
        // Zone of city selected?
        if zones.contains(zone) {
            return true
        }
        
        // No match
        return false
    }
    
    // Table cell display    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create generic cell        
        var cell = AlertTableViewCell()
        
        // Get re-usable cell for better scrolling performance        
        cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! AlertTableViewCell
        
        // Invalid index?
        if (indexPath.row >= alerts.count) {
            return cell
        }
        
        // Get alert by index        
        let alert = alerts[indexPath.row]
        
        cell.desc.text = alert.localizedZoneWithCountdown
        cell.time.text = alert.localizedThreat + " • " + DateFormatterStruct.ConvertUnixTimestampToDateTime(unixTimestamp: alert.date)
        
        // Fix for really annoying bug with UILabel multiline height
        cell.city.preferredMaxLayoutWidth = 0
        
        // Disable truncation for zone names & countdown list
        cell.desc.preferredMaxLayoutWidth = 0
        
        // No cities? Protect against UI failure
        if (alert.localizedZoneWithCountdown == "") {
            cell.desc.text = " "
        }
        
        // RTL cities in case device language is Hebrew        
        if (Localization.isRTL()) {
            // Set text alignment to RTL            
            cell.city.textAlignment = NSTextAlignment.right
            cell.desc.textAlignment = NSTextAlignment.right
            cell.time.textAlignment = NSTextAlignment.right
            
            // Increase font size in case device language is Hebrew
            cell.desc.font = cell.desc.font.withSize(16)
            cell.time.font = cell.time.font.withSize(14)
            
            // Reduce font letter spacing
            cell.desc.attributedText = NSAttributedString(string: cell.desc.text!, attributes: [.kern: -0.3])
            cell.time.attributedText = NSAttributedString(string: cell.time.text!, attributes: [.kern: -0.3])
        }
        
        // Default letter spacing & size for city text
        var letterSpacing = 0.0, cityFontSize = 18;
        
        // Hebrew?
        if (Localization.isRTL()) {
            // Less letter spacing
            letterSpacing = -0.3;
            
            // Larger font
            cityFontSize = 20;
        }
        
        // Create an attributed string (reduce font letter spacing using .kern)
        let attributedString = NSMutableAttributedString(string: alert.localizedCity, attributes: [.font:  UIFont(name: "Arial", size: CGFloat(cityFontSize)) ?? UIFont.systemFont(ofSize: CGFloat(cityFontSize)), .kern: letterSpacing])

        // Traverse all grouped cities in alert
        for city in alert.groupedCities {
            // City / zone selected?
            if shouldBoldCity(city: city) {
                // Get localized city name
                let localizedCity = LocationMetadata.getLocalizedCityName(cityName: city)
                
                // Find the range of localized city to replace with bold font
                if let boldRange = alert.localizedCity.range(of: localizedCity) {
                    // Apply bold font to the specified range
                    attributedString.addAttribute(.font, value: UIFont(name: "Arial-BoldMT", size: CGFloat(cityFontSize)) ?? UIFont.boldSystemFont(ofSize: CGFloat(cityFontSize)), range: NSRange(boldRange, in: alert.localizedCity))
                }
            }
        }
        
        // Set city as attributed text for bold styling to work
        cell.city.attributedText = attributedString
        
        // Update image based on threat type
        cell.threatImage.image = getThreatImage(alert.threat)
        
        // Return configured cell        
        return cell
    }
    
    func getThreatImage(_ threat: String) -> UIImage? {
        // Null fallback
        if threat.isEmpty {
            return UIImage(named: "AlertIcon")
        }

        // Return drawable resource by threat type
        if threat.contains("radiologicalEvent") {
            return UIImage(named: "RadiologicalEventIcon")
        }
        else if threat.contains("hostileAircraftIntrusion") {
            return UIImage(named: "HostileAircraftIntrusionIcon")
        }
        else if threat.contains("hazardousMaterials") {
            return UIImage(named: "HazardousMaterialsIcon")
        }
        else if threat.contains("tsunami") {
            return UIImage(named: "TsunamiIcon")
        }
        else if threat.contains("missiles") {
            return UIImage(named: "AlertIcon")
        }
        else if threat.contains("terroristInfilitration") {
            return UIImage(named: "TerroristInfilitrationIcon")
        }
        else if threat.contains("earthQuake") {
            return UIImage(named: "EarthquakeIcon")
        }
        else {
            // Unknown type
            return UIImage(named: "AlertIcon")
        }
    }
}

// Extension for CGRect (removed in Swift 3)
extension CGRect{
    init(_ x:CGFloat,_ y:CGFloat,_ width:CGFloat,_ height:CGFloat) {
        self.init(x:x,y:y,width:width,height:height)
    }
}

// Extension for CGSize (removed in Swift 3)
extension CGSize{
    init(_ width:CGFloat,_ height:CGFloat) {
        self.init(width:width,height:height)
    }
}

// Extension for CGPoint (removed in Swift 3)
extension CGPoint{
    init(_ x:CGFloat,_ y:CGFloat) {
        self.init(x:x,y:y)
    }
}
