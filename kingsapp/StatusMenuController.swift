//
//  StatusMenuController.swift
//  kingsapp
//
//  Created by Francesco on 29/09/2018.
//  Copyright © 2018 vx. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject, PreferencesWindowDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    // Menu items and actions
    @IBOutlet weak var refreshItem: NSMenuItem!
    @IBOutlet weak var lastRefreshItem: NSMenuItem!
    @IBAction func refreshClicked(_ sender: Any) {
        updateCalendar()
        lastRefreshItem.title = "Refreshing..."
    }
    
    @IBAction func preferencesClicked(_ sender: Any) {
        preferencesWindow.showWindow(nil)
    }
    
    @IBAction func checkForUpdatesClicked(_ sender: Any) {
        self.checkForUpdatesAndPrompt()
    }
    
    // Utils
    let userDefaults = UserDefaults.standard
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ"
        return formatter
    }()
    
    let userFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss dd/MM/yy"
        return formatter
    }()
    
    // KCL
    let utils = Utils()
    let kingsAPI = KingsAPI()
    var currentCalendar: KingsAPI.KCLCalendarResponse? = nil
    var calendarLastRefresh: Date? = nil
    var username: String? = nil
    var password: String? = nil
    
    // UI
    var uiTimer: Timer? = nil
    var preferencesWindow: PrefsWindow!
    
    override func awakeFromNib() {
        // Setup menu
        statusItem.menu = statusMenu
        
        if let button = statusItem.button {
            let icon = NSImage(named: "statusIcon")
            icon?.isTemplate = true
            button.image = icon
        }
        
        // Check for updates
        self.checkForUpdatesAndPrompt()
        
        // Grab calendar from cache
        currentCalendar = loadCachedCalendar()
        loadCredentials()
        
        // Create preferences window
        preferencesWindow = PrefsWindow()
        preferencesWindow.delegate = self
        
        // Launch agent
        registerLaunchAgent()
        
        // Update UI
        updateUI()
        if currentCalendar == nil {
            updateCalendar()
        } else {
            print("Fetched calendar from cache successfully.")
            refreshCalendarView()
        }
    }
    
    func checkForUpdatesAndPrompt() {
        self.utils.checkForUpdates() { (updateAvailable) -> () in
            DispatchQueue.main.async { [unowned self] in
                print("Update available:", updateAvailable)
                if updateAvailable {
                    let alert = NSAlert()
                    alert.informativeText = "There's an update available."
                    alert.messageText = "Update available."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Update now")
                    alert.addButton(withTitle: "Remind me later")
                    if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
                        NSWorkspace.shared.open(URL(string: "https://github.com/frannyfx/kingsapp/releases")!)
                    }
                }
            }
        }
    }
    
    func registerLaunchAgent () {
        let plistPath = NSString(string: "~/Library/LaunchAgents/vx.kingsapp.plist").expandingTildeInPath
        if FileManager.default.fileExists(atPath: plistPath) {
            print("Already registered!")
        } else {
            print("App is installed but no launch agent is registered. Registering...")
            do {
                let plistContents = try String(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "LaunchAgent", ofType: "plist")!))
                FileManager.default.createFile(atPath: plistPath, contents: plistContents.data(using: .utf8))
                print("Success.")
            } catch {
                print("Unable to register launch agent.")
            }
        }
    }
    
    @objc func updateUI () {
        DispatchQueue.main.async { [unowned self] in
            if self.calendarLastRefresh != nil {
                self.lastRefreshItem.title = "Last refreshed " + self.utils.timeAgoSinceDate(self.calendarLastRefresh!, currentDate: Date(), numericDates: false).lowercased() + "."
            } else {
                self.lastRefreshItem.title = "Not yet refreshed."
            }
        }
        
        if self.uiTimer == nil {
            self.uiTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateUI), userInfo: nil, repeats: true)
        }
        
    }
    
    func preferencesDidUpdate() {
        print("Received delegate update.")
        loadCredentials()
        updateCalendar()
    }
    
    func loadCachedCalendar() -> KingsAPI.KCLCalendarResponse? {
        // Get date when calendar was last saved
        let lastRefreshValue = userDefaults.object(forKey: "calendarLastRefresh")
        if lastRefreshValue == nil {
            return nil
        }
        
        let lastRefresh = dateFormatter.date(from: lastRefreshValue as! String)
        let currentDate = Date()
        
        // Create threshold date
        let hoursThreshold = 24
        var components = DateComponents()
        components.hour = -1 * hoursThreshold
        let thresholdDate = NSCalendar.current.date(byAdding: components, to: currentDate)
        
        // Compare dates
        if lastRefresh! > thresholdDate! {
            calendarLastRefresh = lastRefresh
            let xmlCalendar = userDefaults.object(forKey: "calendarData") as! String
            print(xmlCalendar)
            return kingsAPI.parseCalendarResponse(data: xmlCalendar.data(using: .utf8)!)
        }
        
        return nil
    }
    
    func loadCredentials() {
        if let u =  userDefaults.object(forKey: "username") {
            username = u as! String
        }
        
        if let p =  userDefaults.object(forKey: "password") {
            password = p as! String
        }
        
        print("Loaded credentials.")
    }
    
    func saveCalendarToCache(xmlCalendar: String) {
        userDefaults.set(xmlCalendar, forKey: "calendarData")
        userDefaults.set(dateFormatter.string(from: Date()), forKey: "calendarLastRefresh")
        userDefaults.synchronize()
        
        print("Saved calendar to cache.")
    }
    
    func clearCalendarView() {
        for (i, item) in statusMenu.items.enumerated().reversed() {
            print(item.title)
            if item.title == "calendar_item" {
                statusMenu.removeItem(item)
            }
        }
        
        print(statusMenu.items)
    }
    
    func refreshCalendarView() {
        // First, remove old items
        clearCalendarView()
        
        // Get end index
        var insertIndex = 0
        
        // Instantiate header
        if (currentCalendar == nil) {
            return
        }
        
        let firstItem = currentCalendar?.calendar.items[0]
        //print(currentCalendar)
        let calendarDivider = CalendarDivider.initWithData(title: formatDividerDate(date: (firstItem?.start)!), isFirst: true, isLast: false)
        
        addCalendarItem(view: calendarDivider!, index: insertIndex)
        
        insertIndex += 1
        
        // Then, loop through the current calendar
        var lastWeekday:Int?
        for item in (currentCalendar?.calendar.items)! {
            let currentWeekday = Calendar.current.component(.weekday, from: item.start)

            // If the day of the week has changed, we need a new heading
            if lastWeekday != nil && lastWeekday != currentWeekday {
                let calendarDivider = CalendarDivider.initWithData(title: formatDividerDate(date: item.start), isFirst: false, isLast: false)
                
                addCalendarItem(view: calendarDivider!, index: insertIndex)
                insertIndex += 1
            }
            
            // Create calendar item
            let calendarViewItem = CalendarViewItem.initWithData(title: item.description ?? "", description: item.title ?? "", location: item.locationAddress, start: item.start, end: item.end)
            
            addCalendarItem(view: calendarViewItem!, index: insertIndex)
            
            // Increment stuff
            lastWeekday = Calendar.current.component(.weekday, from: item.start)
            insertIndex += 1
        }
        
        // Instantiate footer
        let footer = CalendarDivider.initWithData(title: "", isFirst: false, isLast: true)
        
        addCalendarItem(view: footer!, index: insertIndex)
    }
    
    func addCalendarItem(view: NSView, index: Int) {
        let menuItem = NSMenuItem()
        menuItem.title = "calendar_item"
        menuItem.view = view
        statusMenu.items.insert(menuItem, at: index)
    }
    
    func formatDividerDate (date: Date) -> String {
        let headingWeekday = dateFormatter.weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        let headingDay = Calendar.current.component(.day, from: date)
        let headingSuffix = getDaySuffix(day: headingDay)
        
        return "\(headingWeekday) \(headingDay)\(headingSuffix)"
    }
    
    func getDaySuffix (day: Int) -> String {
        switch (day) {
        case 1, 21, 31:
            return "st"
        case 2, 22:
            return "nd"
        case 3, 23:
            return "rd"
        default:
            return "th"
        }
    }
    
    func updateCalendar() {
        // Check if credentials are not nil
        if username == nil || password == nil {
            let alert = NSAlert()
            alert.informativeText = "Please go to \"Preferences\" and enter your credentials."
            alert.messageText = "Not authenticated."
            alert.alertStyle = .warning
            alert.runModal()
            preferencesWindow.showWindow(nil)
            return
        }
        
        
        // Dates
        let startDate = getSmartCalendarStartDate()
        
        // End date
        var dateComponents = DateComponents()
        dateComponents.day = 7
        
        let endDate = NSCalendar.current.date(byAdding: dateComponents, to: startDate)!
        
        // Update calendar
        print("Updating the calendar. Retrieving data from \(startDate) to \(endDate)")
        do {
            kingsAPI.fetchCalendar(username: username!, password: password!, from: startDate, to: endDate) { (result) -> () in
                self.saveCalendarToCache(xmlCalendar: String(data: result!, encoding: .utf8)!)
                
                // Parse
                self.currentCalendar = self.kingsAPI.parseCalendarResponse(data: result!)
                self.calendarLastRefresh = Date()
                
                // Refresh UI
                DispatchQueue.main.async {
                    self.refreshCalendarView()
                    self.updateUI()
                }
                
            }
        }
        catch {
            print("Unable to fetch calendar info.")
        }
    }
    
    func getSmartCalendarStartDate() -> Date {
        // Setup
        let currentDate = Calendar.current.startOfDay(for: Date())
        
        // Get start of this week
        var startDate = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))
        
        // Get day of the week
        let day = dateFormatter.weekdaySymbols[Calendar.current.component(.weekday, from: currentDate) - 1]
        
        // If it's the weekend look for the start of next week
        if day == "Saturday" || day == "Sunday" {
            var components = DateComponents()
            components.day = 7
            startDate = NSCalendar.current.date(byAdding: components, to: startDate!)
        }
        
        return startDate!
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        print("Quitting.")
        NSApplication.shared.terminate(self)
    }
}
