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
    let color = BeaconColors().redColor.cgColor
    var isAnimating = false
    var initialized = false
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
    }
    
    
    internal required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    init() {
        
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    
    internal func initializeView() {
        
        if !initialized {
            
            initialized = true
            
            //Rotate view
            self.transform = CGAffineTransform( rotationAngle: -90.0 * CGFloat(M_PI) / 180.0)
            
            //Set beacon dot
            let dotBounds = self.bounds.height * 0.80
            dot.path = UIBezierPath(ovalIn: CGRect(x: self.bounds.width * 0.10, y: self.bounds.height * 0.10, width: dotBounds, height: dotBounds)).cgPath
            dot.fillColor = color
            
            //Set swirl
            swirl.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)).cgPath
            swirl.fillColor = UIColor.clear.cgColor
            swirl.strokeColor = color
            swirl.strokeStart = 0.4
            swirl.strokeEnd = 1.0
            swirl.lineWidth = 2
            swirl.lineCap = kCALineCapRound
            
            //Add sublayers to refreh control
            self.layer.addSublayer(swirl)
            self.layer.addSublayer(dot)
        }
    }
    
    
    internal func updateLayers() {
        
        
        let dotBounds = self.bounds.height * 0.80
        swirl.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)).cgPath
        dot.path = UIBezierPath(ovalIn: CGRect(x: self.bounds.width * 0.10, y: self.bounds.height * 0.10, width: dotBounds, height: dotBounds)).cgPath
    }
    
    
    internal func startAnimating() {
        
        self.isHidden = false
        isAnimating = true
        
        rotateAnimation.fromValue = -CGFloat(M_PI)/2
        rotateAnimation.toValue = 3 * CGFloat(M_PI)/2
        rotateAnimation.duration = 1
        rotateAnimation.repeatCount = HUGE
        rotateAnimation.fillMode = kCAFillModeForwards
        rotateAnimation.isRemovedOnCompletion = false

        self.layer.add(rotateAnimation, forKey: nil)
    }
    
    
    internal func stopAnimating() {
        
        //Remove animations and hide
        self.layer.removeAllAnimations()
        self.isHidden = true
        isAnimating = false
    }
    
    
    internal func stopAnimatingWithoutHiding() {
        
        //Remove animations and hide
        self.layer.removeAllAnimations()
        isAnimating = false
    }
    
    
    internal func changeColor(_ color: CGColor) {
        
        dot.fillColor = color
        swirl.strokeColor = color
    }
    
}
