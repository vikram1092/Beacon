///
//  AppDelegate.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    
    var window: UIWindow?

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        //If the user email is not set, segue to login screen
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        print("userID: \(userDefaults.objectForKey("userID"))")
        
        if userDefaults.objectForKey("userID") == nil || (userDefaults.objectForKey("userID") != nil && userDefaults.boolForKey("banned") == true) {
            
            print("App delegate switching")
            self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let initialViewController = storyboard.instantiateViewControllerWithIdentifier("LoginController") as! LoginController
            
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()
            
        }
        
        let parseConfiguration = ParseClientConfiguration(block: { (ParseMutableClientConfiguration) -> Void in
            ParseMutableClientConfiguration.localDatastoreEnabled = true
            ParseMutableClientConfiguration.applicationId = "4x876bs89d7nyfvf58r96ht7moac8"
            ParseMutableClientConfiguration.clientKey = "7as5f76rsdg0s78dtfw89ht8c64f34743f"
            ParseMutableClientConfiguration.server = "http://beacon12-test.herokuapp.com/parse"
            
            //DEMO CODE TESTING -- Test Database turned on
            /*
            ParseMutableClientConfiguration.applicationId = "4h5gk62hjg62g2h435igou"
            ParseMutableClientConfiguration.clientKey = "59ad78f5d5g48fhs9f78saf5d67gs"
            ParseMutableClientConfiguration.server = "https://beacon12.herokuapp.com/parse"*/
        })
        
        Parse.initializeWithConfiguration(parseConfiguration)
        
        //Setup audio session
        do {
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [AVAudioSessionCategoryOptions.MixWithOthers, AVAudioSessionCategoryOptions.DefaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            
        }
        catch let error as NSError { print("Error setting audio session category \(error)") }
        
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

