//
//  HTTP.swift
//  RedAlert
//
//  Created by Elad on 11/1/14.
//  Copyright (c) 2021 Elad Nava. All rights reserved.
//

import Foundation

struct HTTP {
    static func disableSharedCache() {
        // Create empty shared cache        
        let sharedCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        
        // Set it (application-wide)        
        URLCache.shared = sharedCache
    }
    
    static func toggleNetworkActivity(visible: Bool) {
        // Run code on UI thread        
        DispatchQueue.main.async(execute: {
            // Set spinning network indicator visibility        
            UIApplication.shared.isNetworkActivityIndicatorVisible = visible
        })
    }
    
    static func postAsync(urlString : String, params : [String: AnyObject], postCompleted : @escaping (_ err: NSError?, _ json: NSDictionary?) -> ()) {
        // Disable cached requests        
        disableSharedCache()
        
        // Show network activity to user        
        toggleNetworkActivity(visible: true)
        
        // Define alerts API endpoint        
        let url = URL(string: urlString)!
        
        // Create new request        
        let request = NSMutableURLRequest(url: url)
        
        // Create new session handler Run callback on UI        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // This is a POST request        
        request.httpMethod = "POST"
        
        // Serialize request JSON into string        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        catch let err as NSError {
            // Return the error            
            return postCompleted(err, nil)
        }
        
        // Set request and accept content type to JSON        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Execute request async        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void
            in
            // Hide network activity            
            self.toggleNetworkActivity(visible: false)
            
            // Request failed?
            if (data == nil) {
                return postCompleted(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil), nil)
            }
            
            // Get response string (for debugging)            var strData = NSString(data: data!, encoding: NSUTF8StringEncoding) Prepare response JSON dictionary            
            var json: NSDictionary?
            
            do {
                // Serialize request JSON into string                
                json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
            }
            catch let err as NSError {
                // Return the error                
                return postCompleted(err, nil)
            }
            
            // Got a JSON error?            
            if json?["message"] != nil {
                // Return the error                
                return postCompleted(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: ["error": json!["message"]!]), json)
            }
            
            // Return the JSON            
            return postCompleted(nil, json)
        })
        
        // Start running task        
        task.resume()
    }
    
    
    static func getAsync(urlString: String, dictionary: Bool, getCompleted: @escaping (_ err: NSError?, _ json: AnyObject?) -> ()) {
        // Disable cached requests        
        disableSharedCache()
        
        // Define alerts API endpoint        
        let url = URL(string: urlString)!
        
        // Create new request        
        let request = NSMutableURLRequest(url: url)
        
        // Create new session handler Run callback on UI        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // This is a GET request        
        request.httpMethod = "GET"
        
        // We expect to get back JSON        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Execute request async        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void
            in
            // Get response string            let strData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) Prepare response JSON            
            var json: AnyObject?
            
            
            // Request failed?
            if (data == nil) {
                return getCompleted(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil), nil)
            }
            
            do {
                // Serialize request JSON into string                
                if (dictionary) {
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSDictionary
                }
                else {
                    json = try JSONSerialization.jsonObject(with: data!, options: .mutableLeaves) as? NSArray
                }
            }
            catch let err as NSError {
                // Return the error                
                return getCompleted(err, nil)
            }
            
            // Unwrap JSON            
            if let parseJSON = json as? NSDictionary {
                // Got a JSON error?                
                if (parseJSON["message"] != nil) {
                    // Return the error                    
                    return getCompleted(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: ["error": parseJSON["message"]!]), parseJSON)
                }
            }
            
            // Return the JSON            
            return getCompleted(nil, json)
        })
        
        // Start running task        
        task.resume()
    }
}
