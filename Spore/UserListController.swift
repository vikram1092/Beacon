//
//  userListController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 1/26/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//


import UIKit
import Parse
import ParseUI
import Foundation
import AVFoundation
import FBSDKCoreKit
import FBSDKLoginKit


class UserListController: UITableViewController {
    
    var initialRowLoad = false
    var viewLoaded = false
    var userList = Array<PFObject>()
    var userName = ""
    var userEmail = ""
    var userCountry = ""
    var userToReceivePhotos = 0
    var countryCenter = CGPoint(x: 0,y: 0)
    var countryTable = CountryTable()
    var countryObject = UIView()
    let fileManager = NSFileManager.defaultManager()
    let videoPath = NSTemporaryDirectory() + "receivedVideo.mov"
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let calendar = NSCalendar.currentCalendar()
    
    @IBOutlet var table: UITableView!
    
    
    override func viewDidLoad() {
        
        //Load view as usual
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        //Run like usual
        super.viewDidAppear(true)
        
        //Retreive user details
        if userDefaults.objectForKey("userName") != nil {
            
            userName = userDefaults.objectForKey("userName") as! String
            userEmail = userDefaults.objectForKey("userEmail") as! String
        }
        
        if userDefaults.objectForKey("userCountry") != nil {
            
            userCountry = userDefaults.objectForKey("userCountry") as! String
        }
        
        
        //Check user login status
        print("Checking user login status")
        if userDefaults.objectForKey("userName") != nil {
            
            //Check if user is banned in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.userIsBanned()
                })
                
            //Get userToReceivePhotos
            if userDefaults.integerForKey("userToReceivePhotos") > 0 {
                userToReceivePhotos = userDefaults.integerForKey("userToReceivePhotos")
                print("usertoReceivePhotos: " + String(userToReceivePhotos))
            }
            
