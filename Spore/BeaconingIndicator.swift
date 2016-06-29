//
//  BeaconingIndicator.swift
//  Spore
//
//  Created by Vikram Ramkumar on 5/1/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class BeaconingIndicator: UIView {
    
    
    let dot = CAShapeLayer()
    let swirl = CAShapeLayer()
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    let color = UIColor(red: 195.0/255.0, green: 77.0/255.0, blue: 84.0/255.0, alpha: 1).CGColor
    var isAnimating = false
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        if frame.width > 0.0 {
            
            initializeView()
        }
    }
    
    
    internal required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        initializeView()
    }
    
    
    init() {
        
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    
    internal func initializeView() {
        
        //Rotate view
        self.transform = CGAffineTransformMakeRotation( -90.0 * CGFloat(M_PI) / 180.0)
        
        //Set beacon dot
        let dotBounds = self.bounds.height * 0.80
        dot.path = UIBezierPath(ovalInRect: CGRect(x: self.bounds.width * 0.10, y: self.bounds.height * 0.10, width: dotBounds, height: dotBounds)).CGPath
        dot.fillColor = color
        
        //Set swirl
        swirl.path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)).CGPath
        swirl.fillColor = UIColor.clearColor().CGColor
        swirl.strokeColor = color
        swirl.strokeStart = 0.4
        swirl.strokeEnd = 1.0
        swirl.lineWidth = 2
        swirl.lineCap = kCALineCapRound
        
        //Add sublayers to refreh control
        self.layer.addSublayer(swirl)
        self.layer.addSublayer(dot)
    }
    
    
    internal func updateLayers() {
        
        
        let dotBounds = self.bounds.height * 0.80
        swirl.path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)).CGPath
        dot.path = UIBezierPath(ovalInRect: CGRect(x: self.bounds.width * 0.10, y: self.bounds.height * 0.10, width: dotBounds, height: dotBounds)).CGPath
    }
    
    
    internal func startAnimating() {
        
        self.hidden = false
        isAnimating = true
        
        rotateAnimation.fromValue = -CGFloat(M_PI)/2
        rotateAnimation.toValue = 3 * CGFloat(M_PI)/2
        rotateAnimation.duration = 1
        rotateAnimation.repeatCount = HUGE
        rotateAnimation.fillMode = kCAFillModeForwards
        rotateAnimation.removedOnCompletion = false

        self.layer.addAnimation(rotateAnimation, forKey: nil)
    }
    
    
    internal func stopAnimating() {
        
        //Remove animations and hide
        self.layer.removeAllAnimations()
        self.hidden = true
        isAnimating = false
    }
    
    
    internal func stopAnimatingWithoutHiding() {
        
        //Remove animations and hide
        self.layer.removeAllAnimations()
        isAnimating = false
    }
    
    
    internal func changeColor(color: CGColor) {
        
        dot.fillColor = color
        swirl.strokeColor = color
    }
    
}