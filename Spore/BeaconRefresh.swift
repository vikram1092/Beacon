//
//  BeaconRefresh.swift
//  Spore
//
//  Created by Vikram Ramkumar on 5/10/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class BeaconRefresh: UIRefreshControl {
    
    
    let dot = CAShapeLayer()
    let swirl = CAShapeLayer()
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    let color = UIColor(red: 189.0/255.0, green: 27.0/255.0, blue: 83.0/255.0, alpha: 1).CGColor
    var isAnimating = false
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        //Rotate view
        self.transform = CGAffineTransformMakeRotation( 90.0 * CGFloat(M_PI) / 180.0)
        
        //Set beacon dot
        let dotBounds = self.bounds.height * 0.80
        dot.path = UIBezierPath(ovalInRect: CGRect(x: self.bounds.width * 0.10, y: self.bounds.height * 0.10, width: dotBounds, height: dotBounds)).CGPath
        dot.fillColor = color
        
        //Set swirl
        swirl.path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)).CGPath
        swirl.fillColor = UIColor.clearColor().CGColor
        swirl.strokeColor = color
        swirl.strokeStart = 0
        swirl.strokeEnd = 0.6
        swirl.lineWidth = 2
        swirl.lineCap = kCALineCapRound
        
        
        self.layer.addSublayer(swirl)
        self.layer.addSublayer(dot)
    }
    
    override func beginRefreshing() {
        
        isAnimating = true
        
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(2.0 * M_PI)
        rotateAnimation.duration = 1
        rotateAnimation.repeatCount = HUGE
        
        self.layer.addAnimation(rotateAnimation, forKey: nil)
        
    }
    
    override func endRefreshing() {
        
        //Remove animations and hide
        self.layer.removeAllAnimations()
        self.hidden = true
        isAnimating = false
    }
}