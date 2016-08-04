//
//  SettingsController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/21/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {
    
    var userID = ""
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    
    override func viewDidLoad() {
        
        //Retreive user details
        userID = userDefaults.objectForKey("userID") as! String
        
        //Run view load as normal
        super.viewDidLoad()
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        print("Status bar style method - Settings Controller")
        return UIStatusBarStyle.LightContent
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}