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
    
    @IBOutlet var snap: PFImageView!
    @IBOutlet var container: UIView!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
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
        let panRecognizer = UIPanGestureRecognizer(target: self, action: "detectPan:")
        snap.addGestureRecognizer(tap)
        snap.addGestureRecognizer(panRecognizer)
        
    }
    
    
    internal func snapTapped() {
        
        print("Tapped!")
        
        self.snap.userInteractionEnabled = false
        
        UIView.animateWithDuration(0.3) { () -> Void in
            
            self.snap.alpha = 0
            self.moviePlayer.player = nil
            self.moviePlayer.removeFromSuperlayer()
        }
        
    }
    
    
    internal func detectPan(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translationInView(snap.superview)
        snap.center.y = CGPointMake(lastLocation.x + translation.x, lastLocation.y + translation.y).y
        
        switch recognizer.state {
            
        case .Ended:
            
            let snapDistance = abs(snap.center.y - self.view.center.y)
            let distanceFraction = snapDistance/self.view.bounds.height
            
            
            //If not moved much, move snap back
            if distanceFraction < 0.10 {
                
                print("Moving image back")
                UIView.animateWithDuration(0.3) { () -> Void in
                    
                    self.snap.center.y = self.view.center.y
                }
            }
            //Else, slipe off screen
            else {
                print("Moving image off")
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    
                    self.snap.center.y = ((self.snap.center.y - self.view.center.y)/abs(self.snap.center.y - self.view.center.y) * self.view.bounds.height * 2) + self.view.center.y
                    
                    }, completion: { (BooleanLiteralType) -> Void in
                        
                        self.moviePlayer.player = nil
                        self.moviePlayer.removeFromSuperlayer()
                        self.snap.alpha = 0
                        self.snap.center.y = self.view.center.y
                        self.snap.userInteractionEnabled = false
                })
            }
        default:
            print("default")
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        print("Moving image around")
        snap.superview!.bringSubviewToFront(snap)
        lastLocation = snap.center
        
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        
        print("Status bar config")
        return childController
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        return UIStatusBarStyle.LightContent
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "SnapToTabBarSegue" {
            
            print("Setting child controller")
            self.childController = segue.destinationViewController as! TabBarController
            
        }
    }
}