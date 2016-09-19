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
    
    
    var lastLocation = CGPoint(x: 0, y: 0)
    var moviePlayer = AVPlayerLayer()
    let fileManager = FileManager.default
    let userDefaults = UserDefaults.standard
    var childController = TabBarController()
    var hideStatusBar = false
    
    @IBOutlet var snap: PFImageView!
    @IBOutlet var snapTimer: SnapTimer!
    @IBOutlet var container: UIView!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        snap.addSubview(snapTimer)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        //Initialize values
        self.snap.isUserInteractionEnabled = false
        snap.alpha = 0
        
        super.viewWillAppear(true)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        //Run like usual
        super.viewDidAppear(true)
        
        //Configure gestures & snap
        snap.isUserInteractionEnabled = true
        
    }
    
    
    @IBAction func snapTapped(_ sender: AnyObject) {
        
        print("Tapped!")
        
        
        if self.hideStatusBar {
            
            self.toggleStatusBar()
        }
        
        UIView.animate(withDuration: 0.3, animations: { 
            
            //Animate disappearance
            self.snap.alpha = 0
            self.snapTimer.alpha = 0
            
            }, completion: { (Bool) in
                
                //Close beacon after animation
                self.closeBeacon()
        }) 
    }
    
    
    @IBAction func snapPanned(_ sender: UIPanGestureRecognizer) {
        
        
        switch sender.state {
            
        case .began:
            
            //Restrict touches to snap only
            container.isUserInteractionEnabled = false
            
            //Show status bar if hidden
            if self.hideStatusBar {
                
                toggleStatusBar()
            }
            
        case .changed:
            
            //Move snap
            let translation = sender.translation(in: snap.superview)
            snap.center.y = lastLocation.y + translation.y
            
            
        case .ended, .cancelled:
            
            let snapDistance = abs(snap.center.y - self.view.center.y)
            let distanceFraction = snapDistance/self.view.bounds.height
            
            
            //If not moved much, move snap back and hide status bar
            if distanceFraction < 0.10 {
                
                print("Moving image back")
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    
                    self.snap.center.y = self.view.center.y
                    
                    if !self.hideStatusBar && self.snap.alpha == 1 {
                        
                        self.toggleStatusBar()
                    }
                }) 
            }
            //Else, slide off screen
            else {
                
                print("Moving image off")
                
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    
                    //Slide action
                    self.snap.center.y = ((self.snap.center.y - self.view.center.y)/abs(self.snap.center.y - self.view.center.y) * self.view.bounds.height * 2) + self.view.center.y
                    
                    }, completion: { (BooleanLiteralType) -> Void in
                        
                        self.closeBeacon()
                })
            }
            
        default:
            print("default")
        }
    }
    
    
    internal func closeBeacon() {
        
        
        //Post slide snap config
        self.moviePlayer.player = nil
        self.moviePlayer.removeFromSuperlayer()
        self.snap.image = nil
        self.snap.alpha = 0
        self.snap.isUserInteractionEnabled = false
        self.container.isUserInteractionEnabled = true
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("Touching")
        lastLocation = snap.center
        
    }
    
    
    internal func toggleStatusBar() {
        
        hideStatusBar = !hideStatusBar
        setNeedsStatusBarAppearanceUpdate()
    }
    
    
    override var childViewControllerForStatusBarHidden : UIViewController? {
        
        print("Status bar hiding method - Snap Controller")
        if hideStatusBar {
        
            print("Snap is in the center, rely on self for status bar hiding")
            return nil
        }
        
        return childController
    }
    
    
    override var childViewControllerForStatusBarStyle : UIViewController? {
        
        print("Status bar style method - Snap Controller")
        return childController
    }
    
    
    override var prefersStatusBarHidden : Bool {
        
        return true
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SnapToTabBarSegue" {
            
            print("Setting child controller")
            self.childController = segue.destination as! TabBarController
            
        }
    }
}
