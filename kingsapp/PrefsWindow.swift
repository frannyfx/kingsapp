
//
//  PrefsWindow.swift
//  kingsapp
//
//  Created by Francesco on 01/10/2018.
//  Copyright © 2018 vx. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate()
}

class PrefsWindow: NSWindowController {

    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSTextField!

    @IBOutlet weak var applyButton: NSButton!
    @IBOutlet weak var validateButton: NSButton!
    
    // Delegate
    var delegate: PreferencesWindowDelegate?
    
    // Prefs
    let userDefaults = UserDefaults.standard
    var currentUsername: String! = ""
    var currentPassword: String! = ""
    
    // KCL
    let kingsAPI = KingsAPI()
    
    @IBAction func applyClicked(_ sender: Any) {
        userDefaults.set(usernameTextField.stringValue, forKey: "username")
        userDefaults.set(passwordTextField.stringValue, forKey: "password")
        userDefaults.synchronize()
        print("Saved data.")
        
        // Call delegate to warn that the preferences have updated
        delegate?.preferencesDidUpdate()
        
        // Close window
        self.window?.close()
    }
    
    @IBAction func validateClicked(_ sender: Any) {
        // Update UI
        progressIndicator.startAnimation(nil)
        
        // Disable controls
        validateButton.isEnabled = false
        usernameTextField.isEnabled = false
        passwordTextField.isEnabled = false

        
        // Ensure access token is registered
        //self.window?.becomeFirstResponder()
        
        kingsAPI.testCredentials(username: usernameTextField.stringValue, password: passwordTextField.stringValue) { (result) in
            print("Credentials test: \(result)")
            
            DispatchQueue.main.async {
                // Re-enable controls
                self.validateButton.isEnabled = true
                self.usernameTextField.isEnabled = true
                self.passwordTextField.isEnabled = true
                
                // Allow apply if the test was successful
                self.applyButton.isEnabled = result
                
                // Stop spinner
                self.progressIndicator.stopAnimation(nil)
            }
            
        }
    }
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override var windowNibName : String! {
        return "PrefsWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Load defaults
        if let username =  userDefaults.object(forKey: "username") {
            currentUsername = username as! String
        }
        
        if let password =  userDefaults.object(forKey: "password") {
            currentPassword = password as! String
        }
        
        usernameTextField.stringValue = currentUsername
        passwordTextField.stringValue = currentPassword
        
        // Keep on top
        self.window?.level = .floating
    }
    
}
