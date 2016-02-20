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

class SettingsTableController: UITableViewController, UIGestureRecognizerDelegate {
    
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var logoutButton: UIView!
    @IBOutlet var profilePicture: UIImageView!
    
    
    override func viewDidLoad() {
        //Run view load as normal
        super.viewDidLoad()
        
        // Enable swipe back when no navigation bar
        self.navigationController!.interactivePopGestureRecognizer!.delegate = self
        
        profilePicture.layer.cornerRadius = profilePicture.frame.size.width/2
        profilePicture.clipsToBounds = true
    }
    
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        //Perform logout if tag matches Logout button tag
        if cell!.tag == 3 {
            
            performSegueWithIdentifier("PrivacyPolicySegue", sender: self)
        }
        if cell!.tag == 5 {
            
            //Segue back to the login screen
            performSegueWithIdentifier("Logout", sender: self)
            
            //Logout user
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            //Reset name and email local variables
            userDefaults.setObject(nil, forKey: "userName")
            userDefaults.setObject(nil, forKey: "userEmail")
            
        }
    }
    
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}