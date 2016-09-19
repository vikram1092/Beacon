//
//  File.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Foundation
import AVFoundation

class MainController: UIViewController {
    
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var table: UIView!
    @IBOutlet var navItem: UINavigationBar!
    
    override func viewDidLoad() {
        
        //Load view
        super.viewDidLoad()
        
        //Get rid of an annoying black line under navigation bar
        navBar.clipsToBounds = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Run like usual
        super.viewDidAppear(true)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        
        print("Status bar style method - Main Controller")
        return UIStatusBarStyle.lightContent
    }
    
}

