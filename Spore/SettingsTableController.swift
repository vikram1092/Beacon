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
    var userName = ""
    var userEmail = ""
    var userCountry = ""
    let countryTable = CountryTable()
    
    @IBOutlet var logoutButton: UIView!
    @IBOutlet var countryPicture: UIImageView!
    @IBOutlet var usernameCell: UILabel!
    
    
    override func viewDidLoad() {
        
        //Run view load as normal
        super.viewDidLoad()
        
        //Retreive user details
        if userDefaults.objectForKey("userName") != nil {
            
            userName = userDefaults.objectForKey("userName") as! String
            userEmail = userDefaults.objectForKey("userEmail") as! String
        }
        
        if userDefaults.objectForKey("userCountry") != nil {
            
            userCountry = userDefaults.objectForKey("userCountry") as! String
        }
        
        //Configure profile picture
        countryPicture.image = countryTable.getCountryImage(userCountry).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        //Configure username adress label
        usernameCell.text = userDefaults.valueForKey("userName") as? String
    }
    
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        //Perform logout if tag matches Logout button tag
        if cell!.tag == 2 {
            
            performSegueWithIdentifier("TermsOfUseSegue", sender: self)
        }
        else if cell!.tag == 3 {
            
            performSegueWithIdentifier("PrivacyPolicySegue", sender: self)
        }
        else if cell!.tag == 4 {
            
            performSegueWithIdentifier("AboutSegue", sender: self)
        }
        else if cell!.tag == 5 {
            
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