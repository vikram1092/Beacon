//
//  userListController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 1/26/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Bolts
import UIKit
import Parse
import ParseUI
import Foundation
import CoreTelephony
import AVFoundation


class UserListController: UITableViewController {
    
    
    var userList = Array<PFObject>()
    var sendingList = Array<PFObject>()
    var userID = ""
    var userCountry = ""
    var userState = ""
    var userCity = ""
    var userLatitude = NSNumber()
    var userLongitude = NSNumber()
    var userToReceivePhotos = 0
    var countryCenter = CGPoint(x: 0,y: 0)
    var countryTable = CountryTable()
    var checkingForNewBeacons = false
    var checkingForReplyBeacons = false
    var haveSetAlertAfterSending = false
    var showNoMoreBeaconsAlert = false
    
    var tutorialTapBeaconView = TutorialView()
    var tutorialSwipeBeaconView = TutorialView()
    var tutorialBeaconTimeView = TutorialView()
    var tutorialReportBeaconView = TutorialView()
    var tutorialTapBeaconViewShown = false
    var tutorialSwipeBeaconViewShown = false
    var tutorialBeaconTimeViewShown = false
    var tutorialReportBeaconViewShown = false
    
    var locManager = CLLocationManager()
    var beaconRefresh = BeaconRefresh(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    let defaultColor = BeaconColors().redColor
    let sendingColor = BeaconColors().yellowColor
    let replyColor = BeaconColors().lightBlueColor
    let refreshBackgroundColor = BeaconColors().blueColor
    let fileManager = NSFileManager.defaultManager()
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let videoPath = NSTemporaryDirectory() + "receivedVideo.mp4"
    let tableVideoPrefix = NSTemporaryDirectory() + "tableVideo_"
    let tableVideoBounds = CGRect(x: 0, y: 0, width: 85, height: 85)
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let calendar = NSCalendar.currentCalendar()
    
    
    
    override func viewDidLoad() {
        
        //Load view as usual
        super.viewDidLoad()
        
        initializeRefreshControl()
        
        tableView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        print("viewWillAppear")
        //Retreive user defaults
        getUserDefaults()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        //Run like usual
        print("viewDidAppear")
        super.viewDidAppear(true)
        
        //Resume any ongoing animations
        resumeAnimations()
        
        //Check user login status
        print("Checking user login status")
        if userDefaults.objectForKey("userID") != nil {
            
            //Check if user is banned in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.userIsBanned()
            })
            
            //Get userToReceivePhotos
            if userDefaults.integerForKey("userToReceivePhotos") > 0 {
                userToReceivePhotos = userDefaults.integerForKey("userToReceivePhotos")
            }
            
            //Load user list
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                
                //Load user list
                self.loadUserList()
            })
        }
        else {
            segueToLogin()
        }
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        //Reload visible rows
        print("viewDidDisappear")
        reloadVisibleRows()
        refreshControl!.endRefreshing()
        beaconRefresh.stopAnimating()
        removeTutorialBeaconTimeView()
    }
    
    
    
    
    internal func userIsBanned() {
        
        //Show alert if user is banned
        let query = PFQuery(className: "users")
        query.whereKey("userID", equalTo: userID)
        query.getFirstObjectInBackgroundWithBlock { (userObject, error) -> Void in
            
            if error != nil {
                
                print("Error getting user banned status: " + error!.description)
            }
            else {
                
                let bannedStatus = userObject!.objectForKey("banned") as! BooleanLiteralType
                
                if bannedStatus {
                    
                    //Alert user about ban, mark user as banned & segue to login
                    print("User banned.")
                    let alert = UIAlertController(title: "You've been banned", message: "Allow us to investigate this issue & check back soon.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                        self.segueToLogin()
                    }))
                    
                    self.userDefaults.setBool(true, forKey: "banned")
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    print("User is not banned!")
                }
            }
        }
    }
    
    
    internal func getUserDefaults() {
        
        //Retreive user details
        if userDefaults.objectForKey("userID") != nil {
            
            userID = userDefaults.objectForKey("userID") as! String
        }
        
        if userDefaults.objectForKey("userLatitude") != nil {
            
            userLatitude = userDefaults.objectForKey("userLatitude") as! Double
            userLongitude = userDefaults.objectForKey("userLongitude") as! Double
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
    
    
    internal func saveUserList() {
        
        //Clean old photos to save local space
        for object in userList {
            
            if object.objectForKey("receivedAt") != nil {
                
                if(!withinTime(object.objectForKey("receivedAt") as! NSDate)) {
                    
                    object.removeObjectForKey("photo")
                }
            }
        }
        
        //Save everything
        PFObject.pinAllInBackground(userList)
    }
    
    
    internal func loadUserList() {
        
        
        //Retreive local user photo list
        print("loadUserList")
        let query = PFQuery(className: "photo")
        query.fromLocalDatastore()
        query.whereKey("localTag", equalTo: userID)
        
        query.addAscendingOrder("localCreationTag")
        query.findObjectsInBackgroundWithBlock { (objects, retreivalError) -> Void in
            
            if retreivalError != nil {
                
                print("Problem retreiving list: " + retreivalError!.description)
            }
            else if objects!.count > 0 && objects!.count != self.userList.count {
                
                
                //Changes have taken place in local datastore, reload table and send unsent photos
                self.userList = objects!
                print("Reloading table after local retreival")
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Update table
                    self.tableView.reloadData()
                    
                })
                
                //Set alert flag, send any unsent photos and update the table with new photos
                print("Adding new photos")
                self.haveSetAlertAfterSending = false
                self.sendUnsentPhotos()
                self.updateUserList()
            }
            else {
                
                //Nothing has changed, update user list if it's not already updating
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    
                    if !self.checkingForNewBeacons {
                        self.updateUserList()
                    }
                })
            }
        }
    }
    
    
    
    
    internal func sendUnsentPhotos() {
        
        //Send all photos that haven't been sent
        for photoObj in self.userList {
            
            
            if photoObj["sentBy"] as! String == self.userID && photoObj["receivedBy"] == nil {
                
                //Enable no more beacons left alert if it hasn't been shown
                if !haveSetAlertAfterSending {
                
                    haveSetAlertAfterSending = true
                    showNoMoreBeaconsAlert = true
                }
                
                //Send each photo
                self.sendUnsentPhoto(photoObj, updateUserList: true)
            }
        }
    }
    
    
    internal func sendUnsentPhoto(photoObject: PFObject, updateUserList: Bool) {
        
        //Check if geopoint exists and political data doesnt.
        //If so, call the method for it and revert back here through it.
        //If not, simply send the object
        print("sendUnsentPhoto")
        
        //Run unless object is already sending
        if !sendingList.contains(photoObject) {
            
            //Add to list
            sendingList.append(photoObject)
            
            //Initialize user variables
            let geoPoint = photoObject["sentFrom"] as! PFGeoPoint
            let sentCountry = photoObject["countryCode"] as? String
            let sentState = photoObject["sentState"] as? String
            let sentCity = photoObject["sentCity"] as? String
            
            //Declare necessary variables
            let cell = getCellForObject(photoObject)
            let countryBackground = cell?.viewWithTag(6) as? CountryBackground
            let subTitleView = cell?.viewWithTag(2) as? UILabel
            
            
            //Update cell to let user know photo is processing
            photoObject.removeObjectForKey("sendingStatus")
            photoObject.setObject(true, forKey: "isAnimating")
            
            if cell != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    subTitleView!.text = "Sending..."
                    countryBackground!.startAnimating()
                })
            }
            
            
            //If geopoint is valid & we don't  have political details, get them first. If we already have those details, send photo
            if (geoPoint.latitude != 0.0 || geoPoint.longitude != 0.0) && (sentCountry == "" && (sentState == nil || sentState == "") && (sentCity == nil || sentCity == "")) {
                
                getPoliticalDetails(geoPoint, photoObject: photoObject)
            }
            else {
                
                sendPhotoToDatabase(photoObject, updateUserList: true)
            }
        }
    }
    
    
    internal func sendPhotoToDatabase(photoObj: PFObject, updateUserList: Bool) {
        
        
        print("sendPhotoToDatabase")
        //Create media file for object before sending since local datastore does not persist PFFiles
        let filePath = documentsDirectory + (photoObj.objectForKey("filePath") as! String)
        
        //If photo exists, send the object. If not, delete it
        if fileManager.fileExistsAtPath(filePath) {
            
            
            //Save photo object
            photoObj["photo"] = PFFile(data: NSData(contentsOfFile: filePath)!)
            photoObj.saveInBackgroundWithBlock { (saved, error) -> Void in
                
                
                if error != nil {
                    
                    
                    print("Error saving object: \(error)")
                    
                    //Let user know
                    photoObj.setObject("Ready", forKey: "sendingStatus")
                    photoObj.removeObjectForKey("isAnimating")
                    self.sendingList.removeAtIndex(self.sendingList.indexOf(photoObj)!)
                    
                    let cell = self.getCellForObject(photoObj)
                    let countryBackground = cell?.viewWithTag(6) as? CountryBackground
                    let subTitleView = cell?.viewWithTag(2) as? UILabel
                    
                    if cell != nil {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            
                            subTitleView!.text = "Sending failed"
                            countryBackground!.stopAnimating()
                        })
                    }
                }
                else if saved {
                    
                    
                    //If sent, remove locally
                    print("Removing sent object")
                    photoObj.unpinInBackground()
                    
                    if self.userList.contains(photoObj) {
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            
                            if photoObj.objectForKey("replyTo") == nil {
                                
                                //Update user photo variables
                                self.updateUserPhotos()
                            }
                            
                            
                            //Remove from user list and table and clear local path
                            self.sendingList.removeAtIndex(self.sendingList.indexOf(photoObj)!)
                            self.userList.removeAtIndex(self.userList.indexOf(photoObj)!)
                            self.tableView.reloadData()
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                
                                self.clearLocalFile(filePath)
                            })
                            
                            
                            if updateUserList {
                                
                                //Update table twith new photo
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                    
                                    //Update user list and table
                                    self.updateUserList()
                                })
                            }
                        })
                    }
                }
                else if !saved {
                    
                    
                    //If sending fails, let user know
                    photoObj.setObject("Ready", forKey: "sendingStatus")
                    photoObj.removeObjectForKey("isAnimating")
                    self.sendingList.removeAtIndex(self.sendingList.indexOf(photoObj)!)
                    
                    let cell = self.getCellForObject(photoObj)
                    let countryBackground = cell?.viewWithTag(6) as? CountryBackground
                    let subTitleView = cell?.viewWithTag(2) as? UILabel
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        if cell != nil {
                            if subTitleView!.text == "Sending..." {
                                subTitleView!.text = "Sending failed"
                            }
                            countryBackground!.stopAnimating()
                        }
                    })
                }
            }
        }
        else {
            
            
            //Remove from local datastore and temporary sending list
            self.sendingList.removeAtIndex(self.sendingList.indexOf(photoObj)!)
            photoObj.unpinInBackground()
            
            //If table contains photo, delete it from everywhere
            if userList.contains(photoObj) {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Remove from user list and table
                    self.userList.removeAtIndex(self.userList.indexOf(photoObj)!)
                    self.tableView.reloadData()
                })
            }
            
        }
        
    }
    
    
    internal func getCellForObject(photoObject: PFObject) -> UITableViewCell? {
        
        
        let indexPath = NSIndexPath(forRow: userList.count - 1 - userList.indexOf(photoObject)!
            , inSection: 0)
        
        return tableView.cellForRowAtIndexPath(indexPath)
    }
    
    
    internal func updateUserList() {
        
        //Check for new beacons
        checkForNewBeacons(false, sameState: false, sameCity: false, likePrevious: false)
        
        //Check for reply beacons
        checkForReplyBeacons()
    }
    
    
    internal func checkForNewBeacons(sameCountry: Bool, sameState: Bool, sameCity: Bool, likePrevious: Bool) {
        
        
        //Initialize for subtracting from userToReceivePhotos list
        print("checkForNewBeacons")
        checkingForNewBeacons = true
        var userReceivedPhotos = 0
        
        
        //If user is to receive photos, execute the following
        if userToReceivePhotos > 0 {
            
            
            //Get unsent photos in the database equal to how many the user gets
            //Place conditions to get unreceived photos from people preferably not from the same country
            //or the previous beacon's location
            let query = PFQuery(className:"photo")
            query.whereKeyExists("photo")
            //DEMO CODE - REPLACE BEFORE RELEASE
            //query.whereKey("sentBy", notEqualTo: userID)
            query.whereKeyDoesNotExist("receivedBy")
            query.whereKeyDoesNotExist("replyTo")
            query.orderByAscending("createdAt")
            query.limit = userToReceivePhotos
            
            let previous = userList.last
            
            
            //Handle restrictions per given parameters
            //First check country restriction, then state restriction, then city
            //Within these, check for restriction to not be like the previous beacon's location
            if !sameCountry && !sameState && !sameCity && userCountry != "" {
                
                
                //If likePrevious is false and previous exists, apply country to not be like previous
                //Else, apply a simple country restriction
                if !likePrevious && previous != nil {
                    
                    
                    //Ensure previous beacon's country is not nil
                    //If it is, apply a simple restriction
                    if previous!["countryCode"] != nil {
                        
                        query.whereKey("countryCode", notContainedIn: [userCountry, previous!["countryCode"]])
                    }
                    else {
                        
                        query.whereKey("countryCode", notEqualTo: userCountry)
                    }
                }
                else {
                    
                    query.whereKey("countryCode", notEqualTo: userCountry)
                }
                
            }
            else if sameCountry && !sameState && !sameCity && userState != "" {
                
                
                //If likePrevious is false and previous exists, apply state to not be like previous
                //Else, apply a simple state restriction
                if !likePrevious && previous != nil {
                    
                    
                    //Ensure previous beacon's state is not nil
                    //If it is, apply a simple restriction
                    if previous!["sentState"] != nil {
                        
                        query.whereKey("sentState", notContainedIn: [userState, previous!["sentState"]])
                    }
                    else {
                        
                        query.whereKey("sentState", notEqualTo: userState)
                    }
                }
                else {
                    
                    query.whereKey("sentState", notEqualTo: userState)
                }
                
            }
            else if sameCountry && sameState && !sameCity && userCity != "" {
                
                
                //If likePrevious is false and previous exists, apply city to not be like previous
                //Else, apply a simple city restriction
                if !likePrevious && previous != nil {
                    
                    
                    //Ensure previous beacon's city is not nil
                    //If it is, apply a simple restriction
                    if previous!["sentCity"] != nil {
                        
                        query.whereKey("sentCity", notContainedIn: [userCity, previous!["sentCity"]])
                    }
                    else {
                        
                        query.whereKey("sentCity", notEqualTo: userCity)
                    }
                }
                else {
                    
                    query.whereKey("sentCity", notEqualTo: userCity)
                }
            }
            
            
            
            //Query with above conditions
            query.findObjectsInBackgroundWithBlock({ (beacons, error) -> Void in
                
                
                if error != nil {
                    
                    //Display error and trigger flag
                    print("Photo query error: " + error!.description)
                    self.checkingForNewBeacons = false
                }
                else if beacons!.count < 1 {
                    
                    
                    //Either recurse the same method with different parameters or end search
                    //if there are zero results
                    if self.userToReceivePhotos > 0 {
                        
                        
                        //End search, only show if the showNoMoreBeaconsAlert flag is raised
                        if sameCountry && sameState && sameCity && likePrevious {
                            
                            
                            //Trigger flag
                            self.checkingForNewBeacons = false
                            print("Database empty.")
                            
                            //Let the user know that the database if user hasn't switched out already
                            if self.tabBarController?.selectedIndex == 1 && self.showNoMoreBeaconsAlert {
                                
                                self.showNoMoreBeaconsAlert = false
                                
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    let alert = UIAlertController(title: "Beacons To Come!", message: "Users will be sending beacons soon, check back to get them!", preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                })
                            }
                        }
                        else if !sameCountry && !sameState && !sameCity && !likePrevious {
                            
                            //Query for same country not like previous
                            self.checkForNewBeacons(true, sameState: false, sameCity: false, likePrevious: false)
                        }
                        else if sameCountry && !sameState && !sameCity && !likePrevious {
                            
                            //Query for same state not like previous
                            self.checkForNewBeacons(true, sameState: true, sameCity: false, likePrevious: false)
                        }
                        else if sameCountry && sameState && !sameCity && !likePrevious {
                            
                            //Query for same city not like previous
                            self.checkForNewBeacons(true, sameState: true, sameCity: true, likePrevious: false)
                        }
                        else if sameCountry && sameState && sameCity && !likePrevious {
                            
                            //Query for different country, state and city with no previous restriction
                            self.checkForNewBeacons(false, sameState: false, sameCity: false, likePrevious: true)
                        }
                        else if !sameCountry && !sameState && !sameCity && likePrevious {
                            
                            //Query for same country
                            self.checkForNewBeacons(true, sameState: false, sameCity: false, likePrevious: true)
                        }
                        else if sameCountry && !sameState && !sameCity && likePrevious {
                            
                            //Query for same state
                            self.checkForNewBeacons(true, sameState: true, sameCity: false, likePrevious: true)
                        }
                        else if sameCountry && sameState && !sameCity && likePrevious {
                            
                            //Query for same city
                            self.checkForNewBeacons(true, sameState: true, sameCity: true, likePrevious: true)
                        }
                    }
                }
                else {
                    
                    //Update objects and create a temporary array of them
                    var tempList = Array<PFObject>()
                    
                    for photoObject in beacons!{
                        
                        
                        //Mark unread
                        photoObject["unread"] = true
                        
                        //Attach receipt details to object
                        photoObject["receivedAt"] = NSDate()
                        photoObject["receivedBy"] = self.userID
                        photoObject["receivedCountry"] = self.userCountry
                        
                        //Add local parameters
                        photoObject["localTag"] = self.userID
                        photoObject["localCreationTag"] = NSDate()
                        
                        //Add geographic details
                        if self.userState != "" {
                            
                            photoObject["receivedState"] = self.userState
                        }
                        
                        if self.userCity != "" {
                            
                            photoObject["receivedCity"] = self.userCity
                        }
                        
                        if self.userDefaults.objectForKey("userLatitude") != nil   {
                            
                            photoObject["receivedLatitude"] = self.userLatitude
                            photoObject["receivedLongitude"] = self.userLongitude
                        }
                        
                        //Add object to userList
                        tempList.append(photoObject)
                        
                    }
                    
                    
                    //Add objects to user list
                    print("Adding new objects to userList")
                    
                    for object in tempList {
                        
                        //If objects haven't been added already, add, increment counter and save them
                        if !self.userList.contains(object) {
                            
                            self.userList.append(object)
                            
                            //Increment how much user receives
                            userReceivedPhotos += 1
                            
                            //Save object to database
                            print("Saving object!")
                            object.saveInBackgroundWithBlock({ (saved, error) -> Void in
                                
                                if error != nil {
                                    print("Error saving object to DB: \(error)")
                                }
                                else if saved {
                                    print("Saved object!")
                                }
                                else if !saved {
                                    print("Photo not saved")
                                }
                            })
                        }
                    }
                    
                    print("Reloading table after new objects")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        //Reload table
                        self.tableView.reloadData()
                        
                        //Show swipe beacon tutorial view
                        self.showTutorialTapBeaconView()
                        
                        //Save user list
                        print("Saving user list")
                        self.saveUserList()
                        
                        //Reset user photos to zero once photos are retreived
                        print("Resetting user photos")
                        self.userToReceivePhotos -= userReceivedPhotos
                        self.userDefaults.setInteger(self.userToReceivePhotos, forKey: "userToReceivePhotos")
                        
                    })
                    
                    //Reset flag
                    self.checkingForNewBeacons = false
                }
                
                
                //Stop refreshing
                if !self.checkingForNewBeacons && !self.checkingForReplyBeacons {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.refreshControl!.endRefreshing()
                    })
                }
            })
        }
        else {
            
            //Stop refreshing
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                print("Ending")
                self.checkingForNewBeacons = false
                if !self.checkingForReplyBeacons {
                    
                    self.refreshControl!.endRefreshing()
                }
            })
        }
        
    }
    
    
    internal func checkForReplyBeacons() {
        
        
        //Trigger flag
        print("checkForReplyBeacons")
        checkingForReplyBeacons = true
        
        //Get replies that belong to user and haven't been received
        let query = PFQuery(className:"photo")
        query.whereKeyExists("photo")
        query.whereKey("replyTo", equalTo: userID)
        query.whereKeyDoesNotExist("receivedBy")
        query.orderByDescending("createdAt")
        
        
        query.findObjectsInBackgroundWithBlock { (beacons, error) in
            
            if error != nil {
                
                //Display error
                print("Error getting reply beacons: \(error)")
            }
            else if beacons!.count > 0 {
                
                //Update objects and create a temporary array of them
                var tempList = Array<PFObject>()
                
                for beacon in beacons!{
                    
                    
                    //Mark unread
                    beacon["unread"] = true
                    
                    //Attach receipt details to object
                    beacon["receivedAt"] = NSDate()
                    beacon["receivedBy"] = self.userID
                    beacon["receivedCountry"] = self.userCountry
                    
                    //Add local parameters
                    beacon["localTag"] = self.userID
                    beacon["localCreationTag"] = NSDate()
                    
                    //Add geographic details
                    if self.userState != "" {
                        
                        beacon["receivedState"] = self.userState
                    }
                    
                    if self.userCity != "" {
                        
                        beacon["receivedCity"] = self.userCity
                    }
                    
                    if self.userDefaults.objectForKey("userLatitude") != nil   {
                        
                        beacon["receivedLatitude"] = self.userLatitude
                        beacon["receivedLongitude"] = self.userLongitude
                    }
                    
                    //Add object to userList
                    tempList.append(beacon)
                    
                }
                
                
                //Add objects to user list
                print("Adding new objects to userList")
                
                for object in tempList {
                    
                    //If objects haven't been added already, add,and save them
                    if !self.userList.contains(object) {
                        
                        self.userList.append(object)
                        
                        //Save object to database
                        print("Saving object!")
                        object.saveInBackgroundWithBlock({ (saved, error) -> Void in
                            
                            if error != nil {
                                print("Error saving object to DB: \(error)")
                            }
                            else if saved {
                                print("Saved object!")
                            }
                            else if !saved {
                                print("Photo not saved")
                            }
                        })
                    }
                }
                
                print("Reloading table after new objects")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Reload table
                    self.tableView.reloadData()
                    
                    //Show swipe beacon tutorial view
                    self.showTutorialTapBeaconView()
                    
                    //Save user list
                    print("Saving user list")
                    self.saveUserList()
                })
            }
            
            
            //Stop refreshing
            self.checkingForReplyBeacons = false
            
            if !self.checkingForNewBeacons {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.refreshControl!.endRefreshing()
                })
            }
        }
    }
    

    

    @IBAction func refreshControl(sender: AnyObject) {
        
        //Enable no more beacons alert, refresh data and reload table within that function
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
            self.updateUserList()
        }
    }


    internal func initializeRefreshControl() {
        
        
        //Remove existing views
        for subview in refreshControl!.subviews {

            subview.removeFromSuperview()
        }
        
        //Add custom views
        beaconRefresh = BeaconRefresh(frame: (refreshControl?.bounds)!)
        refreshControl!.addSubview(beaconRefresh)

        //Set background color
        refreshControl!.backgroundColor = refreshBackgroundColor
        
        //Add target
        self.refreshControl!.addTarget(self, action: #selector(refreshNeeded), forControlEvents: UIControlEvents.ValueChanged)

    }
    
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //Get ratio of distance pulled and update the refresh control accordingly
        let pullDistance = max(0.0, -scrollView.contentOffset.y)
        if scrollView.contentOffset.y == 0.0 && !refreshControl!.refreshing && beaconRefresh.isAnimating {
            
            //Stop animating if done refreshing and the beacon is still animating
            beaconRefresh.stopAnimating()
        }
        if pullDistance <= 100.0 && !refreshControl!.refreshing && !beaconRefresh.isAnimating {
            
            //Update views
            let pullMax = min(max(pullDistance, 0.0), refreshControl!.bounds.height)
            beaconRefresh.updateViews(pullMax)
        }
    }
    
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //Refresh table
        if refreshControl!.refreshing {
            
            updateUserList()
        }
    }
    
    
    internal func refreshNeeded() {
        
        //Begin animation and set flag to refresh
        print("starting animation")
        self.showNoMoreBeaconsAlert = true
        beaconRefresh.startAnimating()
    }
    
    
    
    
    internal override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        
        //Handle the table if empty
        if userList.count > 0 {
            
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            self.tableView.backgroundView = nil
            return 1
        }
        else {
            
            
            //Display a message when the table is empty
            let messageLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            
            messageLabel.text = "No beacons received yet. Go to the camera and take a beacon!";
            messageLabel.textColor = UIColor.darkGrayColor()
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = NSTextAlignment.Center
            messageLabel.font = UIFont.systemFontOfSize(14)
            messageLabel.sizeToFit()
            
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }
        
        return 0
    }
    
    
    internal override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        print("cellForRowAtIndexPath")
        //Initialize variables:
        //Array is printed backwards so userListLength is initialized
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let titleView = cell.viewWithTag(1) as! UILabel
        let subTitleView = cell.viewWithTag(2) as! UILabel
        let imageView = cell.viewWithTag(5) as! UIImageView
        let imageBackground = cell.viewWithTag(6) as! CountryBackground
        let slideMapIndicator = cell.viewWithTag(3) as! UIImageView
        let slideReplyIndicator = cell.viewWithTag(4) as! UIImageView
        
        let userListIndex = userList.count - 1 - indexPath.row
        let date = userList[userListIndex]["receivedAt"] as? NSDate
        let countryCode = userList[userListIndex]["countryCode"] as? String
        
        
        //Declare geographic data
        let country = countryTable.getCountryName(countryCode!)
        let state = userList[userListIndex]["sentState"] as? String
        let city = userList[userListIndex]["sentCity"] as? String
        
        
        //Configure image sliding and action
        let pan = UIPanGestureRecognizer(target: self, action: #selector(detectPan(_:)))
        imageBackground.addGestureRecognizer(pan)
        
        
        //Add the country image to its background
        if userList[userListIndex]["sentBy"] as! String == userID && userList[userListIndex]["receivedBy"] == nil {
            
            //Set background color
            imageBackground.changeBackgroundColor(sendingColor.CGColor)
            imageBackground.setProgress(0.6)
            
            //Configure subtext
            let sendingStatus = userList[userListIndex]["sendingStatus"] as? String
            
            if sendingStatus == nil {
                
                subTitleView.text = "Sending..."
                userList[userListIndex]["isAnimating"] = true
                imageBackground.startAnimating()
            }
            else {
                 
                subTitleView.text = "Ready To Send"
                imageBackground.stopAnimating()
            }
        }
        else {
            
            
            //Set background color  & kill any animations
            if userList[userListIndex]["replyTo"] != nil {
                imageBackground.changeBackgroundColor(replyColor.CGColor)
            }
            else {
                imageBackground.changeBackgroundColor(defaultColor.CGColor)
            }
            userList[userListIndex].removeObjectForKey("isAnimating")
            imageBackground.stopAnimating()
            
            
            //Configure time left for photo
            let timeString = timeSinceDate(date!, numericDates: true)
            
            if withinTime(date!) {
                imageBackground.setProgress(getTimeFraction(date!))
            }
            else {
                imageBackground.noProgress()
            }
            
            
            //Configure subtext
            subTitleView.textColor = UIColor(red: 166.0/255.0, green: 166.0/255.0, blue: 166.0/255.0, alpha: 1.0)
            subTitleView.text = String(timeString)
            
            //Configure slide map indicator
            slideMapIndicator.image = UIImage(named: "Globe")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            slideMapIndicator.tintColor = UIColor.lightGrayColor()
            
            
            //Configure slide reply indicator
            slideReplyIndicator.image = UIImage(named: "Reply")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            slideReplyIndicator.tintColor = UIColor.lightGrayColor()
        }
        
        
        //Configure text & map image
        //Account for states if country is USA
        imageView.image = countryTable.getCountryImage(countryCode!).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        if state != nil && countryCode == "us" {
            
            //State variable is a state code
            if state!.characters.count == 2 {
                
                titleView.text = (countryTable.getStateName(state!.lowercaseString) + ", " + country)
                
                
                //Set image for state if it exists. If not, use country image
                if countryTable.getStateImage(state!.lowercaseString) != UIImage(named: "Countries/Unknown/128.png"){
                    
                    imageView.image = countryTable.getStateImage(state!.lowercaseString).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                }
            }
            //State variable is not a state code
            else {
                
                let stateCode = countryTable.getStateCode(state!)
                if stateCode != "Unknown" {
                    
                    titleView.text = state! + ", " + country
                    imageView.image = countryTable.getStateImage(stateCode).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                }
                else if city != nil {
                    
                    titleView.text = city! + ", " + country
                }
                else {
                    
                    titleView.text = country
                }
            }
        }
        //Check if city variable is present
        else if city != nil && city != "Unknown" {
            
            titleView.text = city! + ", " + country
        }
        //Configure for only country variable
        else {
            
            titleView.text = country
        }
        
        
        //Configure unread or read. Bold for unread and medium for read.
        if userList[userListIndex]["unread"] != nil && withinTime(date!) {
            
            titleView.font = UIFont.systemFontOfSize(titleView.font.pointSize, weight: UIFontWeightBold)
        }
        else {
            
            titleView.font = UIFont.systemFontOfSize(titleView.font.pointSize, weight: UIFontWeightMedium)
        }
        
        return cell
    }
    
    
    internal override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return userList.count
    }
    
    
    internal override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        
        //Remove report beacon tutorial view
        removeTutorialReportBeaconView()
        
        
        //Get user list information
        let userListLength = self.userList.count - 1
        let toBeSent = userList[userListLength - indexPath.row]["sentBy"] as! String == userID && userList[userListLength - indexPath.row]["receivedBy"] == nil
        
        
        //If photo is not to be sent, check if expired
        if !toBeSent {
            
            let date = userList[userListLength - indexPath.row]["receivedAt"] as! NSDate
            
            if withinTime(date) {
                
                return true
            }
        }
        return false
    }
    
    
    internal override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        
        //Declare spam button
        let spam = UITableViewRowAction(style: .Normal, title: "Report") { (action, index) -> Void in
            
            
            //Get beacon from array
            let userListLength = self.userList.count - 1
            let object = self.userList[userListLength - indexPath.row]
            
            
            //Show alert controller to ensure report action
            let alert = UIAlertController(title: "", message: "Are you sure you want to report this beacon? Wrongful reporting will count against you.", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            //Add confirmation button
            alert.addAction(UIAlertAction(title: "Report", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                
                
                //Update object and - if applicable - user in background
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                    
                    //Update object
                    print("Reported")
                    object.setObject(true, forKey: "spam")
                    object.saveInBackground()
                    
                    //Run method to check if user ban-worthy
                    self.banUser(object.objectForKey("sentBy") as! String)
                })
            }))
            
            //Add cancel button
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            //Present alert controller
            self.presentViewController(alert, animated: true, completion: nil)
            
            //End editing view
            tableView.setEditing(false, animated: true)
            
        }
        spam.backgroundColor = UIColor(red: 254.0/255.0, green: 90.0/255.0, blue: 93.0/255.0, alpha: 1)
        
        return [spam]
    }
    
    
    internal override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
        tableView.reloadData()
        saveUserList()
    }
    
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        //Deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        //Flip index to access correct array element & check time constraint of photos
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        let userListIndex = userList.count - 1 - indexPath.row
        
        
        //If photo to be sent by user, send.
        //Else if row is within time, display photo or video. 
        //Else, animate.
        if userList[userListIndex]["sentBy"] as! String == userID && userList[userListIndex]["receivedBy"] == nil {
            
            print("Send photo")
            sendUnsentPhoto(userList[userListIndex], updateUserList: true)
        }
        else if withinTime(userList[userListIndex].objectForKey("receivedAt") as! NSDate) {
            
            
            print("Show photo")
            //Hide tap beacon tutorial view
            removeTutorialTapBeaconView()
            
            //Start UI animation
            let countryBackground = cell.viewWithTag(6) as! CountryBackground
            countryBackground.startAnimating()
            
            
            
            //Set audio session depending on user being on a call or not
            if CTCallCenter().currentCalls != nil {
                
                changeAudioSession(AVAudioSessionCategoryAmbient)
            }
            else {
                
                changeAudioSession(AVAudioSessionCategoryPlayAndRecord)
            }
            
            
            //Initialize superior VC variables
            let grandparent = self.parentViewController?.parentViewController?.parentViewController as! SnapController
            grandparent.snap.image = nil
            
            //Get variable to know if media is a video
            var isVideo = false
            if userList[userListIndex]["isVideo"] != nil {
                
                isVideo = userList[userListIndex]["isVideo"] as! BooleanLiteralType
            }
            
            //Get PFFile
            let objectToDisplay = userList[userListIndex]["photo"] as! PFFile
            
            
            //Handle for videos and pictures uniqeuly
            if isVideo {
                
                objectToDisplay.getDataInBackgroundWithBlock({ (videoData, videoError) -> Void in
                    
                    if videoError != nil {
                        print("Error converting video: \(videoError)")
                    }
                    else {
                        
                        //Write video to a file
                        videoData?.writeToFile(self.videoPath, atomically: true)
                        
                        //Initialize movie layer
                        print("Initilizing video player")
                        let player = AVPlayer(URL: NSURL(fileURLWithPath: self.videoPath))
                        grandparent.moviePlayer = AVPlayerLayer(player: player)
                        
                        //Set video gravity
                        grandparent.moviePlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        
                        //Set close function
                        NSNotificationCenter.defaultCenter().addObserver(self,
                            selector: #selector(self.closeVideo),
                            name: AVPlayerItemDidPlayToEndTimeNotification,
                            object: grandparent.moviePlayer.player!.currentItem)
                        
                        
                        
                        //Update UI in main queue
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            //Show video to user if user is still on the user list tab
                            if self.tabBarController?.selectedIndex == 1 {
                                
                                print("Adding video player")
                                countryBackground.stopAnimating()
                                
                                if !grandparent.hideStatusBar {
                                    
                                    grandparent.toggleStatusBar()
                                }
                                grandparent.snap.userInteractionEnabled = true
                                grandparent.snap.backgroundColor = UIColor.blackColor()
                                grandparent.moviePlayer.frame = grandparent.snap.bounds
                                grandparent.snap.layer.addSublayer(grandparent.moviePlayer)
                                grandparent.snap.alpha = 1
                                
                                //Bring timer to front
                                grandparent.snap.bringSubviewToFront(grandparent.snapTimer)
                                
                                //Play video
                                grandparent.moviePlayer.player!.play()
                                
                                //Start timer
                                grandparent.snapTimer.startTimer(player.currentItem!.asset.duration)
                                
                                
                                
                                //Reset cell to read if currently unread
                                if self.userList[userListIndex]["unread"] != nil {
                                    
                                    let titleView = cell.viewWithTag(1) as! UILabel
                                    self.userList[userListIndex].removeObjectForKey("unread")
                                    self.userList[userListIndex].pinInBackground()
                                    
                                    titleView.font = UIFont.systemFontOfSize(titleView.font.pointSize, weight: UIFontWeightMedium)
                                }
                                
                                //Show swipe beacon tutorial view
                                self.showTutorialSwipeBeaconView()

                            }
                        })
                    }
                })
            }
            else {
                
                grandparent.snap.file = objectToDisplay
                
                grandparent.snap.loadInBackground { (photoData, photoConvError) -> Void in
                    
                    //Stop animation
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        countryBackground.stopAnimating()
                    })
                    
                    if photoConvError != nil {
                        
                        print("Error converting photo from file: " + photoConvError!.description)
                    }
                    else {
                        
                        //Stop animation
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            //Show photo to user if user is still on user list tab
                            if self.tabBarController?.selectedIndex == 1 {
                                
                                //Decode and display image for user
                                if !grandparent.hideStatusBar {
                                    
                                    grandparent.toggleStatusBar()
                                }
                                
                                grandparent.snap.userInteractionEnabled = true
                                
                                //Hide timer
                                grandparent.snapTimer.alpha = 0
                                grandparent.snap.alpha = 1
                                
                                
                                //Reset cell to read if currently unread
                                if self.userList[userListIndex]["unread"] != nil {
                                    
                                    let titleView = cell.viewWithTag(1) as! UILabel
                                    self.userList[userListIndex].removeObjectForKey("unread")
                                    self.userList[userListIndex].pinInBackground()
                                    
                                    titleView.font = UIFont.systemFontOfSize(titleView.font.pointSize, weight: UIFontWeightMedium)
                                }
                                
                                //Show swipe beacon tutorial view
                                self.showTutorialSwipeBeaconView()

                            }
                        })
                    }
                }
            }
            
        }
        //If photo not within time, display cell bounce animation
        else {
            
            print("Snap expired")
            
            //Get cell views
            let cell = tableView.cellForRowAtIndexPath(indexPath)!
            let titleView = cell.viewWithTag(1) as! UILabel
            let subTitleView = cell.viewWithTag(2) as! UILabel
            let imageView = cell.viewWithTag(5) as! UIImageView
            
            //Establish required variables
            let textIntensity = CGFloat(15)
            let duration = 0.6
            
            
            //Animate country image view spin
            UIView.animateWithDuration(duration/2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                
                
                imageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
                
                }, completion: { (Bool) in
                    
                    //Change image bounds to original upon completion
                    UIView.animateWithDuration(duration/2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                        
                        
                        imageView.transform = CGAffineTransformMakeRotation(2 * CGFloat(M_PI))
                        
                        }, completion: nil)
            })
            
            
            //Animate text views' glide
            UIView.animateWithDuration(duration/4, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: {
                
                titleView.center = CGPoint(x: titleView.center.x + textIntensity, y: titleView.center.y)
                subTitleView.center = CGPoint(x: subTitleView.center.x - textIntensity/3, y: subTitleView.center.y)
                
                }, completion: { (Bool) in
                    
                    //Move text views back
                    UIView.animateWithDuration(duration + duration/3, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                        
                        
                        titleView.center = CGPoint(x: titleView.center.x - textIntensity, y: titleView.center.y)
                        subTitleView.center = CGPoint(x: subTitleView.center.x + textIntensity/3, y: subTitleView.center.y)
                        
                        }, completion: nil)
            })
        }
    }
    
    
    
    
    internal func resumeAnimations() {
        
        print("resumeCellAnimations")
        if tableView != nil {
            
            for indexPath in tableView.indexPathsForVisibleRows! {
                
                //Animate cell if it is supposed to be animating
                let userListIndex = userList.count - 1 - indexPath.row
                
                if let animating = userList[userListIndex].objectForKey("isAnimating") as? Bool {
                    
                    if animating {
                        
                        print("resuming cell")
                        let cell = tableView.cellForRowAtIndexPath(indexPath)
                        let countryBackground = cell!.viewWithTag(6) as! CountryBackground
                        countryBackground.startAnimating()
                    }
                }
            }
        }
    }
    
    
    internal func banUser(sentBy: String) {
        
        
        
        //Count rows reported belonging to user
        let countQuery = PFQuery(className: "photo")
        countQuery.whereKey("sentBy", equalTo: sentBy)
        countQuery.whereKey("spam", equalTo: true)
        countQuery.findObjectsInBackgroundWithBlock { (rows, rowsError) -> Void in
            
            //Display error getting row count
            if rowsError != nil {
                print("Error retrieving row count: \(rowsError)")
            }
            //Ban user if this is the third strike
            else if rows!.count > 2 {
                
                //Query to ban user
                let query = PFQuery(className: "users")
                query.whereKey("userID", equalTo: sentBy)
                query.getFirstObjectInBackgroundWithBlock({ (userObject, userError) -> Void in
                    
                    if userError != nil {
                        
                        //Display error getting result
                        print("Error retreiving user: \(userError) ")
                    }
                    else if userObject == nil {
                        
                        //Print error getting user
                        print("Error retreiving user: User does not exist to mark as spam")
                    }
                    else {
                        
                        //Update banned flag for user in database
                        userObject!.setObject(true, forKey: "banned")
                        userObject!.saveInBackground()
                    }
                })
            }
        }
    }
    
    
    internal func loopTableVideo(notification: NSNotification) {
        
        //Loop video
        print("Looping table video")
        let player = notification.object as! AVPlayer
        player.currentItem?.seekToTime(kCMTimeZero)
        player.play()
    }
    
    
    internal func closeVideo() {
        
        let grandparent = self.parentViewController?.parentViewController?.parentViewController as! SnapController
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            //Send close function
            grandparent.closeBeacon()
            
            //Only toggle if status bar hidden
            if grandparent.hideStatusBar {
                
                grandparent.toggleStatusBar()
            }
        })
        
        //Clear temporary file
        clearLocalFile(videoPath)
    }
    
    
    
    
    internal func updateUserPhotos() {
    
        self.userToReceivePhotos += 1
        self.userDefaults.setInteger(self.userToReceivePhotos, forKey: "userToReceivePhotos")
        print("Saved userToReceivePhotos")
    }
    
    
    internal func clearLocalFile(filePath: String) {
        
        do {
            
            if fileManager.fileExistsAtPath(filePath) {
                
                try fileManager.removeItemAtPath(filePath)
            }
        }
        catch let error as NSError {
            
            print("Error deleting video: \(error)")
        }
    }
    
    
    internal func detectPan(recognizer: UIPanGestureRecognizer) {
        
        
        //Check if view is the Country Background class
        let countryObject = recognizer.view as! CountryBackground
        let translation = recognizer.translationInView(recognizer.view!.superview)
        let cell = recognizer.view!.superview!.superview as! UITableViewCell
        let slideMapIndicator = cell.viewWithTag(3) as! UIImageView
        let slideReplyIndicator = cell.viewWithTag(4) as! UIImageView
        let countryBackground = cell.viewWithTag(6) as! CountryBackground
        let threshold = CGFloat(30)
        
        
        switch recognizer.state {
            
            
        case .Began:
            
            
            //Save original center
            print("Got country's original point")
            if countryCenter == CGPoint(x: 0, y: 0) {
                
                countryCenter = countryObject.center
            }
            
            //Hide all other cell subviews & obtain country name for potential map query
            //Since content view is the direct subview layer, we have to first go into that
            for subview in cell.subviews[0].subviews {
                
                //Ensure that the subview is not the image, its background, or the map label
                if subview.tag != 3 && subview.tag != 4 && subview.tag != 5 && subview.tag != 6 {
                    
                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        
                        subview.alpha = 0
                    })
                }
                //Show map label
                else if subview.tag == 3 || subview.tag == 4 {
                    
                    let view = subview as! UIImageView
                    
                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        
                        view.alpha = 1
                    })
                }
            }
            
        case .Ended:
            
            
            //Calculate distance fraction
            let distance = translation.x
            
            //If moved to the map, go to map and show country.
            //Else if moved to the reply, go to the camera.
            if countryCenter.x + distance > slideMapIndicator.center.x - (threshold * 2) {
                
                
                let index = tableView.indexPathForCell(cell)!.row
                let userListIndex = userList.count - index - 1
                let geoPoint = userList[userListIndex].valueForKey("sentFrom") as! PFGeoPoint
                let sentCountry = userList[userListIndex].valueForKey("countryCode") as? String
                
                if !(geoPoint.latitude == 0.0 && geoPoint.longitude == 0.0) {
                    
                    //Since location exists, go to the location
                    let location = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                    segueToMap(location, country: sentCountry)
                }
                else {
                    
                    //Or else, just go to the map
                    self.tabBarController?.selectedIndex = 2
                }
                
                //Reset visible cells to default values
                resetVisibleCells()
                
            }
            else if countryCenter.x + distance > slideReplyIndicator.center.x - threshold && countryCenter.x + distance < slideReplyIndicator.center.x + threshold/2 {
                
                //Necessary variables
                let index = tableView.indexPathForCell(cell)!.row
                let userListIndex = userList.count - index - 1
                let replyToUser = userList[userListIndex].valueForKey("sentBy") as! String
                let replyImage = countryBackground.getImage()
                
                //Segue to camera with details
                segueToCamera(replyToUser, replyImage: replyImage)
            }
            
            
            //Move country back and bring back elements
            print("Moving country back")
            countryObject.changeToCountryMode(true)
            
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                
                //Move object first
                countryObject.center.x = self.countryCenter.x
                
                //Since content view is the direct subview layer, we have to first go into that
                for subview in cell.subviews[0].subviews {
                    
                    //Ensure that the subview is not the image, its background or the map label
                    if subview.tag != 3 && subview.tag != 4 && subview.tag != 5 && subview.tag != 6 {
                        
                        subview.alpha = 1
                    }
                        //Hide map label
                    else if subview.tag == 3 || subview.tag == 4 {
 
                        subview.alpha = 0
                        
                    }
                }
                
                }, completion: nil)
            
            
        case .Cancelled:
            
            
            print("Country swipe cancelled")
            //Move object first
            countryObject.center.x = self.countryCenter.x
            
            //Since content view is the direct subview layer, we have to first go into that
            for subview in cell.subviews[0].subviews {
                
                //Ensure that the subview is not the image, its background or the map label
                if subview.tag != 3 && subview.tag != 4 && subview.tag != 5 && subview.tag != 6 {
                    
                    subview.alpha = 1
                }
                    //Hide map label
                else if subview.tag == 3 || subview.tag == 4 {
                    
                    let view = subview as! UIImageView
                    view.alpha = 0
                }
            }
            
        default:
            
            
            //Calculate distance fraction
            let distance = translation.x
            
            
            if countryCenter.x + distance > slideMapIndicator.center.x - (threshold * 2) {
                
                
                //Change to map indicator view and hide country view continuously
                countryBackground.changeToMapMode()
                
                
                //If indicator is inactive, turn it active
                if slideMapIndicator.tintColor == UIColor.lightGrayColor() {
                    
                    UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                        
                        
                        //Move country to map indicator view
                        if countryObject.center.x != slideMapIndicator.center.x {
                            
                            countryObject.center = CGPoint(x: slideMapIndicator.center.x, y: countryObject.center.y)
                        }
                        
                        //Change reply indicator to default color
                        slideMapIndicator.tintColor = self.defaultColor
                        
                        
                        //If slide reply indicator is not gray, turn it to gray
                        if slideReplyIndicator.tintColor != UIColor.lightGrayColor() {
                            
                            //Bring country back to panning and change tint
                            slideReplyIndicator.tintColor = UIColor.lightGrayColor()
                        }
                        
                        }, completion: nil)
                }
                
            }
            else if countryCenter.x + distance > slideReplyIndicator.center.x - threshold && countryCenter.x + distance < slideReplyIndicator.center.x + threshold/2 {
                
                
                //Change to reply indicator view and hide country view continuously
                countryBackground.changeToReplyMode(true)
                
                
                //If indicator is inactive, turn it active
                if slideReplyIndicator.tintColor == UIColor.lightGrayColor() {
                    
                    UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                        
                        
                        //Move country to reply indicator view
                        if countryObject.center.x != slideReplyIndicator.center.x {
                            
                            countryObject.center = CGPoint(x: slideReplyIndicator.center.x, y: countryObject.center.y)
                        }
                        
                        //Change reply indicator to default color
                        slideReplyIndicator.tintColor = self.defaultColor
                        
                        
                        //If slide map indicator is not gray, turn it to gray
                        if slideMapIndicator.tintColor != UIColor.lightGrayColor() {
                            
                            //Bring country back to panning and change tint
                            slideMapIndicator.tintColor = UIColor.lightGrayColor()
                        }
                    }, completion: nil)
                }
                
            }
            else if countryCenter.x + distance < slideReplyIndicator.center.x - threshold {
                
                
                //Change to country mode
                countryBackground.changeToCountryMode(true)
                
                //Move country as per slide. Animate if it's coming back into panning control
                print("turning gray color")
                if countryObject.center.x == slideMapIndicator.center.x || countryObject.center.x == slideReplyIndicator.center.x {
                    
                    UIView.animateWithDuration(0.2, animations: {
                        
                        countryObject.center.x = translation.x + self.countryCenter.x
                    })
                }
                else {
                    
                    countryObject.center.x = translation.x + self.countryCenter.x
                }
                
                
                
                //If slide reply indicator is not gray, turn it to gray
                if slideReplyIndicator.tintColor != UIColor.lightGrayColor() {
                    
                    UIView.animateWithDuration(0.3, animations: {
                        
                        //Bring country back to panning and change tint
                        slideReplyIndicator.tintColor = UIColor.lightGrayColor()
                    })
                }
                
                //If slide map indicator is not gray, turn it to gray
                if slideMapIndicator.tintColor != UIColor.lightGrayColor() {
                    
                    UIView.animateWithDuration(0.3, animations: {
                        
                        //Bring country back to panning and change tint
                        slideMapIndicator.tintColor = UIColor.lightGrayColor()
                    })
                }
            }
        }
    }
    
    
    internal func resetVisibleCells() {
        
        
        for cell in tableView.visibleCells {
            
            //Since content view is the direct subview layer, we have to first go into that
            for subview in cell.subviews[0].subviews {
                
                //Ensure that the subview is not the image, its background or the map label
                if subview.tag != 3 && subview.tag != 4 && subview.tag != 5 && subview.tag != 6 {
                    
                    subview.alpha = 1
                }
                //Move the country object back and reset subviews
                else if subview.tag == 6 {
                    
                    let country = subview as! CountryBackground
                    country.center.x = self.countryCenter.x
                    country.changeToCountryMode(false)
                }
                //Hide map label
                else if subview.tag == 3 || subview.tag == 4 {
                    
                    let view = subview as! UIImageView
                    view.alpha = 0
                    
                }
            }
        }
    
    }
    
    
    internal func reloadVisibleRows() {
        
        print("reloadVisibleRows")
        if self.tableView != nil {
            
            self.tableView.reloadRowsAtIndexPaths(self.tableView.indexPathsForVisibleRows!, withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    
    internal func getPoliticalDetails(locGeoPoint: PFGeoPoint, photoObject: PFObject) {
        
        
        //Initialize coordinate details
        print("getPoliticalDetails")
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)
        
        //Get political information, update the object and send it to the database
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, locationError) -> Void in
            
            if locationError != nil {
                
                //Update cell to let user know sending failed
                print("Reverse geocoder error: " + locationError!.description)
                photoObject.setObject("Ready", forKey: "sendingStatus")
                photoObject.removeObjectForKey("isAnimating")
                self.sendingList.removeAtIndex(self.sendingList.indexOf(photoObject)!)
                let cell = self.getCellForObject(photoObject)
                let countryBackground = cell?.viewWithTag(6) as? CountryBackground
                let subTitleView = cell?.viewWithTag(2) as? UILabel
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if cell != nil {
                        if subTitleView!.text == "Sending..." {
                            subTitleView!.text = "Sending failed"
                        }
                        countryBackground!.stopAnimating()
                    }
                })
            }
            else if placemarks!.count > 0 {
                
                //Get and save object's country, state & city
                print("Geo location country code: \(placemarks![0].locality), \(placemarks![0].administrativeArea), \(placemarks![0].ISOcountryCode!)")
                photoObject["countryCode"] = placemarks![0].ISOcountryCode!.lowercaseString
                
                
                if placemarks![0].administrativeArea != nil {
                    
                    photoObject["sentState"]  = placemarks![0].administrativeArea!
                }
                
                if placemarks![0].locality != nil {
                    
                     photoObject["sentCity"]  = placemarks![0].locality!
                }
                
                
                //If object exists in user list, refresh its cell in the table
                if self.userList.contains(photoObject) {
                    
                    let cell = self.getCellForObject(photoObject)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        if cell != nil {
                            
                            if self.tableView.visibleCells.contains(cell!) {
                                
                                self.tableView.reloadRowsAtIndexPaths(self.tableView.indexPathsForVisibleRows!, withRowAnimation: UITableViewRowAnimation.None)
                            }
                        }
                    })
                }
                
                //Save object locally, then send to database
                photoObject.pinInBackgroundWithBlock({ (saved, error) -> Void in
                    
                    if error != nil {
                        
                        //Let user know the sending process failed
                        print("Error saving location updated object: \(error)")
                        photoObject.setObject("Ready", forKey: "sendingStatus")
                        photoObject.removeObjectForKey("isAnimating")
                        self.sendingList.removeAtIndex(self.sendingList.indexOf(photoObject)!)
                        let cell = self.getCellForObject(photoObject)
                        let countryBackground = cell?.viewWithTag(6) as? CountryBackground
                        let subTitleView = cell?.viewWithTag(2) as? UILabel
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            if cell != nil {
                                if subTitleView!.text == "Sending..." {
                                    subTitleView!.text = "Sending failed"
                                }
                                countryBackground!.stopAnimating()
                            }
                        })
                    }
                    else if saved {
                        
                        //Try sending photo to database with the updated location
                        self.sendPhotoToDatabase(photoObject, updateUserList: true)
                    }
                })
            }
            else {
                
                print("Problem with the data received from geocoder")
                //Try sending photo to database without location
                self.sendPhotoToDatabase(photoObject, updateUserList: true)
            }
        }
    }
    
    
    
    
    internal func showTutorialTapBeaconView() {
        
        
        //Show label if the user default is nil
        print("showTutorialTapBeaconView")
        if userDefaults.objectForKey("tutorialTapBeacon") == nil && !tutorialTapBeaconViewShown {
            
            let heading = "You Got A Beacon!"
            let text = "Tap to open it!"
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(210)
                self.tutorialTapBeaconView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2, y: self.tableView.frame.minY + self.tableView.rowHeight + 15, width: width, height: height))
                self.tutorialTapBeaconView.pointTriangleUp()
                self.tutorialTapBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialTapBeaconView)
                self.view.bringSubviewToFront(self.tutorialTapBeaconView)
                self.tutorialTapBeaconViewShown = true
            })
        }
    }
    
    
    internal func removeTutorialTapBeaconView() {
        
        //Remove send beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialTapBeacon") == nil && tutorialTapBeaconViewShown {
            
            tutorialTapBeaconView.removeView("tutorialTapBeacon")
            tutorialTapBeaconViewShown = false
        }
    }
    
    
    internal func showTutorialSwipeBeaconView() {
        
        
        //Show label if the user default is nil
        print("showTutorialSwipeBeaconView")
        if userDefaults.objectForKey("tutorialSwipeBeacon") == nil && !tutorialSwipeBeaconViewShown {
            
            let heading = "Take It To The Map!"
            let text = "Swipe the country to the right\nto see it on the map"
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(210)
                self.tutorialSwipeBeaconView = TutorialView(frame: CGRect(x: 20, y: self.tableView.frame.minY + self.tableView.rowHeight + 15, width: width, height: height))
                self.tutorialSwipeBeaconView.pointTriangleUp()
                self.tutorialSwipeBeaconView.moveTriangle(CGPoint(x: -width/2 + 30, y: 0))
                self.tutorialSwipeBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialSwipeBeaconView)
                self.view.bringSubviewToFront(self.tutorialSwipeBeaconView)
                self.tutorialSwipeBeaconViewShown = true
            })
        }
        else {
            
            //Show beacon time tutorial view
            showTutorialBeaconTimeView()
        }
    }
    
    
    internal func removeTutorialSwipeBeaconView() {
        
        //Remove send beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialSwipeBeacon") == nil && tutorialSwipeBeaconViewShown {
            
            tutorialSwipeBeaconView.removeView("tutorialSwipeBeacon")
            tutorialSwipeBeaconViewShown = false
        }
    }
    
    
    internal func showTutorialBeaconTimeView() {
        
        
        //Show label if the user default is nil
        print("showTutorialBeaconTimeView")
        if userDefaults.objectForKey("tutorialBeaconTime") == nil && !tutorialBeaconTimeViewShown {
            
            let heading = "Time Left"
            let text = "You can see the beacon until\nthe circle disappears"
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(200)
                self.tutorialBeaconTimeView = TutorialView(frame: CGRect(x: 20, y: self.tableView.frame.minY + self.tableView.rowHeight + 15, width: width, height: height))
                self.tutorialBeaconTimeView.pointTriangleUp()
                self.tutorialBeaconTimeView.moveTriangle(CGPoint(x: -width/2 + 30, y: 0))
                self.tutorialBeaconTimeView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialBeaconTimeView)
                self.view.bringSubviewToFront(self.tutorialBeaconTimeView)
                self.tutorialBeaconTimeViewShown = true
                self.userDefaults.setBool(true, forKey: "tutorialBeaconTime")
                
            })
        }
        else {
            
            //Show report beacon tutorial view
            showTutorialReportBeaconView()
        }
    }
    
    
    internal func removeTutorialBeaconTimeView() {
        
        //Remove send beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialBeaconTime") != nil && tutorialBeaconTimeViewShown {
            
            tutorialBeaconTimeView.removeView("tutorialBeaconTime")
            tutorialBeaconTimeViewShown = false
        }
    }
    
    
    internal func showTutorialReportBeaconView() {
        
        
        //Show label if the user default is nil
        print("showTutorialReportBeaconView")
        if userDefaults.objectForKey("tutorialReportBeacon") == nil && !tutorialReportBeaconViewShown && !tutorialBeaconTimeViewShown {
            
            let heading = "Naughty Beacon?"
            let text = "Swipe left to report it."
            tutorialReportBeaconViewShown = true
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(210)
                self.tutorialReportBeaconView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2, y: self.tableView.frame.minY + self.tableView.rowHeight + 15, width: width, height: height))
                self.tutorialReportBeaconView.pointTriangleUp()
                self.tutorialReportBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialReportBeaconView)
                self.view.bringSubviewToFront(self.tutorialReportBeaconView)
            })
        }
    }
    
    
    internal func removeTutorialReportBeaconView() {
        
        //Remove send beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialReportBeacon") == nil && tutorialReportBeaconViewShown {
            
            tutorialReportBeaconView.removeView("tutorialReportBeacon")
            tutorialBeaconTimeViewShown = false
        }
    }
    
    
    
    
    internal func segueToCamera(replyToUser: String, replyImage: UIImage) {
        
        //Move to the camera
        tabBarController!.selectedIndex = 0
        let camera = tabBarController!.viewControllers![0] as! CameraController
        
        //Provide reply details
        camera.replyMode(replyToUser, replyImage: replyImage)
    }
    
    
    internal func segueToMap(location: CLLocationCoordinate2D, country: String?) {
        
        //Move to the map
        tabBarController!.selectedIndex = 2
        let map = tabBarController!.viewControllers![2] as! MapController
        
        //Switch control if current segment isn't "received"
        if map.beaconControl.selectedSegmentIndex != 0 {
            
            map.beaconControl.selectedSegmentIndex = 0
            map.beaconControlChanged(map.beaconControl)
        }
        
        //Pan to selected location
        map.goToCountry(location)
        
        
        //Remove swipe beacon tutorial view
        removeTutorialSwipeBeaconView()
        
        
        //If the country exists, outline the country
        if country != nil {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                
                map.getDetailsToDrawCountry(country!)
            }
        }
    }
    
    
    internal func segueToLogin() {
        
        //Segue to login screen
        print("Segue-ing")
        performSegueWithIdentifier("UserListToLoginSegue", sender: self)
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "UserListToLoginSegue" && segue.destinationViewController.isViewLoaded() {
            
            let loginController = segue.destinationViewController as! LoginController
            
            //Set buttons on appearance
            loginController.alertButton.alpha = 0
        }
    }
    
    
    
    
    internal func changeAudioSession(category: String) {
        
        //If audio session isn't already the new category, change it
        if AVAudioSession.sharedInstance().category != category {
            
            do {
                
                print("Changing session")
                try AVAudioSession.sharedInstance().setCategory(category, withOptions: [AVAudioSessionCategoryOptions.MixWithOthers, AVAudioSessionCategoryOptions.DefaultToSpeaker])
                AVAudioSession.sharedInstance()
                try AVAudioSession.sharedInstance().setActive(true)
            }
            catch let error as NSError { print("Error setting audio session category \(error)") }
        }
    }
    
        
    internal func withinTime(date: NSDate) -> BooleanLiteralType {
        
        //Get calendar and current date, compare it to given date
        let difference = calendar.components([.Day, .WeekOfYear, .Month, .Year], fromDate: date, toDate: NSDate(), options: [])
        
        //Compare all components of the difference to see if it's greater than 1 day
        if difference.year > 0 || difference.month > 0 || difference.weekOfYear > 0 || difference.day >= 1
        {
            return false
        }
        
        return true
    }
    
    
    internal func getTimeFraction(date: NSDate) -> Float {
        
        //Get calendar and current date, compare it to given date
        let difference = calendar.components([.Day, .Hour, .Minute], fromDate: date, toDate: NSDate(), options: [])
        let timeElapsed = (difference.day * 24 * 60) + (difference.hour * 60) + (difference.minute)
        
        //Return fraction of elapsed time over one day
        return (1.0 - Float(timeElapsed)/1440) * 0.98
        
    }
    
    
    internal func timeSinceDate(date:NSDate, numericDates:Bool) -> String {
        
        let now = NSDate()
        let earliest = now.earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:NSDateComponents = calendar.components([.Minute, .Hour, .Day, .WeekOfYear, .Month, .Year, .Second], fromDate: earliest, toDate: latest, options: [])
        
        if (components.year >= 2) {
            return "\(components.year) years ago"
        } else if (components.year >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month >= 2) {
            return "\(components.month) months ago"
        } else if (components.month >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear >= 2) {
            return "\(components.weekOfYear) weeks ago"
        } else if (components.weekOfYear >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day >= 2) {
            return "\(components.day) days ago"
        } else if (components.day >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour >= 2) {
            return "\(components.hour) hours ago"
        } else if (components.hour >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute >= 2) {
            return "\(components.minute) minutes ago"
        } else if (components.minute >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second >= 3) {
            return "\(components.second) seconds ago"
        } else {
            return "Just now"
        }
        
    }
    
    
}