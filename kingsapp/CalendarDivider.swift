//
//  CalendarDivider.swift
//  kingsapp
//
//  Created by Francesco on 30/09/2018.
//  Copyright © 2018 vx. All rights reserved.
//

import Cocoa

class CalendarDivider: NSView {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var upperLine: NSBox!
    @IBOutlet weak var lowerLine: NSBox!
    
    class func initWithData (title: String, isFirst: Bool, isLast: Bool) -> CalendarDivider? {
        var objects: NSArray?
        let success = NSNib(nibNamed: "CalendarDivider", bundle: nil)?.instantiate(withOwner: self, topLevelObjects: &objects)
        
        if success! {
            let view = objects!.first(where: { $0 is NSView }) as? CalendarDivider
            view?.titleLabel.stringValue = title
            if isFirst {
                view?.upperLine.isHidden = true
            }
            if isLast {
                view?.lowerLine.isHidden = true
            }
            return view
        }
        return nil
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
}
