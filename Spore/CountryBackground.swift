//
//  CountryBackground.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/23/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit
import ParseUI

class CountryBackground: UIView {
    
    
    let background = CAShapeLayer()
    let progressLayer = CAShapeLayer()
    var progressView = UIView()
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    var isAnimating = false
    
    var color = UIColor(red: 195.0/255.0, green: 77.0/255.0, blue: 84.0/255.0, alpha: 1).CGColor
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let frame = super.frame
        
        //Create view
        progressView.frame = self.bounds
        progressView.backgroundColor = UIColor.clearColor()
        progressView.transform = CGAffineTransformMakeRotation(-CGFloat(M_PI)/2)
        self.addSubview(progressView)
        
        //Create background layer
        background.path = UIBezierPath(ovalInRect: CGRect(x: 4.0, y: 4.0, width: frame.width - 8, height: frame.height - 8)).CGPath
        background.fillColor = self.color
        self.layer.addSublayer(background)
        
        //Rotate view for progress bar, and rotate country image back
        let country = self.viewWithTag(5)
        self.bringSubviewToFront(country!)
        
        
        //Register for interruption notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CountryBackground.resumeAnimating), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    
    internal func setProgress(progress: Float) {
        
        
        progressLayer.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        
        progressLayer.fillColor = UIColor.clearColor().CGColor
        progressLayer.strokeColor = background.fillColor
        progressLayer.lineWidth = 2.5
        progressLayer.strokeStart = 1.0 - CGFloat(progress)
        progressLayer.strokeEnd = 1.0
        progressLayer.lineCap = kCALineCapRound
        
        progressView.layer.addSublayer(progressLayer)
    }
    
    
    internal func changeBackgroundColor(color: CGColor) {
        
        background.fillColor = color
        progressLayer.fillColor = color
    }
    
    
    internal func noProgress() {
        
        progressLayer.removeFromSuperlayer()
    }
    
    
    internal func startAnimating() {
        
        isAnimating = true
        progressView.layer.removeAllAnimations()
        
        rotateAnimation.fromValue = CGFloat(-M_PI/2)
        rotateAnimation.toValue = CGFloat(3 * M_PI / 2)
        rotateAnimation.duration = 1
        rotateAnimation.repeatCount = HUGE
        
        
        progressView.layer.addAnimation(rotateAnimation, forKey: nil)
    }
    
    
    internal func resumeAnimating() {
        
        if isAnimating {
            
            progressView.layer.addAnimation(rotateAnimation, forKey: nil)
        }
    }
    
    
    internal func stopAnimating() {
        
        //Remove animations and hide
        isAnimating = false
        progressView.layer.removeAllAnimations()
    }
    
}
