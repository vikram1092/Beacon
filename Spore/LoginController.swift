//
//  ViewController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Parse

class LoginController: UIViewController, FBSDKLoginButtonDelegate {

    
    @IBOutlet var alertButton: UIButton!
    @IBOutlet var fbLoginButton: FBSDKLoginButton!
    var userName = ""
    var userEmail = ""
    var bannedText = "You have been suspended due to some photos you've sent. Please allow us to investigate and reach a decision."
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    
    override func viewDidLoad() {
        
        //Initialize UI objects
        alertButton.alpha = 0

        //Set permissions to get from Facebook
        fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        
        // Configure Facebook login button
        fbLoginButton.delegate = self
        
        //Load as normal
        super.viewDidLoad()
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        return UIStatusBarStyle.LightContent
    }
    
    
    //Configure Facebook login button
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult loginResult: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if (error != nil){
            //Process error
            print("Facebook Login Error: " + error.description)
        }
        else if loginResult.isCancelled {
            //Handle cancellations
            print("Cancelled")
        }
        else {
            //Call function to check with database
            print("User Logged In: checking with database")
            getFacebookResults()
            
            //Hide button
            loginButton.alpha = 0
        }
    }
    
    
    internal func getFacebookResults() {
        
        //Create request to obtain user email and name
        let accessToken = FBSDKAccessToken.currentAccessToken()
        let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
        
        req.startWithCompletionHandler({ (connection, result, error : NSError!) -> Void in
            
            if(error == nil){
                
                //Send database
                self.checkWithDatabase(result, source: "Facebook")
            }
            else{
                
                print("error \(error.description)")
            }
        })
    }
    
    
    
    internal func checkWithDatabase(result: AnyObject, source: String) {
        
        
        let userResult = result as! NSDictionary
        //Query to find email ID in database. If it doesn't exist, create it.
        self.userName = userResult.objectForKey("name") as! String
        self.userEmail = userResult.objectForKey("email") as! String
        
        //Save details
        self.saveNameAndEmail(self.userName, email: self.userEmail)
        
        //Initialize query
        let query = PFQuery(className:"users")
        query.whereKey("email", equalTo: self.userEmail)
        
        query.findObjectsInBackgroundWithBlock({ (users, error) -> Void in
            
            if error == nil && users!.count >= 1 {
                
                //Check if user is banned in database
                print("Object 'users' count: " + String(users!.count))
                let userBanned = users![0]["banned"] as! BooleanLiteralType
                print(userBanned)
                
                //If user is banned, show message stating ban
                if userBanned == true {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.showAlert(self.bannedText)
                    })
                }
                else {
                    
                    // The user is not banned, seque to next screen
                    print("User logged in, segue-ing")
                    self.segueToNextView("LoginToMain")
                }
            }
            else if error == nil && users!.count < 1 {
                
                //Create user in database when not found
                let user = PFObject(className:"users")
                user["source"] = source
                user["email"] = self.userEmail
                user["banned"] = false
                
                user.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    if (success) {
                        
                        // The user has been saved, seque to next screen
                        print("New user saved")
                        self.segueToNextView("LoginToMain")
                    }
                    else {
                        
                        // There was a problem, check error.description
                        print("Error saving user")
                        print(error!.description)
                    }
                }
            }
            else {
                print("Error: " + String(error))
            }
        })
        
        print("result \(userResult)")
    }
    
    
    internal func showAlert(text: String) {
        
        self.alertButton.setTitle(text, forState: .Normal)
        self.alertButton.sizeToFit()
        
        UIView.animateWithDuration(0.4) { () -> Void in
            
            self.fbLoginButton.alpha = 0
            self.alertButton.alpha = 1
        }
        
        //Logout user
        logoutUser()
        
    }
    
    
    @IBAction func alertButtonPressed(sender: AnyObject) {
        
        UIView.animateWithDuration(0.4) { () -> Void in
            
            self.fbLoginButton.alpha = 1
            self.alertButton.alpha = 0
        }
    }
    
    
    internal func logoutUser() {
        
        //Logout user
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            //Reset name and email local variables
            self.userDefaults.setObject(nil, forKey: "userName")
            self.userDefaults.setObject(nil, forKey: "userEmail")
        }
    }
    
    
    internal func saveNameAndEmail(name: String, email: String) {
        
        userDefaults.setObject(name, forKey: "userName")
        userDefaults.setObject(email, forKey: "userEmail")
    }
    
    
    internal func segueToNextView(identifier: String) {
        
        
        if self.tabBarController == nil {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.dismissViewControllerAnimated(true, completion: nil)
                self.performSegueWithIdentifier(identifier, sender: self)
            })
        }
        else {
            
            //Go to camera
            self.tabBarController?.selectedIndex = 0
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "LoginToMain" {
            
            let destinationController = segue.destinationViewController as! SnapController
            let destinationChildController = destinationController.childController 
            
            destinationChildController.selectedIndex = 0
            
        }
    }
    
    
    internal func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

