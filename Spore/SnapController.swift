//
//  SnapController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/16/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Foundation
import AVFoundation

class SnapController: UIViewController {
    
    
    var lastLocation = CGPointMake(0, 0)
    var moviePlayer = AVPlayerLayer()
    let fileManager = NSFileManager.defaultManager()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var childController = TabBarController()
    var hideStatusBar = false
    
    @IBOutlet var snap: PFImageView!
    @IBOutlet var snapTimer: SnapTimer!
    @IBOutlet var container: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        snap.addSubview(snapTimer)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //Initialize values
        self.snap.userInteractionEnabled = false
        snap.alpha = 0
        
        super.viewWillAppear(true)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        //Run like usual
        super.viewDidAppear(true)
        
        //Configure gestures & snap
        snap.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: ("snapTapped"))
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "snapSwiped:")
        snap.addGestureRecognizer(tap)
        snap.addGestureRecognizer(panRecognizer)
        
    }
    
    
    internal func snapTapped() {
        
        print("Tapped!")
        
        self.snap.userInteractionEnabled = false
        
        if self.hideStatusBar {
            
            self.toggleStatusBar()
        }
        
        UIView.animateWithDuration(0.3) { () -> Void in
            
            self.snap.alpha = 0
            self.moviePlayer.player = nil
            self.moviePlayer.removeFromSuperlayer()
        }
        
    }
    
    
    internal func snapSwiped(recognizer: UIPanGestureRecognizer) {
        
        
        switch recognizer.state {
            
        case .Began:
            
            if self.hideStatusBar {
                
                toggleStatusBar()
            }
            
        case .Changed:
            
            //Move snap
            let translation = recognizer.translationInView(snap.superview)
            snap.center.y = lastLocation.y + translation.y
            
            
        case .Ended:
            
            let snapDistance = abs(snap.center.y - self.view.center.y)
            let distanceFraction = snapDistance/self.view.bounds.height
            
            
            //If not moved much, move snap back
            if distanceFraction < 0.10 {
                
                print("Moving image back")
                UIView.animateWithDuration(0.3) { () -> Void in
                    
                    self.snap.center.y = self.view.center.y
                    
                    if !self.hideStatusBar && self.snap.alpha == 1 {
                        
                        self.toggleStatusBar()
                    }
                }
            }
            //Else, slide off screen
            else {
                
                print("Moving image off")
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    
                    //Slide action
                    self.snap.center.y = ((self.snap.center.y - self.view.center.y)/abs(self.snap.center.y - self.view.center.y) * self.view.bounds.height * 2) + self.view.center.y
                    
                    }, completion: { (BooleanLiteralType) -> Void in
                        
                        //Post slide snap config
                        self.moviePlayer.player = nil
                        self.moviePlayer.removeFromSuperlayer()
                        self.snap.alpha = 0
                        self.snap.userInteractionEnabled = false
                })
            }
        default:
            print("default")
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        print("Moving image around")
        //snap.superview!.bringSubviewToFront(snap)
        lastLocation = snap.center
        
    }
    
    
    internal func toggleStatusBar() {
        
        hideStatusBar = !hideStatusBar
        setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        
        print("Status bar hiding method")
        if hideStatusBar {
        
            print("Status bar is in the center")
            return nil
        }
        
        return childController
    }
    
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        
        print("Status bar style method")
        return childController
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "SnapToTabBarSegue" {
            
            print("Setting child controller")
            self.childController = segue.destinationViewController as! TabBarController
            
        }
    }
}