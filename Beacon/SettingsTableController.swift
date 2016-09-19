//
//  SettingsTableController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/23/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit

class SettingsTableController: UITableViewController, UIGestureRecognizerDelegate {
    
    
    let userDefaults = UserDefaults.standard
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
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        //Run as normal
        super.viewWillAppear(animated)
        
        //Get user defaults
        getUserDefaults()
        
        //Configure country picture
        setUserLocation()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Run as normal
        super.viewDidAppear(animated)
        
        //Turn switch to user saved state
        if userDefaults.object(forKey: "saveMedia") != nil {
            
            //Set save switch to user preference
            let saveMedia = userDefaults.bool(forKey: "saveMedia")
            saveSwitch.setOn(saveMedia, animated: false)
        }
        
        //Set progress bar
        self.countryBackground.setProgress(0.6)
    }
    
    
    internal override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        
        //Perform logout if tag matches Logout button tag
        if cell!.tag == 2 {
            
            performSegue(withIdentifier: "TermsOfUseSegue", sender: self)
        }
        else if cell!.tag == 3 {
            
            performSegue(withIdentifier: "PrivacyPolicySegue", sender: self)
        }
        else if cell!.tag == 4 {
            
            performSegue(withIdentifier: "AboutSegue", sender: self)
        }
        cell!.isSelected = false
    }
    
    
    @IBAction func saveSwitchFlipped(_ sender: AnyObject) {
        
        
        //Set saving on or off depending on trigger
        if saveSwitch.isOn {
            
            userDefaults.set(true, forKey: "saveMedia")
        }
        else {
            
            userDefaults.set(false, forKey: "saveMedia")
        }
    }
    
    
    internal func getUserDefaults() {
        
        
        //Retreive user details
        if userDefaults.object(forKey: "userID") != nil {
            
            userID = userDefaults.object(forKey: "userID") as! String
        }
        
        if userDefaults.object(forKey: "userCountry") != nil {
            
            userCountry = userDefaults.object(forKey: "userCountry") as! String
        }
        
        if userDefaults.object(forKey: "userState") != nil {
            
            userState = userDefaults.object(forKey: "userState") as! String
        }
        
        if userDefaults.object(forKey: "userCity") != nil {
            
            userCity = userDefaults.object(forKey: "userCity") as! String
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
                    
                    countryPicture.image = countryTable.getCountryImage(userCountry).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                }
                else {
                    
                    countryPicture.image = countryTable.getStateImage(userState).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                }
            }
            else {
                
                
                let stateCode = countryTable.getStateCode(userState)
                if stateCode == "Unknown" {
                    
                    text = countryTable.getCountryName(userCountry)
                    countryPicture.image = countryTable.getStateImage(stateCode).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                }
                else {
                    
                    text = userState + ", " + countryTable.getCountryName(userCountry)
                    countryPicture.image = countryTable.getStateImage(stateCode).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                }
            }
        }
        else if userCity != "" {
            
            text = userCity + ", " + countryTable.getCountryName(userCountry)
            countryPicture.image = countryTable.getCountryImage(userCountry).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
        else if userCountry != "" {
            
            text = countryTable.getCountryName(userCountry)
            countryPicture.image = countryTable.getStateImage(userCountry).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
        else {
            
            //Below function will return an unknown image
            text = "Unknown"
            countryPicture.image = countryTable.getStateImage(userCountry).withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        }
        
        
        userLocation.text = text
    }
    
    
    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
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
