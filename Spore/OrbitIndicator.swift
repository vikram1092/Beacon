//
//  OrbitIndicator.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/20/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class OrbitIndicator: UIView {
    
    
    let circle = CAShapeLayer()
    
    internal var animating: Bool = false {
        
        willSet (shouldAnimate) {
            if shouldAnimate && !animating {
                startSpinning()
            }
        }
        
        didSet {
        }
    }
    

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        
        let frameSize = super.frame
        circle.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frameSize.width, height: frameSize.height/1.5)).CGPath
        
        circle.lineWidth = 2.0
        circle.strokeStart = 0.0
        circle.strokeEnd = 0.25
        circle.lineCap = kCALineCapRound
        circle.fillColor = UIColor.clearColor().CGColor
        circle.strokeColor = UIColor.blackColor().CGColor
        
        self.layer.addSublayer(circle)
        
        startSpinning()
    }
    
    
    internal func show() {
    
        startSpinning()
    }
    
    
    internal func startSpinning() {
        
        let strokeEndMove = 1.0
        let strokeStartMove = 1.0
        
        
        self.circle.strokeEnd = CGFloat(0.0)
        
        UIView.animateWithDuration(0.8, animations: { () -> Void in
            
            self.circle.strokeEnd = CGFloat(strokeEndMove)
            
        }, completion: { (Bool) -> Void in
            
            self.startSpinning()
        })
        
        
        delay(0.2) { () -> () in
            
            self.circle.strokeStart = CGFloat(0.0)
            
            UIView.animateWithDuration(0.8, animations: { () -> Void in
                
                self.circle.strokeStart = CGFloat(strokeStartMove)
            })
        }
        
    }
    
    
    internal func hide() {
        
        
    }
    
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
}