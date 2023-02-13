//
//  RecentAlertsTableViewController.swift
//  RedAlert
//
//  Created by Elad on 10/14/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import UIKit
import AVFoundation

class SoundSelectionViewController: UITableViewController {
    // Initialize class variables    
    var audioPlayer: AVAudioPlayer?, key: String = "", selection: String = "", items: [SoundItem] = []
    
    // Init function    
    func setup(key: String, title: String, items: [SoundItem], defaultValue: String) {
        // Save selector key        
        self.key = key
        
        // Save view title        
        self.title = title
        
        // Save reference to items        
        self.items = items
        
        // Get stored value        
        self.selection = UserSettings.getString(key: key, defaultValue: defaultValue)
        
        // Find selected item and check it            
        for item in items as [SoundItem] {
            // Same item?            
            if (item.value == selection) {
                // Mark as selected                    
                item.selected = true
            }
        }
        
        // Set navigation buttons        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(SoundSelectionViewController.doneTapped(sender:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.undo, target: self, action: #selector(SoundSelectionViewController.cancelTapped(sender:)))
        
        // Set bar button appearance        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18), NSAttributedStringKey.foregroundColor: UIColor.red ], for: UIControlState.normal)
    }
    
    func stopAudioPlayer() {
        // Did it initialize?        
        if let player = self.audioPlayer {
            // Is it playing?            
            if (player.isPlaying) {
                // Stop playing the sound                
                player.stop()
            }
        }
    }
    
    @objc func cancelTapped(sender: UIBarButtonItem) {
        // Stop playing sounds        
        stopAudioPlayer()

        // Selection cancelled, go back to settings        
        self.navigationController!.popViewController(animated: true)
    }
    
    @objc func doneTapped(sender: UIBarButtonItem) {
        // Stop playing sounds        
        stopAudioPlayer()
        
        // Show loading dialog        
        MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        
        // Prepare primary and secondary sounds        
        var primary = "", secondary = ""
        
        // Set new value depending on key        
        if (self.key == UserSettingsKeys.soundSelection) {
            primary = self.selection
        }
        if (self.key == UserSettingsKeys.secondarySoundSelection) {
            secondary = self.selection
        }
        
        // Save sounds serverside        
        RedAlertAPI.updateSoundsAsync(primary: primary, secondary: secondary) { (err: NSError?) -> () in
            
            // Hide loading dialog            
            MBProgressHUD.hide(for: self.navigationController!.view, animated: true)
            
            // JSON parse error?
            if let theErr = err {
                // Default message
                var message = NSLocalizedString("SOUND_SAVE_ERROR", comment: "Error saving sound")
                
                // Error provided?
                if let errMsg = theErr.userInfo["error"] as? String {
                    message += "\n\n" + errMsg
                }
                
                // Show the error
                return Dialogs.error(message: message)
            }
            
            // Save selected value in user defaults by key            
            UserDefaults.standard.set(self.selection, forKey: self.key)
            
            // Go back to settings            
            self.navigationController!.popViewController(animated: true)
        }
    }
    
    // View loaded initially (called once)    
    override func viewDidLoad() {
        // Call super function        
        super.viewDidLoad()
        
        // Register reusable ID  for faster scrolling        
        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "Cell")
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
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Remove gray cell background        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get SoundItem by index        
        let sound = items[indexPath.row]
        
        // Traverse the sounds        
        for i in (0..<items.count) {
            // Get item by index            
            let item = items[i]
            
            // Is it selected?            
            if (item.selected) {
                // No longer selected                
                item.selected = false
                
                // Calculate its indexPath                
                let itemIndexPath = IndexPath(row: i, section: 0)
                
                // Display sound as unchecked                
                tableView.cellForRow(at: itemIndexPath)?.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        // Set clicked sound as selected        
        sound.selected = true
        
        // Update selected value        
        self.selection = sound.value
        
        // Display sound as checked            
        tableView.cellForRow(at: indexPath)?.accessoryType = UITableViewCellAccessoryType.checkmark
        
        // Generate path to sound file        
        self.playSound(file: sound.value)
    }
    
    func playSound(file: String) {
        // Remove sound extension        
        let file = file.replacingOccurrences(of: ".aifc", with: "")
        
        // Get path to sound        
        let path = Bundle.main.path(forResource: file, ofType: "aifc")
        
        // Invalid path?        
        if (path == nil) {
            return
        }
        
        // Create URL to path    
        let alertSound = URL(fileURLWithPath: path!)
        
        // Prepare error variable        
        var error: NSError?
        
        do {
            // Create a new instance of audio player        
            audioPlayer = try AVAudioPlayer(contentsOf: alertSound)
            
            // Burst through silent mode
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }
        
        // Generate path to sound file        
        if (error != nil) {
            Dialogs.error(message: NSLocalizedString("SOUND_ERROR", comment: "Sound error message"))
        }
        
        // Unwrap variable        
        if let audioPlayer = audioPlayer {
            // Play the sound            
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        }
    }
    
    // Table cell display    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get re-usable cell for better scrolling performance        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        
        // Row does not exist?        
        if (indexPath.row >= items.count) {
            return cell
        }
        
        // Get sound by index        
        let sound = items[indexPath.row]
        
        // Get alert by index and get its area as string        
        cell.textLabel!.text = NSLocalizedString(sound.title, comment: "Sound title translation")
        
        // Set up checkmark if checked        
        cell.accessoryType = (sound.selected) ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        
        // RTL cities in case device language is Hebrew        
        if (Localization.isRTL()) {
            // Set text alignment to RTL            
            cell.textLabel!.textAlignment = NSTextAlignment.right
        }
        
        // Return configured cell        
        return cell
    }
}
