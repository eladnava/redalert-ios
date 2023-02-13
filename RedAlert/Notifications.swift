//
//  Notifications.swift
//  RedAlert
//
//  Created by Elad on 10/28/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox.AudioServices

struct Notifications {
    static var audioPlayer: AVAudioPlayer?
    
    static func inAppPushNotification(notification: [AnyHashable : Any]) {
        // Use deprecated inAppPushNotification library on < iOS 10
        if #available(iOS 10, *) {
            // Stop audio playing (iOS 10+)
            Notifications.stopSound()
        } else {
            // Show banner (old method)
            self.showInAppBanner(notification: notification)
        
            // Play sound
            self.playSoundAndVibrate(notification: notification)
        }
    }
    
    static func stopSound() {
        // Unwrap safely        
        if let audioPlayer = audioPlayer {
            // Stop sound            
            audioPlayer.stop()
        }
    }
    
    static func playSoundAndVibrate(notification: [AnyHashable : Any]) {
        // Get APS object        
        let aps = notification["aps"] as! NSDictionary
        
        // Sound filename
        var fileName:String;
        
        // Sound was sent as a string?
        if let file = aps["sound"] as? String {
            fileName = file
        }
        // Sound was sent as a dictionary (Critical alert)?
        else if let sound = aps["sound"] as? NSDictionary {
            fileName = sound["name"] as! String
        }
        else {
            // No sound provided, do nothing
            return
        }
        
        // Remove sound extension
        fileName = fileName.replacingOccurrences(of: ".aifc", with: "")
        
        // Try to determine path
        let path = Bundle.main.path(forResource: fileName, ofType: "aifc")
        
        // Unwrap variable safely
        if let path = path {
            // Create path to sound
            let alertSound = URL(fileURLWithPath: path)
            
            // Create a new instance of audio player
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: alertSound)
                
                // Burst through silent mode
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            }
            catch {
                // Show error
                Dialogs.error(message: NSLocalizedString("SOUND_ERROR", comment: "Sound error message"))
            }
            
            // Unwrap variable
            if let audioPlayer = audioPlayer {
                // Play the sound
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                
                // Vibrate shortly
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }

    static func showInAppBanner(notification: [AnyHashable : Any]) {
        // Get app title        
        let title = NSLocalizedString("APP_NAME", comment: "Name of app")
        
        // Get APS object        
        let aps = notification["aps"] as! NSDictionary
        
        // Get actual push message        
        let alert = aps["alert"] as! String
        
        // Set library to use iOS7 style in-app notification        
        JCNotificationCenter.shared().presenter = JCNotificationBannerPresenterIOS7Style()
        
        // Show the notification        
        JCNotificationCenter.enqueueNotification(withTitle: title, message: alert, tapHandler: { () -> Void in
            
            // Stop the notification sound            
            self.stopSound()
        })
    }
}
