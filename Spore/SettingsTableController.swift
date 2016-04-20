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
    @IBOutlet var countryBackground: CountryBackground!
    @IBOutlet var saveSwitch: UISwitch!
    
    
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
        countryBackground.changeBackgroundColor(UIColor(red: 254.0/255.0, green: 202.0/255.0, blue: 22.0/255.0, alpha: 1).CGColor)
        countryPicture.image = countryTable.getCountryImage(userCountry).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        countryBackground.bringSubviewToFront(countryPicture)
        
        //Configure username adress label
        usernameCell.text = userDefaults.valueForKey("userCity") as? String
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        if userDefaults.objectForKey("saveMedia") != nil {
            
            //Set save switch to user preference
            let saveMedia = userDefaults.boolForKey("saveMedia")
            saveSwitch.setOn(saveMedia, animated: false)
        }
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
        else if cell!.tag == 10 {
            
            //Segue back to the login screen
            performSegueWithIdentifier("Logout", sender: self)
            
            //Logout user
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
            //Reset name and email local variables
            userDefaults.setObject(nil, forKey: "userName")
            userDefaults.setObject(nil, forKey: "userEmail")
            
        }
        
        cell!.selected = false
    }
    
    
    
    @IBAction func saveSwitchFlipped(sender: AnyObject) {
        
        
        //Set saving on or off depending on trigger
        if saveSwitch.on {
            
            userDefaults.setBool(true, forKey: "saveMedia")
        }
        else {
            
            userDefaults.setBool(false, forKey: "saveMedia")
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