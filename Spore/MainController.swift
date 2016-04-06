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

class MainController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate {
    
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var table: UIView!
    @IBOutlet var navItem: UINavigationBar!
    
    override func viewDidLoad() {
        
        //Load view
        super.viewDidLoad()
        let image = UIImage(named: "Logo")
        navItem.topItem?.titleView = UIImageView(image: image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate))
        navItem.topItem?.titleView!.tintColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //Run like usual
        super.viewDidAppear(true)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        print("Status bar style method - Main Controller")
        return UIStatusBarStyle.LightContent
    }
    
}

