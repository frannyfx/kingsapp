//
//  Utils.swift
//  KingsApp
//
//  Created by Francesco on 05/11/2018.
//  Copyright © 2018 vx. All rights reserved.
//

import Foundation
class Utils {
    let LATEST_VERSION_URL = "https://versions.scuf.me/kingsapp.txt"
    
    func checkForUpdates(completion: @escaping (Bool)->()) {
        let session = URLSession.shared
        let url = URL(string: LATEST_VERSION_URL)
        
        // Setup the request
        var request = URLRequest(url: url!)
        
        // Add body
        request.httpMethod = "GET"
        let task = session.dataTask(with: request) { data, response, err in
            if err != nil {
                print("Unable to fetch content.")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    if let newVersion = String(data: data!, encoding: .utf8) {
                        // Split new version
                        let newVersionNumbers = newVersion.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
                        
                        // Split current version
                        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                        let currentVersionNumbers = currentVersion.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".")
                        
                        // For loop from 0 to maximum length
                        var updateAvailable = false
                        for i in 0..<(currentVersionNumbers.count > newVersionNumbers.count ? currentVersionNumbers.count : newVersionNumbers.count) {
                            let current = i < currentVersionNumbers.count ? Int(currentVersionNumbers[i]) : nil
                            let new = i < newVersionNumbers.count ? Int(newVersionNumbers[i]) : nil
                            if new == nil || (current != nil && new! < current!) {
                                break;
                            }
                            
                            if current == nil || new! > current! {
                                updateAvailable = true
                                break;
                            }
                        }
                        
                        completion(updateAvailable)
                    }
                case 401:
                    if let dataString = String(data: data!, encoding: .utf8) {
                        print(dataString)
                    }
                    print("You are not properly authenticated!")
                default:
                    if let dataString = String(data: data!, encoding: .utf8) {
                        print(dataString)
                    }
                    print("Something went wrong.")
                }
                
            }
        }
        task.resume()
    }
    
    func timeAgoSinceDate(_ date:Date, currentDate:Date, numericDates:Bool) -> String {
        let calendar = Calendar.current
        let now = currentDate
        let earliest = (now as NSDate).earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:DateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.minute , NSCalendar.Unit.hour , NSCalendar.Unit.day , NSCalendar.Unit.weekOfYear , NSCalendar.Unit.month , NSCalendar.Unit.year , NSCalendar.Unit.second], from: earliest, to: latest, options: NSCalendar.Options())
        
        if (components.year! >= 2) {
            return "\(components.year!) years ago"
        } else if (components.year! >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month! >= 2) {
            return "\(components.month!) months ago"
        } else if (components.month! >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear! >= 2) {
            return "\(components.weekOfYear!) weeks ago"
        } else if (components.weekOfYear! >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day! >= 2) {
            return "\(components.day!) days ago"
        } else if (components.day! >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour! >= 2) {
            return "\(components.hour!) hours ago"
        } else if (components.hour! >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute! >= 2) {
            return "\(components.minute!) minutes ago"
        } else if (components.minute! >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second! >= 3) {
            return "\(components.second!) seconds ago"
        } else {
            return "Just now"
        }
    }
}
