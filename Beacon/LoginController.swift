//
//  ViewController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse

class LoginController: UIViewController {

    
    @IBOutlet var logoView: UIImageView!
    @IBOutlet var dotViewLeft: DotView!
    @IBOutlet var dotViewRight: DotView!
    @IBOutlet var alertButton: UIButton!
    @IBOutlet var workingView: UIView!
    @IBOutlet var workingMessageLabel: UILabel!
    @IBOutlet var beaconingIndicator: BeaconingIndicator!
    
    var userID: String? = nil
    var banned: Bool? = nil
    var bannedText = "You have been suspended due to some of your activities. Please allow us to investigate and check back later."
    let userDefaults = UserDefaults.standard
    
    
    override func viewDidLoad() {
        
        //Load as normal
        super.viewDidLoad()
        
        //Initialize views
        self.view.sendSubview(toBack: dotViewLeft)
        self.view.sendSubview(toBack: dotViewRight)

        dotViewLeft.frame = self.view.bounds
        dotViewRight.frame = self.view.bounds
        dotViewLeft.initializeViews()
        dotViewRight.initializeViews()
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        //Initialize UI objects
        alertButton.alpha = 0
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Start animating all views
        beaconingIndicator.initializeView()
        beaconingIndicator.changeColor(UIColor.white.cgColor)
        beaconingIndicator.startAnimating()
        
        if !dotViewLeft.isAnimating {
            
            dotViewLeft.startAnimating(23)
        }
        
        if !dotViewRight.isAnimating {
            
            dotViewRight.startAnimating(-23)
        }
        
        handleUserRegistration()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        
        //Stop all animations
        dotViewLeft.stopAnimating()
        dotViewRight.stopAnimating()
        beaconingIndicator.stopAnimating()
    }
    
    
    internal func handleUserRegistration() {
        
        
        //Get user defaults
        getUserDefaults()
        
        //Handle the userID depending on whether it's valid or not
        if userID == nil {
            
            DispatchQueue.global(qos: .utility).async(execute: {
                
                self.generateNewUserID()
            })
        }
        else if userID != nil && banned! {
            
            showWorkingView()
            checkIfUserBanned()
        }
    }
    
    
    internal func getUserDefaults() {
        
        //Get user ID
        userID = userDefaults.object(forKey: "userID") as? String
        
        //Get banned status
        banned = userDefaults.bool(forKey: "banned")
    }
    
    
    internal func generateNewUserID() {
        
        
        //Show user animation
        showWorkingView()
        
        //Create random string
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
        var newUserID = ""
        let length = 50
        
        for _ in 0..<length {
            
            let randomIndex = Int(arc4random_uniform(UInt32(characters.characters.count)))
            let newChar = characters[characters.characters.index(characters.startIndex, offsetBy: randomIndex)]
            newUserID.append(newChar)
        }
        
        
        //Check database to see if user exists already
        do {
            
            let query = PFQuery(className: "users")
            query.whereKey("userID", equalTo: newUserID)
            let objects = try query.findObjects()

            if objects.count == 0 {
                
                //User doesn't exist, save user locally
                userID = newUserID
                saveID(userID!)
                
                //Also create user in database
                let user = PFObject(className:"users")
                user["userID"] = self.userID
                user["banned"] = false
                
                user.saveInBackground { (success, error)  in
                    if (success) {
                        
                        // The user has been saved, seque to next screen
                        print("New user saved")
                        
                        self.showAlert(self.userID!)
                        self.segueToNextView("LoginToMain")
                    }
                    else {
                        
                        // There was a problem, check error
                        print("Error saving user: \(error)")
                        self.showAlert("We encountered an error. Tap here to try again.")
                        
                    }
                }
            }
            else if objects.count > 0 {
                
                //User exists, redo function
                generateNewUserID()
            }
        }
        catch let error as NSError {
            
            print("Error searching for userID: \(error)")
            self.showAlert("We encountered an error. Tap here to try again.")
        }
    }
    
    
    internal func showWorkingView() {
        
        DispatchQueue.main.async { 
            
            if self.workingView.alpha != 1 {
                
                UIView.animate(withDuration: 0.4, animations: {
                    
                    self.workingView.alpha = 1
                }) 
            }
        }
    }
    
    
    internal func showAlert(_ text: String) {
        
        self.alertButton.setTitle(text, for: UIControlState())
        self.alertButton.titleLabel?.textAlignment = NSTextAlignment.center
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.workingView.alpha = 0
            }, completion: { (Bool) in
                
                UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    
                    self.alertButton.alpha = 1
                }) 
        }) 
        
    }
    
    
    @IBAction func alertButtonPressed(_ sender: AnyObject) {
    
        
        UIView.animate(withDuration: 0.4, animations: { 
            
            //Animate label
            self.alertButton.alpha = 0
            
            }, completion: { (Bool) in
                
                //Handle user registration
                self.handleUserRegistration()
        }) 
        
    }
    
    
    internal func saveID(_ id: String) {
        
        //Save user ID
        userDefaults.set(id, forKey: "userID")
    }
    
    
    internal func checkIfUserBanned() {
        
        //Show alert if user is banned
        let query = PFQuery(className: "users")
        query.whereKey("userID", equalTo: userID!)
        query.getFirstObjectInBackground { (userObject, error) -> Void in
            
            if error != nil {
                
                print("Error getting user banned status: \(error)")
            }
            else {
                
                let bannedStatus = userObject!.object(forKey: "banned") as! Bool
                
                if !bannedStatus {
                    
                    //Un-ban user
                    print("User not banned anymore.")
                    self.userDefaults.removeObject(forKey: "banned")
                    self.segueToNextView("LoginToMain")
                }
                else {
                    print("User is still banned!")
                    DispatchQueue.main.async(execute: { 
                        
                        //Show user that they're still banned
                        self.showAlert(self.bannedText)
                    })
                }
            }
        }
    }
    
    
    internal func segueToNextView(_ identifier: String) {
        
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            if self.tabBarController == nil {
                
                    
                    self.dismiss(animated: true, completion: nil)
                    self.performSegue(withIdentifier: identifier, sender: self)
            }
            else {
                
                //Go to camera
                self.tabBarController?.selectedIndex = 0
            }
        })
    }
    
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        
        return UIStatusBarStyle.lightContent
    }
    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

