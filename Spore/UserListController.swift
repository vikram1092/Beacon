//
//  File.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit

class UserListController: UIViewController, UITableViewDelegate {
    
    var timer = NSTimer()
    
    @IBOutlet var snap: UIImageView!
    
    var initialRowLoad = true
    var userList = [["Italy", "Description", "Time", "Picture1"],
                    ["Australia", "Description", "Time", "Picture2"],
                    ["India", "Description", "Time", "Picture3"],
                    ["USA", "Description", "Time", "Picture4"],
                    ["Ecuador", "Description", "Time", "Picture5"],
                    ["Congo", "Description", "Time", "Picture6"]]
    
    @IBOutlet var table: UITableView!
    @IBOutlet var settingsButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        snap.alpha = 0
        
        if NSUserDefaults.standardUserDefaults().objectForKey("userList") != nil {
    
            userList = NSUserDefaults.standardUserDefaults().objectForKey("userList") as! [Array]
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        initialRowLoad = true
        super.viewDidAppear(true)
    }
    
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Unread")
        let country = userList[indexPath.row][0]
        let desc = userList[indexPath.row][1]
        let time = userList[indexPath.row][2]
        
        cell.imageView!.image = UIImage(named: "Zion.png")
        cell.textLabel!.text = String(country + desc + time)
            
        return cell
    }
    
    
    internal func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        return 60
    }
    
    internal func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
        if initialRowLoad {
            
            cell.center = CGPointMake(cell.center.x+100, cell.center.y)
            
            UIView.animateWithDuration(0.2 + Double(indexPath.row)/4) { () -> Void in
                
                cell.center = CGPointMake(cell.center.x-100, cell.center.y)
            }
        }
        
    }
    
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            userList.removeAtIndex(indexPath.row)
        }
    
        NSUserDefaults.standardUserDefaults().setObject(userList, forKey: "userList")
        
        
        table.reloadData()
    }
    
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        snap.image = UIImage(named: "Zion Fullscreen.png")
        snap.alpha = 1
        
        delay(4.0) {
            self.snap.alpha = 0
        }
        
    }
    func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
}

