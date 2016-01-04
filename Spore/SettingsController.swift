//
//  SettingsController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/21/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit

class SettingsController: UIViewController {
    
    @IBOutlet var backButton: UIBarButtonItem!
    var userName = ""
    var userEmail = ""
    
    override func viewDidLoad() {
        //Run view load as normal
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}