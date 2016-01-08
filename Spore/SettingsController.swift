//
//  SettingsController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/21/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit

class SettingsController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet var backButton: UIBarButtonItem!
    var userName = ""
    var userEmail = ""
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        
        //Retreive user details
        userName = userDefaults.objectForKey("userName") as! String
        userEmail = userDefaults.objectForKey("userEmail") as! String
        
        //Run view load as normal
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //Add navigation swipe functionality
        self.navigationController!.interactivePopGestureRecognizer!.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

}