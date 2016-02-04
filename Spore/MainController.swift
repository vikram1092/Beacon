//
//  File.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import Foundation

class MainController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate {
    
    
    var timer = NSTimer()
    var lastLocation = CGPointMake(0, 0)
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var table: UIView!

    @IBOutlet var snap: PFImageView!
    
    override func viewDidLoad() {
        
        //Load view
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        //Initialize values
        snap.alpha = 0
        self.tabBarController?.tabBar.hidden = false
        
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
        UIView.animateWithDuration(0.3) { () -> Void in
            
            self.snap.alpha = 0
            self.tabBarController!.tabBar.hidden = false
        }
    }
    
    
    internal func detectPan(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translationInView(snap.superview)
        snap.center.y = CGPointMake(lastLocation.x + translation.x, lastLocation.y + translation.y).y
        //snap.alpha = (self.view.center.y - abs(self.view.center.y - snap.center.y))/self.view.center.y
        
        switch recognizer.state {
           
        case .Ended:
            
            let snapDistance = abs(snap.center.y - self.view.center.y)
            let distanceFraction = snapDistance/self.view.bounds.height
            
            if distanceFraction < 0.10 {
                
                print("Moving image back")
                UIView.animateWithDuration(0.3) { () -> Void in
                    
                    self.snap.center.y = self.view.center.y
                }
            }
            else {
                print("Moving image off")
                UIView.animateWithDuration(0.3) { () -> Void in
                    
                    self.snap.center.y = ((self.snap.center.y - self.view.center.y)/abs(self.snap.center.y - self.view.center.y) * self.view.bounds.height * 2) + self.view.center.y
                    self.tabBarController!.tabBar.hidden = false
                }
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
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
}