            //Load user list if it hasn't loaded, or else update what's loaded
            print("viewDidAppear: " + String(viewLoaded))
            if viewLoaded {
                updateUserList(false)
            }
            else {
                
                //Turn on table animations
                print("Turning on animations")
                initialRowLoad = true
                
                //Load user list
                loadUserList()
            }
        }
        else {
            segueToLogin()
        }
    }
    
    
    internal func userIsBanned() {
        
        //Show alert if user is banned
        let query = PFQuery(className: "users")
        print("user email: " + userEmail)
        query.whereKey("email", equalTo: userEmail)
        query.getFirstObjectInBackgroundWithBlock { (userObject, error) -> Void in
            
            if error != nil {
                
                print("Error getting user banned status: " + error!.description)
            }
            else {
                
                let bannedStatus = userObject!.objectForKey("banned") as! BooleanLiteralType
                
                if bannedStatus {
                    
                    //Alert user about ban & segue
                    print("User banned.")
                    let alert = UIAlertController(title: "You've been banned", message: "Allow us to investigate this issue & check back soon.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                        self.logoutUser()
                        self.segueToLogin()
                    }))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
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
            self.userDefaults.setObject(nil, forKey: "userCountry")
        }
    }
    
    
    internal func saveUserList() {
        
        //Clean old photos to save local space
        for object in userList {
            
            if(!withinTime(object.objectForKey("receivedAt") as! NSDate)) {
                
                object.removeObjectForKey("photo")
            }
        }
        
        //Save everything
        PFObject.pinAllInBackground(userList)
    }
    
    
    internal func loadUserList() {
        
        
        //Retreive local user photo list
        let query = PFQuery(className: "photo")
        query.fromLocalDatastore()
        query.whereKey("receivedBy", equalTo: userEmail)
        
        print("Querying localuserList")
        query.addAscendingOrder("updatedAt")
        query.findObjectsInBackgroundWithBlock { (objects, retreivalError) -> Void in
            
            if retreivalError != nil {
                
                print("Problem retreiving list: " + retreivalError!.description)
            }
            else if objects!.count > 0 {
                
                //Save list of objects & reload table
                self.userList = objects!
                self.viewLoaded = true
                print("viewLoad: " + String(self.viewLoaded))
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Update user list with new photos
                    print("Reloading table after local retreival")
                    self.table.reloadData()
                    print("Adding new photos")
                    self.updateUserList(false)
                })
            }
        }
    }
    
    
    internal func updateUserList(sameCountry: Bool) {
        
        //Initialize for subtracting from userToReceivePhotos list
        var userReceivedPhotos = 0
        
        //If user is to receive photos, execute the following
        if userToReceivePhotos > 0 {
            
            //Get unsent photos in the database equal to how many the user gets
            let query = PFQuery(className:"photo")
            query.whereKeyDoesNotExist("receivedBy")
            
            if !sameCountry {
                
                print("Adding country restriction")
                query.whereKey("countryCode", notEqualTo: userCountry)
            }
            //query.whereKey("sentBy", notEqualTo: userEmail)
            query.limit = userToReceivePhotos
            
            //Query with above conditions
            query.findObjectsInBackgroundWithBlock({ (photos, error) -> Void in
                
                if error != nil {
                    print("Photo query error: " + error!.description)
                }
                else if photos!.count < 1 {
                    
                    //Either recurse the same method with different parameters or end search
                    if self.userToReceivePhotos > 0 {
                        if sameCountry {
                            
                            //Let the user know that the database is empty
                            print("Database empty.")
                            let alert = UIAlertController(title: "Photos To Come!", message: "People will be sharing their pics very soon, check back to see what you get!", preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                        else {
                            
                            //Query for pictures from the same country
                            self.updateUserList(true)
                        }
                    }
                }
                else {
                    
                    print("photo count: " + String(photos!.count))
                    
                    //Create temporary list and run for each returned object
                    var tempList = Array<PFObject>()
                    
                    for photoObject in photos!{
                        
                        //Increment how much user receives
                        userReceivedPhotos++
                        
                        //Attach receipt details to object
                        photoObject["receivedAt"] = NSDate()
                        photoObject["receivedBy"] = self.userEmail
                        
                        //Add object to userList
                        tempList.append(photoObject)
                        print("userList count: " + String(self.userList.count))
                        
                        //Save object to database
                        print("Saving object!")
                        photoObject.saveInBackground()
                        print("Saved object!")
                        print("userList count: " + String(self.userList.count))
                    }
                    
                    //Add objects to user list
                    print("Adding new objects to userList")

                    for object in tempList {
                        self.userList.append(object)
                    }
                    
                    print("Reloading table after new objects")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        //Reload table
                        self.table.reloadData()
                        
                        //Save user list
                        print("Saving user list")
                        self.saveUserList()
                        
                        //Reset user photos to zero once photos are retreived
                        print("Resetting user photos")
                        self.userToReceivePhotos -= userReceivedPhotos
                        self.userDefaults.setInteger(self.userToReceivePhotos, forKey: "userToReceivePhotos")
                    })
                }
                

            })
        }
        
        //Stop refreshing
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.refreshControl!.endRefreshing()
        })
    }

    
    @IBAction func refreshControl(sender: AnyObject) {
        
        //Refresh data and reload table within that function
        updateUserList(false)
    }
    
    
    internal override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Initialize variables:
        //Array is printed backwards so userListLength is initialized
        print("Reached cell" + String(indexPath.row))
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let titleView = cell.viewWithTag(1) as! UILabel
        let subTitleView = cell.viewWithTag(2) as! UILabel
        let imageView = cell.viewWithTag(5) as! UIImageView
        let imageBackground = cell.viewWithTag(6) as! CountryBackground
        let slideIndicator = cell.viewWithTag(3) as! UIImageView
        
        let userListLength = userList.count - 1
        let date = userList[userListLength - indexPath.row]["receivedAt"] as! NSDate
        let timeString = timeSinceDate(date, numericDates: true)
        let countryCode = userList[userListLength - indexPath.row]["countryCode"]
        
        
        //Configure image background
        imageBackground.layer.cornerRadius = imageBackground.frame.size.width/2
        //Configure image
        imageView.image = countryTable.getCountryImage(countryCode as! String).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        imageBackground.addSubview(imageView)
        
        //Configure image sliding and action
        let pan = UIPanGestureRecognizer(target: self, action: Selector("detectPan:"))
        imageBackground.addGestureRecognizer(pan)
        
        
        //Configure time left for photo
        if withinTime(date) {
            imageBackground.setProgress(getTimeFraction(date))
        }
        else {
            imageBackground.noProgress()
        }
        
        
        //Configure text
        titleView.text = countryTable.getCountryName(countryCode as! String)
        
        //Configure subtext
        subTitleView.textColor = UIColor(red: 166.0/255.0, green: 166.0/255.0, blue: 166.0/255.0, alpha: 1.0)
        subTitleView.text = String(timeString)
        
        
        //Configure slide indicator
        slideIndicator.image = UIImage(named: "Globe")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        slideIndicator.tintColor = UIColor.lightGrayColor()
        
        return cell
    }
    

    internal override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if initialRowLoad {
            
            cell.center = CGPointMake(cell.center.x+100, cell.center.y)
            UIView.animateWithDuration(0.2 + Double(indexPath.row)/40) { () -> Void in
                
                cell.center = CGPointMake(cell.center.x-100, cell.center.y)
            }
        }
        
        //Turn off animations when we reach the last cell
        print("Numberofrowsinsection: " + String(tableView.numberOfRowsInSection(0) - 1))
        if initialRowLoad && indexPath.row == tableView.indexPathsForVisibleRows!.last!.row {
            print("Turning off animations")
            initialRowLoad = false
        }
    }
    
    
    internal override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return userList.count
    }
    
    
    internal override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let userListLength = self.userList.count - 1
        let date = userList[userListLength - indexPath.row]["receivedAt"] as! NSDate
        
        if withinTime(date) {
            
            return true
        }
        
        return false
    }
    
    
    internal override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
    
        //Declare spam button
        let spam = UITableViewRowAction(style: .Normal, title: "Spam") { (action, index) -> Void in
            
            print("Marked as spam")
            
            //Do in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                
                //Get user from table and ban
                let userListLength = self.userList.count - 1
                let object = self.userList[userListLength - indexPath.row]
                object.setObject(true, forKey: "spam")
                object.saveInBackground()
                
                //Run method to check if user ban-worthy
                self.banUser(object.objectForKey("sentBy") as! String)
            })
            
            //End editing view
            tableView.setEditing(false, animated: true)
        }
        spam.backgroundColor = UIColor(red: 254.0/255.0, green: 90.0/255.0, blue: 93.0/255.0, alpha: 1)
        
        return [spam]
    }
    
    
    internal override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
        saveUserList()
        table.reloadData()
    }
    
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //Deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        //Flip index to access correct array element & check time constraint of photos
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        let index = userList.count - 1 - indexPath.row
        let inTime = withinTime(userList[index].objectForKey("receivedAt") as! NSDate)
        
        //If photo within time, display photo or video
        if inTime {
            
            //Initialize parent VC variables
            let grandparent = self.parentViewController?.parentViewController?.parentViewController as! SnapController
            grandparent.snap.image = nil
            
            //Get video trigger from DB object
            var isVideo = false
            if userList[index]["isVideo"] != nil {
                
                isVideo = userList[index]["isVideo"] as! BooleanLiteralType
            }
            
            //Get PFFile
            let objectToDisplay = userList[index]["photo"] as! PFFile
            
            //Start UI animation
            let activity = cell.viewWithTag(4) as! UIActivityIndicatorView
            activity.startAnimating()
            
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
                            selector: "closeVideo",
                            name: AVPlayerItemDidPlayToEndTimeNotification,
                            object: grandparent.moviePlayer.player!.currentItem)
                        
                        
                        
                        //Update UI in main queue
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            print("Adding video player")
                            activity.stopAnimating()
                            
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
                            
                        })
                    }
                })
            }
            else {
                
                grandparent.snap.file = objectToDisplay
                
                grandparent.snap.loadInBackground { (photoData, photoConvError) -> Void in
                    
                    //Stop animation
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        activity.stopAnimating()
                    })
                    
                    if photoConvError != nil {
                        
                        print("Error converting photo from file: " + photoConvError!.description)
                    }
                    else {
                        
                        //Stop animation
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            //Decode and display image for user
                            if !grandparent.hideStatusBar {
                                
                                grandparent.toggleStatusBar()
                            }
                            
                            grandparent.snap.userInteractionEnabled = true
                            
                            //Hide timer
                            grandparent.snapTimer.alpha = 0
                            grandparent.snap.alpha = 1
                        })
                    }
                }
            }
            
        }
        //If photo not within time, display cell bounce animation
        else {
            
            
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                cell.center = CGPoint(x: cell.center.x+25, y: cell.center.y)
                
                }, completion: { (Bool) -> Void in
                    
                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        
                        cell.center = CGPoint(x: cell.center.x-25, y: cell.center.y)
                        
                        }, completion: { (BooleanLiteralType) -> Void in
                            
                            UIView.animateWithDuration(0.1, animations: { () -> Void in
                                
                                cell.center = CGPoint(x: cell.center.x+15, y: cell.center.y)
                                
                                }, completion: { (BooleanLiteralType) -> Void in
                                    
                                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                                        
                                        cell.center = CGPoint(x: cell.center.x-15, y: cell.center.y)
                                        
                                        }, completion: { (BooleanLiteralType) -> Void in
                                            
                                            UIView.animateWithDuration(0.1, animations: { () -> Void in
                                                
                                                cell.center = CGPoint(x: cell.center.x+7, y: cell.center.y)
                                                
                                                }, completion: { (BooleanLiteralType) -> Void in
                                                    
                                                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                                                        
                                                        cell.center = CGPoint(x: cell.center.x-7, y: cell.center.y)
                                                        
                                                    })
                                            })
                                    })
                            })
                    })
            })

        }
        
    }
    
    
    internal func banUser(sentBy: String) {
        
        print(sentBy)
        
        //Count rows reported belonging to user
        let countQuery = PFQuery(className: "photo")
        countQuery.whereKey("sentBy", equalTo: sentBy)
        countQuery.whereKey("spam", equalTo: true)
        countQuery.findObjectsInBackgroundWithBlock { (rows, rowsError) -> Void in
            
            //Display error getting row count
            if rowsError != nil {
                print("Error retrieving row count: \(rowsError)")
            }
                //Ban user if this is the second strike
            else if rows!.count > 1 {
                
                //Query to ban user
                print(rows!.count)
                let query = PFQuery(className: "users")
                query.whereKey("email", equalTo: sentBy)
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
    
    
    internal func closeVideo() {
        
        let grandparent = self.parentViewController?.parentViewController?.parentViewController as! SnapController
        
        //Stop animation
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            grandparent.moviePlayer.player = nil
            grandparent.moviePlayer.removeFromSuperlayer()
            grandparent.snap.alpha = 0
            
            //Only toggle if status bar hidden
            if grandparent.hideStatusBar {
                
                grandparent.toggleStatusBar()
            }
            })
        
        clearVideoTempFile()
    }
    
    
    internal func clearVideoTempFile() {
        
        do {
            try fileManager.removeItemAtPath(videoPath)
        }
        catch let error as NSError {
            print("Error deleting video: \(error)")
        }
    }
    

    internal func detectPan(recognizer: UIPanGestureRecognizer) {
        
        
        countryObject = recognizer.view!
        let translation = recognizer.translationInView(recognizer.view!.superview)
        let cell = recognizer.view!.superview!.superview as! UITableViewCell
        
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
                if subview.tag != 3 && subview.tag != 5 && subview.tag != 6 {
                    
                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        
                        subview.alpha = 0
                    })
                }
                //Show map label
                else if subview.tag == 3 {
                    
                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        
                        subview.alpha = 1
                    })
                }
            }
            
        case .Ended:
            
            
            //Calculate distance fraction
            let countryDistance = abs(countryObject.center.x - countryCenter.x)
            let distanceFraction = countryDistance/self.view.bounds.width
            
            //If moved to the other side of the screen, go to map and show country
            if distanceFraction > 0.60 {
                
                let index = tableView.indexPathForCell(cell)!.row
                let userListIndex = userList.count - index - 1
                let geoPoint = userList[userListIndex].valueForKey("sentFrom") as! PFGeoPoint
                let location = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                segueToMap(location)
            }
            
            //Move country back and bring back elements
            print("Moving country back")
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                
                    //Move object first
                    self.countryObject.center.x = self.countryCenter.x
                    
                    
                    //Since content view is the direct subview layer, we have to first go into that
                    for subview in cell.subviews[0].subviews {
                        
                        //Ensure that the subview is not the image, its background or the map label
                        if subview.tag != 3 && subview.tag != 5 && subview.tag != 6 {
                            
                            subview.alpha = 1
                        }
                        //Hide map label
                        else if subview.tag == 3 {
                            
                            UIView.animateWithDuration(0.1, animations: { () -> Void in
                                
                                subview.alpha = 0
                            })
                        }
                    }
                
                }, completion: nil)
            
        default:
            print("default")
            countryObject.center.x = translation.x + countryCenter.x
            
        }
    }
    
    
    internal func segueToMap(location: CLLocationCoordinate2D) {
        
        //Move to the map
        self.tabBarController?.selectedIndex = 1
        let map = tabBarController!.viewControllers![1] as! MapController
        map.goToCountry(location)
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
            loginController.loginButton.alpha = 1
            loginController.alertButton.alpha = 0
        }
    }
    
    
    internal func withinTime(date: NSDate) -> BooleanLiteralType {
        
        //Get calendar and current date, compare it to given date
        let difference = calendar.components([.Day, .WeekOfYear, .Month, .Year], fromDate: date, toDate: NSDate(), options: [])
        
        //Compare all components of the difference to see if it's greater than 2 days
        if difference.year > 0 || difference.month > 0 || difference.weekOfYear > 0 || difference.day >= 2
        {
            return false
        }
        
        return true
    }
    
    
    internal func getTimeFraction(date: NSDate) -> Float {
        
        //Get calendar and current date, compare it to given date
        let difference = calendar.components([.Day, .Hour, .Minute], fromDate: date, toDate: NSDate(), options: [])
        let timeElapsed = (difference.day * 24 * 60) + (difference.hour * 60) + (difference.minute)
        
        //Return fraction of elapsed time over two days
        return 1.0 - Float(timeElapsed)/2880
        
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