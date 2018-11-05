//
//  KingsAPI.swift
//  kingsapp
//
//  Created by Francesco on 29/09/2018.
//  Copyright © 2018 vx. All rights reserved.
//

import Foundation
class KingsAPI {
    let BASE_URL = "https://campusm.kcl.ac.uk//kcl_live/services/CampusMUniversityService/retrieveCalendar"
    let NAMESPACE = "http://campusm.gw.com/campusm"
    let APP_TOKEN = "YXBwbGljYXRpb25fc2VjX3VzZXI6ZjJnaDUzNDg="
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ"
        return formatter
    }()
    
    struct KCLCalendarResponse: Codable {
        var calendar: KCLCalendar
        
        enum CodingKeys: String, CodingKey {
            case calendar = "ns1:calendar"
        }
    }
    
    struct KCLCalendar: Codable {
        var items: [KCLCalendarItem]
        
        enum CodingKeys: String, CodingKey {
            case items = "ns1:calitem"
        }
    }
    
    struct KCLCalendarItem: Codable {
        var title: String?
        var description: String?
        var start: Date
        var end: Date
        var teacherName: String?
        var locationCode: String
        var locationAddress: String
        
        enum CodingKeys: String, CodingKey {
            case title = "ns1:desc1"
            case description = "ns1:desc2"
            case start = "ns1:start"
            case end = "ns1:end"
            case teacherName = "ns1:teacherName"
            case locationCode = "ns1:locCode"
            case locationAddress = "ns1:locAdd1"
        }
    }
    
    func parseCalendarResponse (data: Data) -> KCLCalendarResponse? {
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        let response: KCLCalendarResponse?
        
        do {
            response = try decoder.decode(KCLCalendarResponse.self, from: data)
            let items = response?.calendar.items.sorted(by: {$0.start < $1.start})
            response?.calendar.items = items!
            return response
        } catch {
            print ("Something went wrong while parsing the calendar response.\n\(error)")
        }
        
        return nil
    }
    
    func makeCalendarPayload (username: String, password: String, start: Date, end: Date) -> String {
        // Get dates
        let formattedStart = formatter.string(from: start)
        let formattedEnd = formatter.string(from: end)
        print("Start: \(formattedStart) -> End: \(formattedEnd)")
        
        var payload = "<retrieveCalendar xmlns=\"\(NAMESPACE)\">\n"
        payload += "    <username>\(username)</username>\n"
        payload += "    <password>\(password)</password>\n"
        payload += "    <calType>course_timetable</calType>\n"
        payload += "    <start>\(formattedStart)</start>\n"
        payload += "    <end>\(formattedEnd)</end>\n"
        payload += "</retrieveCalendar>"
        return payload
    }
    
    func testCredentials (username: String, password: String, completion: @escaping(Bool)->()) {
        let session = URLSession.shared
        let url = URL(string: BASE_URL)
        
        // Setup the request
        var request = URLRequest(url: url!)
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic " + APP_TOKEN, forHTTPHeaderField: "Authorization")
        
        // Get payload
        let payload = makeCalendarPayload(username: username, password: password, start: Date(), end: Date().addingTimeInterval(1))
        
        // Add body
        request.httpMethod = "POST"
        request.httpBody = payload.data(using: .utf8)
        
        let task = session.dataTask(with: request) { data, response, err in
            if let error = err {
                print(error)
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    completion(true)
                    return
                default:
                    completion(false)
                    print(httpResponse.statusCode)
                    if let dataString = String(data: data!, encoding: .utf8) {
                        print(dataString)
                    }
                    return
                
                }
            }
        }
            
        task.resume()
    }
    
    func fetchCalendar (username: String, password: String, from: Date, to: Date, completion: @escaping (Data?)->()) {
        let session = URLSession.shared
        let url = URL(string: BASE_URL)
        
        // Setup the request
        var request = URLRequest(url: url!)
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic " + APP_TOKEN, forHTTPHeaderField: "Authorization")
        
        // Get payload
        let payload = makeCalendarPayload(username: username, password: password, start: from, end: to)
        print(payload)
        
        // Add body
        request.httpMethod = "POST"
        request.httpBody = payload.data(using: .utf8)

        let task = session.dataTask(with: request) { data, response, err in
            if let error = err {
                print("KCL API error \(error)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    if let dataString = String(data: data!, encoding: .utf8) {
                        print("Received successful response:\n \(dataString)")
                        completion(data!)
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
}
