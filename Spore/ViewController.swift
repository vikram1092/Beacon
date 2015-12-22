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

class ViewController: UIViewController, FBSDKLoginButtonDelegate {

    @IBOutlet var loginButton: FBSDKLoginButton!
    
    override func viewDidLoad() {
        
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        
        loginButton = FBSDKLoginButton.init()
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
                let UserListController = self.storyboard!.instantiateViewControllerWithIdentifier("UserListController") as! UserListController
                
                self.navigationController?.pushViewController(UserListController, animated: true)
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

