//
//  CalendarViewItem.swift
//  kingsapp
//
//  Created by Francesco on 30/09/2018.
//  Copyright © 2018 vx. All rights reserved.
//

import Cocoa

class CalendarViewItem: NSView {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var startTimeLabel: NSTextField!
    @IBOutlet weak var infoLabel: NSTextField!
    
    class func initWithData (title: String, description: String, location: String, start: Date, end: Date) -> CalendarViewItem? {
        var objects: NSArray?
        let success = NSNib(nibNamed: "CalendarViewItem", bundle: nil)?.instantiate(withOwner: self, topLevelObjects: &objects)
        
        if success! {
            let view = objects!.first(where: { $0 is NSView }) as? CalendarViewItem
            view?.titleLabel.stringValue = title
            view?.descriptionLabel.stringValue = description
            
            // Calculate lecture length
            let timespan = end.timeIntervalSince(start)
            let hours = Int(timespan / 3600)
            let minutes = Int((timespan - Double(hours * 3600)) / 60)
            var lectureLengthString = "\(hours)"
            
            if hours == 1 {
                lectureLengthString += " hour"
            } else {
                lectureLengthString += " hours"
            }
            
            if minutes != 0 {
                lectureLengthString += "and \(minutes) minutes"
            }
            
            view?.infoLabel.stringValue = "\(lectureLengthString) - \(location)"
            
            let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "H:mm"
                return formatter
            }()
            
            view?.startTimeLabel.stringValue = formatter.string(from: start)
            view?.toolTip = lectureLengthString
            
            return view
        }
        return nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
}
