//
//  SettingsTableController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/23/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class SettingsTableController: UITableViewController {
    
    @IBOutlet var logoutButton: UIView!
    @IBOutlet var profilePicture: UIImageView!
    
    override func viewDidLoad() {
        //Run view load as normal
        super.viewDidLoad()
        profilePicture.layer.cornerRadius = profilePicture.frame.size.width/2
        profilePicture.clipsToBounds = true
    }
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        //Perform logout if tag matches Logout button tag
        if cell!.tag == 1 {
            
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            //Segue back to the login screen
            performSegueWithIdentifier("Logout", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}