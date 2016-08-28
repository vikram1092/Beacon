//
//  SettingsTableController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/23/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit

class SettingsTableController: UITableViewController, UIGestureRecognizerDelegate {
    
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var userID = ""
    var userCountry = ""
    var userState = ""
    var userCity = ""
    let countryTable = CountryTable()
    
    @IBOutlet var countryPicture: UIImageView!
    @IBOutlet var userLocation: UILabel!
    @IBOutlet var countryBackground: CountryBackground!
    @IBOutlet var saveSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        
        
        //Run view load as normal
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        //Run as normal
        super.viewWillAppear(animated)
        
        //Get user defaults
        getUserDefaults()
        
        //Configure country picture
        setUserLocation()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        //Run as normal
        super.viewDidAppear(animated)
        
        //Turn switch to user saved state
        if userDefaults.objectForKey("saveMedia") != nil {
            
            //Set save switch to user preference
            let saveMedia = userDefaults.boolForKey("saveMedia")
            saveSwitch.setOn(saveMedia, animated: false)
        }
        
        //Set progress bar
        self.countryBackground.setProgress(0.6)
    }
    
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
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
    
    
    internal func getUserDefaults() {
        
        
        //Retreive user details
        if userDefaults.objectForKey("userID") != nil {
            
            userID = userDefaults.objectForKey("userID") as! String
        }
        
        if userDefaults.objectForKey("userCountry") != nil {
            
            userCountry = userDefaults.objectForKey("userCountry") as! String
        }
        
        if userDefaults.objectForKey("userState") != nil {
            
            userState = userDefaults.objectForKey("userState") as! String
        }
        
        if userDefaults.objectForKey("userCity") != nil {
            
            userCity = userDefaults.objectForKey("userCity") as! String
        }
    }
    
    
    internal func setUserLocation() {
        
        
        //Set location image and text
        var text = ""
        if userCountry == "us" && userState != "" {
            
            if userState.characters.count == 2 {
                
                
                text = countryTable.getStateName(userState) + ", " + countryTable.getCountryName(userCountry)
                
                //Set image for state if it exists. If not, use country image
                if countryTable.getStateImage(userState) == UIImage(named: "Countries/Unknown/128.png") {
                    
                    countryPicture.image = countryTable.getCountryImage(userCountry).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                }
                else {
                    
                    countryPicture.image = countryTable.getStateImage(userState).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                }
            }
            else {
                
                
                let stateCode = countryTable.getStateCode(userState)
                if stateCode == "Unknown" {
                    
                    text = countryTable.getCountryName(userCountry)
                    countryPicture.image = countryTable.getStateImage(stateCode).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                }
                else {
                    
                    text = userState + ", " + countryTable.getCountryName(userCountry)
                    countryPicture.image = countryTable.getStateImage(stateCode).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                }
            }
        }
        else if userCity != "" {
            
            text = userCity + ", " + countryTable.getCountryName(userCountry)
            countryPicture.image = countryTable.getCountryImage(userCountry).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        else if userCountry != "" {
            
            text = countryTable.getCountryName(userCountry)
            countryPicture.image = countryTable.getStateImage(userCountry).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        else {
            
            //Below function will return an unknown image
            text = "Unknown"
            countryPicture.image = countryTable.getStateImage(userCountry).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        
        
        userLocation.text = text
    }
    
    
    internal func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
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