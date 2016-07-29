//
//  FocusShape.swift
//  Spore
//
//  Created by Vikram Ramkumar on 4/12/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class FocusShape: UIView {
    
    
    var focusFill = CAShapeLayer()
    var focusStroke = CAShapeLayer()
    var focusStrokeBorder = CAShapeLayer()
    
    
    init() {
        
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.userInteractionEnabled = false
    }
    
    
    init(drawPoint: CGPoint) {
        
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        self.userInteractionEnabled = false
        self.center = drawPoint
        drawFocus(drawPoint)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal func drawFocus(focusPoint: CGPoint) {
        
        
        //Remove focus shapes if they're in view and center view on given point
        focusFill.removeFromSuperlayer()
        focusStroke.removeFromSuperlayer()
        
        let originalSize = CGSize(width: 0.0, height: 0.0)
        let expandedSize = CGSize(width: 35.0, height: 35.0)
        let disappearingSize = CGSize(width: 25.0, height: 25.0)
        let x = self.bounds.width/2
        let y = self.bounds.height/2
        let originalShapeOrigin = CGPoint(x: -originalSize.width/2 + x, y: -originalSize.height/2 + y)
        let finalShapeOrigin = CGPoint(x:-expandedSize.width/2 + x, y: -expandedSize.height/2 + y)
        let disappearingOrigin = CGPoint(x: -disappearingSize.width/2 + x, y: -disappearingSize.height/2 + y)
        
        
        //Define focus shapes
        focusFill.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusFill.fillColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).CGColor
        
        focusStroke.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusStroke.strokeColor = UIColor.whiteColor().CGColor
        focusStroke.fillColor = UIColor.clearColor().CGColor
        focusStroke.lineWidth = 1.5
        focusStroke.strokeStart = 0.0
        focusStroke.strokeEnd = 1.0
        
        focusStrokeBorder.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusStrokeBorder.strokeColor = UIColor.lightGrayColor().CGColor
        focusStrokeBorder.fillColor = UIColor.clearColor().CGColor
        focusStrokeBorder.lineWidth = focusStroke.lineWidth + 1.0
        focusStrokeBorder.strokeStart = 0.0
        focusStrokeBorder.strokeEnd = 1.0
        
        
        //self.layer.addSublayer(focusFill)
        self.layer.addSublayer(focusStrokeBorder)
        self.layer.addSublayer(focusStroke)
        
        
        //Add animations
        let animationGroup = CAAnimationGroup()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            
            self.focusFill.removeFromSuperlayer()
            self.focusStrokeBorder.removeFromSuperlayer()
            self.focusStroke.removeFromSuperlayer()
            self.removeFromSuperview()
        }
        
        //Ease in animation
        let easeIn = CABasicAnimation(keyPath: "path")
        easeIn.fromValue = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        easeIn.toValue = UIBezierPath(ovalInRect: CGRect(origin: finalShapeOrigin, size: expandedSize)).CGPath
        easeIn.duration = 0.2
        easeIn.beginTime = 0.0
        easeIn.removedOnCompletion = false
        easeIn.fillMode = kCAFillModeForwards
        
        
        //Ease out animation
        let easeOut = CABasicAnimation(keyPath: "path")
        easeOut.fromValue = UIBezierPath(ovalInRect: CGRect(origin: finalShapeOrigin, size: expandedSize)).CGPath
        easeOut.toValue = UIBezierPath(ovalInRect: CGRect(origin: disappearingOrigin, size: disappearingSize)).CGPath
        easeOut.duration = 0.2
        easeOut.beginTime = 0.4
        easeOut.removedOnCompletion = false
        easeOut.fillMode = kCAFillModeForwards
        
        
        //Initialize animation group
        animationGroup.animations = [easeIn, easeOut]
        animationGroup.duration = 0.8
        animationGroup.removedOnCompletion = false
        animationGroup.fillMode = kCAFillModeForwards
        
        
        //Add animation group
        focusFill.addAnimation(animationGroup, forKey: nil)
        focusStroke.addAnimation(animationGroup, forKey: nil)
        focusStrokeBorder.addAnimation(animationGroup, forKey: nil)
        CATransaction.commit()
        
    }
}