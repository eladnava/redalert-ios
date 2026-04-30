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
    var reloading = false, imSafe = UIView(), noAlerts = UIView(), pullToRefresh = UIRefreshControl(), alerts: [Alert] = [], allAlerts: [Alert] = [], reloadTimer: Timer?
    var dismissAlertsButton = UIButton(type: .system)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Do we have any alerts being displayed?
        if (self.alerts.count > 0) {
            // Refresh display of alerts to update bold styling in case selected cities/zones changed
            self.refreshAlertsTable()
        }
        
        // Keep dismiss/restore icon in sync when returning to this screen
        self.updateDismissAlertsButtonIcon()
        
        // Create timer to refresh recent alerts list
        self.startReloadTimer()
        
        // Reload recent alerts (Timer does not tick when initialized)
        self.reloadRecentAlerts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop the timer
        reloadTimer?.invalidate()
        reloadTimer = nil
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
        
        // Create new Live Map button
        let button = UIButton(type: .system)
        
        // Set image & click handler
        button.setImage(UIImage(named: "MapIcon"), for: .normal)
        button.addTarget(self, action:#selector(AlertTableViewController.openLiveMap), for: .touchUpInside)
        
        // Fix image stretching on iOS 26 and up
        if #available(iOS 26.0, *) {
            // Keep icon aspect ratio to avoid stretching wide
            button.imageView?.contentMode = .scaleAspectFit
            
            // Center icon inside button bounds
            button.contentHorizontalAlignment = .center
            
            // Center icon vertically inside button bounds
            button.contentVerticalAlignment = .center
            
            // Add inner padding so non-square assets are not edge-stretched
            button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }

        // Set width & height of button
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 35)
        ])
        
        // Add dismiss/restore icon button on the right side
        dismissAlertsButton.addTarget(self, action: #selector(AlertTableViewController.dismissAlertsTapped), for: .touchUpInside)
        
        // Fix image stretching on iOS 26 and up
        if #available(iOS 26.0, *) {
            // Keep icon aspect ratio to avoid stretching wide
            dismissAlertsButton.imageView?.contentMode = .scaleAspectFit
            
            // Center icon inside button bounds
            dismissAlertsButton.contentHorizontalAlignment = .center
            
            // Center icon vertically inside button bounds
            dismissAlertsButton.contentVerticalAlignment = .center
            
            // Add inner padding so non-square assets are not edge-stretched
            dismissAlertsButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }

        // Set width & height of button
        NSLayoutConstraint.activate([
            dismissAlertsButton.widthAnchor.constraint(equalToConstant: 25),
            dismissAlertsButton.heightAnchor.constraint(equalToConstant: 25)
        ])
        
        // Shift map & dismiss buttons closer to the screen edge
        var shiftPx: CGFloat = 7;
        
        // Non-RTL language?
        if (!Localization.isRTL()) {
            // Shift the other way
            shiftPx *= -1
        }
        
        // No shifting on iOS 26 and up
        if #available(iOS 26.0, *) {
            shiftPx = 0;
        }
        
        // Shift map button closer to the screen edge
        button.transform = CGAffineTransform(translationX: shiftPx, y: 0)
        dismissAlertsButton.transform = CGAffineTransform(translationX: shiftPx, y: 0)
        
        // Place dismiss/restore next to live map on the left action buttons
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: button), UIBarButtonItem(customView: dismissAlertsButton)]
        
        // Keep dismiss/restore icon in sync when returning to this screen
        self.updateDismissAlertsButtonIcon()
        
        // Hide the empty separators before content loads        
        self.hideEmptyCellSeparators()
        
        // Programatic pull to refresh        
        self.initialPullToRefresh()
        
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
    
    @objc func openLiveMap() {
        // Crete and push the new view controller
        self.navigationController?.pushViewController(LiveMapViewController(), animated: true)
    }
    
    @objc func openSettings() {
        // Crete and push the new view controller
        self.navigationController?.pushViewController(self.storyboard!.instantiateViewController(withIdentifier: "Settings") as UIViewController, animated: true)
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

    @objc func dismissAlertsTapped() {
        // Read the current dismiss cutoff timestamp from user defaults
        let ts = UserDefaults.standard.object(forKey: UserSettingsKeys.dismissAlertsTimestamp) as? Double

        // If a cutoff exists, alerts are currently dismissed and this tap means restore
        if ts != nil {
            // Remove the dismiss cutoff to restore all alerts in the list
            UserDefaults.standard.removeObject(forKey: UserSettingsKeys.dismissAlertsTimestamp)
            
            // Switch the button image to the dismiss icon
            self.updateDismissAlertsButtonIcon()
            
            // Re-apply filtering immediately to refresh visible rows
            self.refreshAlertsTable()
            
            // Exit early because restore flow is complete
            return
        }

        // Create a confirmation dialog before applying dismiss cutoff
        let alert = UIAlertController(title: NSLocalizedString("DISMISS_ALERTS_CONFIRM_TITLE", comment: "Dismiss alerts title"), message: NSLocalizedString("DISMISS_ALERTS_CONFIRM_MESSAGE", comment: "Dismiss alerts message"), preferredStyle: .alert)
        
        // Add a cancel action so users can abort dismissing alerts
        alert.addAction(UIAlertAction(title: NSLocalizedString("CANCEL_BUTTON", comment: "Cancel"), style: .cancel, handler: nil))
        
        // Add a confirm action that applies the dismiss cutoff
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK_BUTTON", comment: "OK"), style: .destructive, handler: { _ in
            // Capture the current Unix timestamp as the new dismiss cutoff
            let now = Date().timeIntervalSince1970
            
            // Persist the cutoff so older alerts are hidden
            UserDefaults.standard.set(now, forKey: UserSettingsKeys.dismissAlertsTimestamp)
            
            // Switch the button image to the restore icon
            self.updateDismissAlertsButtonIcon()
            
            // Re-filter the in-memory list for an instant UI update
            self.refreshAlertsTable()
        }))

        // Present the confirmation dialog to the user
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateDismissAlertsButtonIcon() {
        // Read the current dismiss cutoff timestamp from user defaults
        let ts = UserDefaults.standard.object(forKey: UserSettingsKeys.dismissAlertsTimestamp) as? Double
        
        // Choose the clear icon when alerts are active, or restore icon when dismissed
        let imageName = ts == nil ? "ClearIcon" : "RestoreIcon"
        
        // Apply the selected image to the dismiss/restore button
        dismissAlertsButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    func startReloadTimer() {
        // Invalidate existing timer just in case
        reloadTimer?.invalidate()
        
        // Simply start the timer every X seconds
        reloadTimer = Timer.scheduledTimer(timeInterval: Config.recentAlertsRefreshIntervalSeconds, target: self, selector: #selector(AlertTableViewController.reloadRecentAlerts), userInfo: nil, repeats: true)
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
            
            // Store grouped alerts in member (unfiltered)
            var alerts = self.groupAlerts(alerts!)

            // Preserve expanded state where possible based on previous full alerts list
            if alerts.count == self.allAlerts.count {
                // Loop over old alerts
                for i in 0..<self.allAlerts.count {
                    let alert = self.allAlerts[i]

                    // User tapped to expand?
                    if alert.isExpanded {
                        // Safeguard: check if new alert at same position has the same date
                        if self.allAlerts[i].date == alerts[i].date {
                            // Preserve expanded state after refresh
                            alerts[i].isExpanded = true
                        }
                    }
                }
            }
            
            // Overwrite full alerts list (unfiltered)
            self.allAlerts = alerts
            
            // Invoke callback on main thread
            DispatchQueue.main.async {
                // Refresh table with data (will apply dismiss/restore filter)
                self.refreshAlertsTable()
                
                // Hide loading indicator
                self.toggleNetworkActivity(visible: false)
            }
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
            if (!currentAlert.localizedZone.isEmpty) {
                currentAlert.groupedDescriptions.append(currentAlert.localizedZone)
            }
            
            // Add '@' sign to user-selected cities so they are sorted first
            if (shouldBoldCity(city: currentAlert.city)) {
                currentAlert.localizedCity = "@" + currentAlert.localizedCity
            }

            // Add current localized city name to grouped cities list
            currentAlert.groupedLocalizedCities.append(currentAlert.localizedCity)
            
            // Alert grouping date cutoff threshold (seconds)
            let dateGroupingThreshold: Double = 3 * 60
            
            // Check whether this new alert can be grouped with the previous one
            // (Same threat + same region + 3 minute cutoff threshold in either direction)
            if let previousAlert = lastAlert,
                currentAlert.localizedThreat == previousAlert.localizedThreat,
                currentAlert.date >= previousAlert.date - dateGroupingThreshold,
                currentAlert.date <= previousAlert.date + dateGroupingThreshold {
                // Skip duplicate alerts for same city name
                if (previousAlert.groupedLocalizedCities.contains(currentAlert.localizedCity)) {
                    continue
                }
                
                // Group with the previous alert list item
                previousAlert.groupedLocalizedCities.append(currentAlert.localizedCity)
                
                // Add current alert zone if new
                if !previousAlert.localizedZone.contains(currentAlert.localizedZone) {
                    // Support for unknown city (no prefixing with comma)
                    if previousAlert.localizedZone.isEmpty && !currentAlert.localizedZone.isEmpty {
                        // Occupy previous alert's zone with current alert zone
                        previousAlert.localizedZone = currentAlert.localizedZone
                        previousAlert.groupedDescriptions.append(currentAlert.localizedZone)
                    }
                    else if currentAlert.localizedZone.isEmpty {
                        // Do nothing
                    }
                    else {
                        // Comma-separated zones and countdowns
                        previousAlert.localizedZone += ", " + currentAlert.localizedZone
                        previousAlert.groupedDescriptions.append(currentAlert.localizedZone)
                    }
                }
                
                previousAlert.groupedCities.append(currentAlert.city)
                
                // Update date range
                previousAlert.minDate = min(previousAlert.minDate, currentAlert.date)
                previousAlert.maxDate = max(previousAlert.maxDate, currentAlert.date)
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
            alert.localizedZone = alert.groupedDescriptions.joined(separator: ", ")
            
            // Remove @ signs
            alert.localizedCity = alert.localizedCity.replacingOccurrences(of: "@", with: "")
        }

        // All done
        return groupedAlerts
    }
    
    func refreshAlertsTable() {
        // Table not in view hierarchy yet?
        guard tableView.window != nil else {
            // Defer refresh
            return
        }

        // Start from full alerts list
        var alertsToDisplay = self.allAlerts

        // Filter by dismissed timestamp if set
        let ts = UserDefaults.standard.object(forKey: UserSettingsKeys.dismissAlertsTimestamp) as? Double
        
        // Dismiss cutoff exists? Filter out older alerts that should be hidden
        if let cutoff = ts {
            alertsToDisplay = alertsToDisplay.filter { $0.date > cutoff }
        }

        // Update current alerts used by table view
        self.alerts = alertsToDisplay
        
        // Do we have any alerts?
        if (self.alerts.count > 0) {
            // Hide default view            
            self.toggleDefaultView(visible: false)
            
            // Unwrap variable            
            if let tableView = self.tableView {
                let previousOffset = tableView.contentOffset
                let previousContentHeight = tableView.contentSize.height
                
                // Don't animate cell redrawing
                UIView.performWithoutAnimation {
                    // Reload table view data
                    tableView.reloadData()
                }
                
                // Maintain scrollbar position
                if (previousContentHeight > 0) {
                    let newContentHeight = tableView.contentSize.height
                    let offsetAdjustment = newContentHeight - previousContentHeight
                    tableView.contentOffset = CGPoint(
                        x: previousOffset.x,
                        y: max(0, previousOffset.y + offsetAdjustment)
                    )
                }
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
        // Run code on UI thread
        DispatchQueue.main.async(execute: {
            // Toggle iOS status bar network activity indicator
            UIApplication.shared.isNetworkActivityIndicatorVisible = visible
            
            // Pulled to refresh?
            if self.pullToRefresh.isRefreshing && !visible {
                // Hide loading indicator
                self.pullToRefresh.endRefreshing()
            }
        })
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
        
        // Mutuate localized city string
        var title: String
        
        // If at least 15 cities, display alert city count with threat name
        if (alert.groupedCities.count >= 15) {
            // Format city count for current app language
            let cityCountText = self.localizedCityCountText(count: alert.groupedCities.count)
            
            // Prefix with {threat} • {count} Cities
            title = alert.localizedThreat + " • " + cityCountText + " " + NSLocalizedString("CITIES", comment: "Cities")
        }
        else {
            // Prefix with {threat} • {count} Cities
            title = alert.localizedThreat
        }
        
        // Display title
        cell.title.text = title
        
        // Max 3 lines for cities
        cell.cities.numberOfLines = 3
        
        // Prepare time text
        if alert.groupedCities.count > 1 && alert.minDate != alert.maxDate {
            cell.time.text = DateFormatterStruct.ConvertUnixTimestampRangeToDateTime(minTimestamp: alert.minDate, maxTimestamp: alert.maxDate)
        } else {
            cell.time.text = DateFormatterStruct.ConvertUnixTimestampToDateTime(unixTimestamp: alert.date)
        }
        
        // Capitalize first letter only
        cell.time.text = cell.time.text?.capitalizeFirstWordOnly()
        
        // Zones label
        cell.zones.text = alert.localizedZone
        
        // Fix for really annoying bug with UILabel multiline height
        cell.cities.preferredMaxLayoutWidth = 0
        
        // RTL cities in case device language is Hebrew        
        if (Localization.isRTL()) {
            // Set text alignment to RTL            
            cell.title.textAlignment = NSTextAlignment.right
            cell.time.textAlignment = NSTextAlignment.right
            cell.cities.textAlignment = NSTextAlignment.right
            cell.zones.textAlignment = NSTextAlignment.right

            // Increase font size in case device language is Hebrew
            cell.title.font = cell.title.font.withSize(19)
            cell.zones.font = cell.zones.font.withSize(14)
            
            // Reduce font letter spacing
            cell.title.attributedText = NSAttributedString(string: cell.title.text!, attributes: [.kern: -0.3])
            cell.time.attributedText = NSAttributedString(string: cell.time.text!, attributes: [.kern: -0.3])
            cell.cities.attributedText = NSAttributedString(string: cell.cities.text!, attributes: [.kern: -0.3])
        }
        
        
        // Alert already expanded?
        if alert.isExpanded {
            // Unlimited lines
            cell.cities.numberOfLines = 0
        }
        
        // Set ellipsis / truncation
        cell.cities.lineBreakMode = .byTruncatingTail
        
        // Capture click event
        cell.cities.isUserInteractionEnabled = true
        
        // Remove previous gesture recognizers to avoid duplicates
        cell.cities.gestureRecognizers?.forEach { cell.cities.removeGestureRecognizer($0) }

        // Add tap event on UILabel
        cell.cities.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cityLabelTapped(_:))))

        // Tag the label with the indexPath.row so we know which alert it belongs to
        cell.cities.tag = indexPath.row
        
        // Default letter spacing & size for city text
        var letterSpacing = 0.0, cityFontSize = 18
        
        // Hebrew?
        if (Localization.isRTL()) {
            // Less letter spacing
            letterSpacing = -0.5
            
            // Larger font
            cityFontSize = 20
        }
        
        // Create an attributed string (reduce font letter spacing using .kern)
        let attributedString = NSMutableAttributedString(string: alert.localizedCity, attributes: [.font:  UIFont(name: "Arial", size: CGFloat(cityFontSize)) ?? UIFont.systemFont(ofSize: CGFloat(cityFontSize)), .kern: letterSpacing])

        // Traverse all grouped cities in alert
        for city in alert.groupedCities {
            // City / zone selected?
            if shouldBoldCity(city: city) {
                // Get localized city name
                let localizedCityName = LocationMetadata.getLocalizedCityName(cityName: city)
                
                // Find the range of localized city to replace with bold font
                if let boldRange = alert.localizedCity.range(of: localizedCityName) {
                    // Apply bold font to the specified range
                    attributedString.addAttributes([.font: UIFont(name: "Arial-BoldMT", size: CGFloat(cityFontSize)) ?? UIFont.boldSystemFont(ofSize: CGFloat(cityFontSize)), .kern: letterSpacing], range: NSRange(boldRange, in: alert.localizedCity))
                }
            }
        }
        
        // Set city as attributed text for bold styling to work
        cell.cities.attributedText = attributedString
        
        // Update image based on threat type
        cell.threatImage.image = getThreatImage(alert.threat)
        
        // Return configured cell        
        return cell
    }
    
    @objc func cityLabelTapped(_ sender: UITapGestureRecognizer) {
        // Get UILabel that was tapped
        guard let label = sender.view as? UILabel else { return }
        
        // Get row number
        let row = label.tag
        let alert = alerts[row]
                
        // Alert doesn't need expansion?
        if (!alert.isExpanded && !label.isEllipsized) {
            // Get superview
            var view = label.superview
            
            // Find UITableViewCell
            while view != nil && !(view is UITableViewCell) {
                view = view?.superview
            }

            // Ensure we have a cell
            guard let cell = view as? UITableViewCell else { return }

            // Ask the table for the index path of this cell
            guard let indexPath = tableView.indexPath(for: cell) else { return }

            // Select row
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)

            // Open map (alert view)
            self.performSegue(withIdentifier: "AlertViewSegue", sender: alert)

            // Stop execution (no need to toggle expansion)
            return
        }
        
        // Toggle expansion
        alert.isExpanded.toggle()
        
        // Animate height change
        tableView.beginUpdates()
        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        tableView.endUpdates()
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
        else if threat.contains("terroristInfiltration") {
            return UIImage(named: "TerroristInfiltrationIcon")
        }
        else if threat.contains("earthQuake") {
            return UIImage(named: "EarthquakeIcon")
        }
        else if threat.contains("leaveShelter") {
            return UIImage(named: "LeaveShelterIcon")
        }
        else if threat.contains("earlyWarning") {
            return UIImage(named: "EarlyWarningIcon")
        }
        else {
            // Unknown type
            return UIImage(named: "AlertIcon")
        }
    }
    
    func localizedCityCountText(count: Int) -> String {
        // Arabic active? use Arabic-Indic digits
        if Localization.shouldLocalizeToArabic() {
            // Convert count to plain text first
            let rawText = String(count)
            
            // Map ASCII digits to Arabic-Indic digits deterministically
            let mapped = rawText.map { char -> Character in
                switch char {
                case "0": return "٠"
                case "1": return "١"
                case "2": return "٢"
                case "3": return "٣"
                case "4": return "٤"
                case "5": return "٥"
                case "6": return "٦"
                case "7": return "٧"
                case "8": return "٨"
                case "9": return "٩"
                default: return char
                }
            }
            
            // Return localized city count text
            return String(mapped)
        }
        
        // Non-Arabic languages keep standard formatting
        return String(count)
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

extension String {
    func capitalizeFirstWordOnly() -> String {
        return prefix(1).uppercased() + dropFirst().lowercased()
    }
}

extension UILabel {
    var isEllipsized: Bool {
        // Get attributed text
        guard let attributedText = self.attributedText else { return false }
        
        // 1. Create a framesetter with your attributed string
        let framesetter = CTFramesetterCreateWithAttributedString(attributedText)
        
        // 2. Define the constraints (Current width, infinite height)
        let targetSize = CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        
        // 3. Calculate the actual size required
        let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attributedText.length),
            nil,
            targetSize,
            nil
        )
        
        // 4. Compare required height vs actual label height
        // We use a small tolerance (1.0) for rounding
        return ceil(fitSize.height) > ceil(self.bounds.height) + 1.0
    }
}
