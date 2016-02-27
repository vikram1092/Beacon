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
    var viewLoad = false
    var userList = Array<PFObject>()
    var userName = ""
    var userEmail = ""
    var userToReceivePhotos = 0
    let fileManager = NSFileManager.defaultManager()
    let videoPath = NSTemporaryDirectory() + "receivedVideo.mov"
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
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
            }
            
            //Load user list if it hasn't loaded, or else update what's loaded
            print("viewDidAppear: " + String(viewLoad))
            if viewLoad {
                updateUserList()
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
    
    
    //Show alert if user is banned
    internal func userIsBanned() {
    
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
        
        print("Querying localuserList")
        query.addAscendingOrder("updatedAt")
        query.findObjectsInBackgroundWithBlock { (objects, retreivalError) -> Void in
            
            if retreivalError != nil {
                
                print("Problem retreiving list: " + retreivalError!.description)
            }
            else if objects!.count > 0 {
                
                //Save list of objects & reload table
                self.userList = objects!
                self.viewLoad = true
                print("viewLoad: " + String(self.viewLoad))
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Update user list with new photos
                    print("Reloading table after local retreival")
                    self.table.reloadData()
                    print("Adding new photos")
                    self.updateUserList()
                })
            }
        }
    }
    
    
    internal func updateUserList() {
        
        //Initialize for subtracting from userToReceivePhotos list
        var userReceivedPhotos = 0
        
        //If user is to receive photos, execute the following
        if userToReceivePhotos > 0 {
            
            //Get unsent photos in the database equal to how many the user gets
            let query = PFQuery(className:"photo")
            query.whereKeyDoesNotExist("receivedBy")
            //query.whereKey("isVideo", equalTo: true)
            //query.whereKey("sentBy", notEqualTo: userEmail)
            query.limit = userToReceivePhotos
            
            //Query with above conditions
            query.findObjectsInBackgroundWithBlock({ (photos, error) -> Void in
                
                
                if error != nil {
                    print("Photo query error: " + error!.description)
                }
                else if photos!.count < 1 {
                    
                    //Let the user know that the database is empty
                    print("Database empty.")
                    let alert = UIAlertController(title: "Photos To Come!", message: "People will be sharing their pics very soon, check back to see what you get!", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
                    self.presentViewController(alert, animated: true, completion: nil)
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
                
                //Stop refreshing

            })
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.refreshControl!.endRefreshing()
        })
    }

    
    @IBAction func refreshControl(sender: AnyObject) {
        
        //Refresh data and reload table within that function
        updateUserList()
    }
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    internal override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Initialize variables:
        //Array is printed backwards so userListLength is initialized
        print("Reached cell" + String(indexPath.row))
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let imageView = cell.viewWithTag(100) as! UIImageView
        let titleView = cell.viewWithTag(101) as! UILabel
        let subTitleView = cell.viewWithTag(102) as! UILabel
        
        let userListLength = userList.count - 1
        print(userListLength)
        
        let date = userList[userListLength - indexPath.row]["receivedAt"] as! NSDate
        let timeString = timeSinceDate(date, numericDates: true)
        let countryCode = userList[userListLength - indexPath.row]["countryCode"]
        
        //Configure image
        
        //let color = UIColor(red: CGFloat(arc4random_uniform(255))/255.0, green: CGFloat(arc4random_uniform(255))/255.0, blue: CGFloat(arc4random_uniform(255))/255.0, alpha: 0.5)
        imageView.image = getCountryImage(countryCode as! String).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        //imageView.tintColor = color
        
        //Configure text
        titleView.text = getCountryName(countryCode as! String)
        titleView.textColor = getColorForCell(date)
        
        //Configure subtext
        subTitleView.textColor = UIColor(red: 166.0/255.0, green: 166.0/255.0, blue: 166.0/255.0, alpha: 1.0)
        subTitleView.text = String(timeString)
        
        
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
    
    
    internal override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        //Declare spam button with functionality
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
        
        return [spam]
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
    
    
    internal override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            userList.removeAtIndex(indexPath.row)
        }
        
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
            let activity = cell.viewWithTag(104) as! UIActivityIndicatorView
            activity.startAnimating()
            
            //Handle for videos and pictures uniqeuly
            if isVideo {
                
                objectToDisplay.getDataInBackgroundWithBlock({ (videoData, videoError) -> Void in
                    
                    if videoError != nil {
                        print("Error converting video: \(videoError)")
                    }
                    else {
                        
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
                            
                            grandparent.snap.userInteractionEnabled = true
                            grandparent.snap.backgroundColor = UIColor.blackColor()
                            grandparent.moviePlayer.frame = grandparent.snap.bounds
                            grandparent.snap.layer.addSublayer(grandparent.moviePlayer)
                            grandparent.snap.alpha = 1
                            
                            //Play video
                            grandparent.moviePlayer.player!.play()
                            
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
                            grandparent.snap.userInteractionEnabled = true
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
                
                }, completion: { (BooleanLiteralType) -> Void in
                    
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
    
    
    internal func closeVideo() {
        
        let grandparent = self.parentViewController?.parentViewController?.parentViewController as! SnapController
        
        //Stop animation
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            grandparent.moviePlayer.player = nil
            grandparent.moviePlayer.removeFromSuperlayer()
            grandparent.snap.alpha = 0
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
    
    
    internal func segueToLogin() {
        
        //Segue to login screen
        print("Segue-ing")
        performSegueWithIdentifier("UserListToLoginSegue", sender: self)
        
    }
    
    
    internal func getCountryImage(countryCode: String) -> UIImage {
        
        let link  = "Countries/" + countryCode + "/128.png"
        
        if let image = UIImage(named: link) {
            
            return image
        }
        
        return UIImage(named: "Countries/Unknown/128.png")!
    }
    
    
    internal func getCountryName(countryCode: String) -> String {
        
        var countryName = "India"
        print("Country:" + countryCode)
        
        //Find country and obtain the 2 digit ISO code
        for country in countryTable {
            
            if country[1] == countryCode {
                countryName = country[0]
                break
            }
        }
        
        return countryName
    }
    
    
    internal func getColorForCell(date: NSDate) -> UIColor {
        
        if withinTime(date) {
            
            return UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: 1)
        }
        else {
            
            return UIColor(red: CGFloat(0.4), green: CGFloat(0.4), blue: CGFloat(0.4), alpha: 1)
        }
    }
    
    
    internal func withinTime(date: NSDate) -> BooleanLiteralType {
        
        //Get calendar and current date, compare it to given date
        let calendar = NSCalendar.currentCalendar()
        let difference = calendar.components([.Day, .WeekOfYear, .Month, .Year], fromDate: date, toDate: NSDate(), options: [])
        
        //Comapre all components of the difference to see if it's greater than 2 days
        if difference.year > 0 || difference.month > 0 || difference.weekOfYear > 0 || difference.day >= 2
        {
            return false
        }
        
        return true
    }
    
    
    internal func timeSinceDate(date:NSDate, numericDates:Bool) -> String {
        
        let calendar = NSCalendar.currentCalendar()
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
    
    
    var countryTable = [["Afghanistan","af"],
        ["Åland Islands","ax"],
        ["Albania","al"],
        ["Algeria","dz"],
        ["American Samoa","as"],
        ["Andorra","ad"],
        ["Angola","ao"],
        ["Anguilla","ai"],
        ["Antarctica","aq"],
        ["Antigua and Barbuda","ag"],
        ["Argentina","ar"],
        ["Armenia","am"],
        ["Aruba","aw"],
        ["Australia","au"],
        ["Austria","at"],
        ["Azerbaijan","az"],
        ["Bahamas","bs"],
        ["Bahrain","bh"],
        ["Bangladesh","bd"],
        ["Barbados","bb"],
        ["Belarus","by"],
        ["Belgium","be"],
        ["Belize","bz"],
        ["Benin","bj"],
        ["Bermuda","bm"],
        ["Bhutan","bt"],
        ["Bolivia","bo"],
        ["Bonaire, Sint Eustatius and Saba","bq"],
        ["Bosnia and Herzegovina","ba"],
        ["Botswana","bw"],
        ["Bouvet Island","bv"],
        ["Brazil","br"],
        ["British Indian Ocean Territory","io"],
        ["Brunei Darussalam","bn"],
        ["Bulgaria","bg"],
        ["Burkina Faso","bf"],
        ["Burundi","bi"],
        ["Cambodia","kh"],
        ["Cameroon","cm"],
        ["Canada","ca"],
        ["Cabo Verde","cv"],
        ["Cayman Islands","ky"],
        ["Central African Republic","cf"],
        ["Chad","td"],
        ["Chile","cl"],
        ["China","cn"],
        ["Christmas Island","cx"],
        ["Cocos (Keeling) Islands","cc"],
        ["Colombia","co"],
        ["Comoros","km"],
        ["Congo","cg"],
        ["Congo","cd"],
        ["Cook Islands","ck"],
        ["Costa Rica","cr"],
        ["Côte d'Ivoire","ci"],
        ["Croatia","hr"],
        ["Cuba","cu"],
        ["Curaçao","cw"],
        ["Cyprus","cy"],
        ["Czech Republic","cz"],
        ["Denmark","dk"],
        ["Djibouti","dj"],
        ["Dominica","dm"],
        ["Dominican Republic","do"],
        ["Ecuador","ec"],
        ["Egypt","eg"],
        ["El Salvador","sv"],
        ["Equatorial Guinea","gq"],
        ["Eritrea","er"],
        ["Estonia","ee"],
        ["Ethiopia","et"],
        ["Falkland Islands (Malvinas)","fk"],
        ["Faroe Islands","fo"],
        ["Fiji","fj"],
        ["Finland","fi"],
        ["France","fr"],
        ["French Guiana","gf"],
        ["French Polynesia","pf"],
        ["French Southern Territories","tf"],
        ["Gabon","ga"],
        ["Gambia","gm"],
        ["Georgia","ge"],
        ["Germany","de"],
        ["Ghana","gh"],
        ["Gibraltar","gi"],
        ["Greece","gr"],
        ["Greenland","gl"],
        ["Grenada","gd"],
        ["Guadeloupe","gp"],
        ["Guam","gu"],
        ["Guatemala","gt"],
        ["Guernsey","gg"],
        ["Guinea","gn"],
        ["Guinea-Bissau","gw"],
        ["Guyana","gy"],
        ["Haiti","ht"],
        ["Heard Island and McDonald Islands","hm"],
        ["Holy See","va"],
        ["Honduras","hn"],
        ["Hong Kong","hk"],
        ["Hungary","hu"],
        ["Iceland","is"],
        ["India","in"],
        ["Indonesia","id"],
        ["Iran","ir"],
        ["Iraq","iq"],
        ["Ireland","ie"],
        ["Isle of Man","im"],
        ["Israel","il"],
        ["Italy","it"],
        ["Jamaica","jm"],
        ["Japan","jp"],
        ["Jersey","je"],
        ["Jordan","jo"],
        ["Kazakhstan","kz"],
        ["Kenya","ke"],
        ["Kiribati","ki"],
        ["North Korea","kp"],
        ["South Korea","kr"],
        ["Kuwait","kw"],
        ["Kyrgyzstan","kg"],
        ["Lao People's Democratic Republic","la"],
        ["Latvia","lv"],
        ["Lebanon","lb"],
        ["Lesotho","ls"],
        ["Liberia","lr"],
        ["Libya","ly"],
        ["Liechtenstein","li"],
        ["Lithuania","lt"],
        ["Luxembourg","lu"],
        ["Macao","mo"],
        ["Macedonia ","mk"],
        ["Madagascar","mg"],
        ["Malawi","mw"],
        ["Malaysia","my"],
        ["Maldives","mv"],
        ["Mali","ml"],
        ["Malta","mt"],
        ["Marshall Islands","mh"],
        ["Martinique","mq"],
        ["Mauritania","mr"],
        ["Mauritius","mu"],
        ["Mayotte","yt"],
        ["Mexico","mx"],
        ["Micronesia","fm"],
        ["Moldova","md"],
        ["Monaco","mc"],
        ["Mongolia","mn"],
        ["Montenegro","me"],
        ["Montserrat","ms"],
        ["Morocco","ma"],
        ["Mozambique","mz"],
        ["Myanmar","mm"],
        ["Namibia","na"],
        ["Nauru","nr"],
        ["Nepal","np"],
        ["Netherlands","nl"],
        ["New Caledonia","nc"],
        ["New Zealand","nz"],
        ["Nicaragua","ni"],
        ["Niger","ne"],
        ["Nigeria","ng"],
        ["Niue","nu"],
        ["Norfolk Island","nf"],
        ["Northern Mariana Islands","mp"],
        ["Norway","no"],
        ["Oman","om"],
        ["Pakistan","pk"],
        ["Palau","pw"],
        ["Palestine, State of","ps"],
        ["Panama","pa"],
        ["Papua New Guinea","pg"],
        ["Paraguay","py"],
        ["Peru","pe"],
        ["Philippines","ph"],
        ["Pitcairn","pn"],
        ["Poland","pl"],
        ["Portugal","pt"],
        ["Puerto Rico","pr"],
        ["Qatar","qa"],
        ["Réunion","re"],
        ["Romania","ro"],
        ["Russian Federation","ru"],
        ["Rwanda","rw"],
        ["Saint Barthélemy","bl"],
        ["Saint Helena, Ascension and Tristan da Cunha","sh"],
        ["Saint Kitts and Nevis","kn"],
        ["Saint Lucia","lc"],
        ["Saint Martin (French part)","mf"],
        ["Saint Pierre and Miquelon","pm"],
        ["Saint Vincent and the Grenadines","vc"],
        ["Samoa","ws"],
        ["San Marino","sm"],
        ["Sao Tome and Principe","st"],
        ["Saudi Arabia","sa"],
        ["Senegal","sn"],
        ["Serbia","rs"],
        ["Seychelles","sc"],
        ["Sierra Leone","sl"],
        ["Singapore","sg"],
        ["Sint Maarten (Dutch part)","sx"],
        ["Slovakia","sk"],
        ["Slovenia","si"],
        ["Solomon Islands","sb"],
        ["Somalia","so"],
        ["South Africa","za"],
        ["South Georgia and the South Sandwich Islands","gs"],
        ["South Sudan","ss"],
        ["Spain","es"],
        ["Sri Lanka","lk"],
        ["Sudan","sd"],
        ["Suriname","sr"],
        ["Svalbard and Jan Mayen","sj"],
        ["Swaziland","sz"],
        ["Sweden","se"],
        ["Switzerland","ch"],
        ["Syrian Arab Republic","sy"],
        ["Taiwan","tw"],
        ["Tajikistan","tj"],
        ["Tanzania","tz"],
        ["Thailand","th"],
        ["Timor-Leste","tl"],
        ["Togo","tg"],
        ["Tokelau","tk"],
        ["Tonga","to"],
        ["Trinidad and Tobago","tt"],
        ["Tunisia","tn"],
        ["Turkey","tr"],
        ["Turkmenistan","tm"],
        ["Turks and Caicos Islands","tc"],
        ["Tuvalu","tv"],
        ["Uganda","ug"],
        ["Ukraine","ua"],
        ["United Arab Emirates","ae"],
        ["United Kingdom","gb"],
        ["United States of America","us"],
        ["United States Minor Outlying Islands","um"],
        ["Uruguay","uy"],
        ["Uzbekistan","uz"],
        ["Vanuatu","vu"],
        ["Venezuela","ve"],
        ["Vietnam","vn"],
        ["Virgin Islands (British)","vg"],
        ["Virgin Islands (U.S.)","vi"],
        ["Wallis and Futuna","wf"],
        ["Western Sahara","eh"],
        ["Yemen","ye"],
        ["Zambia","zm"],
        ["Zimbabwe","zw"]]
    
}