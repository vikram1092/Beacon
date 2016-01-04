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

    @IBOutlet var bannedLabel: UILabel!
    @IBOutlet var loginButton: FBSDKLoginButton!
    var userName = ""
    var userEmail = ""
    var bannedText = "You have been suspended due to some photos you've sent. Please allow us to investigate and reach a decision."
    
    override func viewDidLoad() {
        
        //Initialize objects and check for login status
        bannedLabel.alpha = 0
        loginButton = FBSDKLoginButton.init()
        
        //Check if already logged in
        if(FBSDKAccessToken.currentAccessToken() != nil) {

            checkWithDatabase()
        }
        else {
            
            //Obtain permissions from Facebook
            loginButton.readPermissions = ["public_profile", "email", "user_friends"]
            //If user is not logged in, load views
            super.viewDidLoad()
            
            // Configure login button
            loginButton.delegate = self
            loginButton.center = self.view.center
            self.view.addSubview(loginButton)
        }
    }
    
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult loginResult: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        print("User Logged In")
        
        if ((error) != nil){
            //Process error
            print("Facebook Login Error: " + error.description)
        }
        else if loginResult.isCancelled {
            //Handle cancellations
            print("Cancelled")
        }
        else {
            //Call function to check with database
            print("Checking with database")
            checkWithDatabase()
        }
    }
    
    //Function to retrieve FB information, save it, 
    internal func checkWithDatabase() {
        
        //Create request to obtain user email and name
        let accessToken = FBSDKAccessToken.currentAccessToken()
        let req = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email,name"], tokenString: accessToken.tokenString, version: nil, HTTPMethod: "GET")
        
        req.startWithCompletionHandler({ (connection, userResult, error : NSError!) -> Void in
            
            if(error == nil){
                
                //Query to find email ID in database. If it doesn't exist, create it.
                self.userName = userResult["name"] as! String
                self.userEmail = userResult["email"] as! String
                
                //Initialize query
                let query = PFQuery(className:"users")
                query.whereKey("email", containsString: self.userEmail)
                
                query.findObjectsInBackgroundWithBlock({ (users, error) -> Void in
                    
                    if error == nil && users!.count >= 1 {
                        
                        //Check if user is banned in database
                        print("Object 'users' count: " + String(users!.count))
                        let userBanned = users![0]["banned"] as! BooleanLiteralType
                        print(userBanned)
                        
                        //If user is not banned, segue on
                        if userBanned == false {
                            self.segueToNextView("LoginToMain")
                        }
                        //If user is banned, show message stating ban
                        else {
                            self.bannedLabel.text = self.bannedText
                            self.bannedLabel.font = UIFont(name: "Helvetica", size: 13.0)
                            self.bannedLabel.sizeToFit()
                            UIView.animateWithDuration(0.4) { () -> Void in
                                
                                self.bannedLabel.alpha = 1
                            }
                        }
                    }
                    else if error == nil && users!.count < 1 {
                        
                        //Create user in database when not found
                        let user = PFObject(className:"users")
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
            else{
                
                print("error \(error)")
            }
        })

    }
    
    internal func segueToNextView(identifier: String) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            self.performSegueWithIdentifier(identifier, sender: self)
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "LoginToMain") {
            let nextView = segue.destinationViewController as! MainController
            nextView.userName = self.userName
            nextView.userEmail = self.userEmail
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

