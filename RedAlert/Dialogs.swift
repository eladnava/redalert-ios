//
//  Dialogs.swift
//  RedAlert
//
//  Created by Elad on 10/29/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct Dialogs {
    static func error(message: String) {
        // Run code on UI thread        
        DispatchQueue.main.async(execute: {
            // Create new alert view
            let alert = UIAlertView()
            
            // Set title, message
            alert.message = message
            alert.title = NSLocalizedString("ERROR_DIALOG", comment: "Error dialog title")
            
            // Set dismiss button
            alert.addButton(withTitle: NSLocalizedString("OK_BUTTON", comment: "OK dialog button"))
                
            // Show alert view
            alert.show()
        
            // Auto hide after some time
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 7) {
                alert.dismiss(withClickedButtonIndex: 0, animated: true)
            }
        })
    }
    
    static func message(title: String, message: String, delegate: UIAlertViewDelegate) {
        // Run code on UI thread        
        DispatchQueue.main.async(execute: {
                // Create new alert view                
                let alert = UIAlertView()
                
                // Set title, message                
                alert.title = title
                alert.message = message
                alert.delegate = delegate
                
                // Set dismiss button                
                alert.addButton(withTitle: NSLocalizedString("OK_BUTTON", comment: "OK dialog button"))
                
                // Show alert view                
                alert.show()
        })
    }
}
