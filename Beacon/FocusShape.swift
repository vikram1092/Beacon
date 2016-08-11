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
    
    
    var focusStrokePrimary = CAShapeLayer()
    var focusStrokePrimaryBorder = CAShapeLayer()
    var focusStrokeSecondary = CAShapeLayer()
    var focusStrokeSecondaryBorder = CAShapeLayer()
    
    
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
        focusStrokePrimary.removeFromSuperlayer()
        focusStrokeSecondary.removeFromSuperlayer()
        focusStrokePrimaryBorder.removeFromSuperlayer()
        focusStrokeSecondaryBorder.removeFromSuperlayer()
        
        let originalSize = CGSize(width: 0.0, height: 0.0)
        let expandedSize = CGSize(width: 35.0, height: 35.0)
        let disappearingSize = CGSize(width: 25.0, height: 25.0)
        let x = self.bounds.width/2
        let y = self.bounds.height/2
        let originalShapeOrigin = CGPoint(x: -originalSize.width/2 + x, y: -originalSize.height/2 + y)
        let finalShapeOrigin = CGPoint(x:-expandedSize.width/2 + x, y: -expandedSize.height/2 + y)
        let disappearingOrigin = CGPoint(x: -disappearingSize.width/2 + x, y: -disappearingSize.height/2 + y)
        
        
        //Define focus shapes
        focusStrokePrimary.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusStrokePrimary.strokeColor = UIColor.whiteColor().CGColor
        focusStrokePrimary.fillColor = UIColor.clearColor().CGColor
        focusStrokePrimary.lineWidth = 3
        focusStrokePrimary.strokeStart = 0.0
        focusStrokePrimary.strokeEnd = 0.6
        focusStrokePrimary.lineCap = kCALineCapRound
        
        focusStrokePrimaryBorder.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusStrokePrimaryBorder.strokeColor = UIColor.lightGrayColor().CGColor
        focusStrokePrimaryBorder.fillColor = UIColor.clearColor().CGColor
        focusStrokePrimaryBorder.lineWidth = focusStrokePrimary.lineWidth + 1.0
        focusStrokePrimaryBorder.strokeStart = focusStrokePrimary.strokeStart
        focusStrokePrimaryBorder.strokeEnd = focusStrokePrimary.strokeEnd
        focusStrokePrimaryBorder.lineCap = kCALineCapRound
        
        
        focusStrokeSecondary.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusStrokeSecondary.strokeColor = UIColor.whiteColor().CGColor
        focusStrokeSecondary.fillColor = UIColor.clearColor().CGColor
        focusStrokeSecondary.lineWidth = 3
        focusStrokeSecondary.strokeStart = 0.7
        focusStrokeSecondary.strokeEnd = 0.9
        focusStrokeSecondary.lineCap = kCALineCapRound
        
        focusStrokeSecondaryBorder.path = UIBezierPath(ovalInRect: CGRect(origin: originalShapeOrigin, size: originalSize)).CGPath
        focusStrokeSecondaryBorder.strokeColor = UIColor.lightGrayColor().CGColor
        focusStrokeSecondaryBorder.fillColor = UIColor.clearColor().CGColor
        focusStrokeSecondaryBorder.lineWidth = focusStrokeSecondary.lineWidth + 1.0
        focusStrokeSecondaryBorder.strokeStart = focusStrokeSecondary.strokeStart
        focusStrokeSecondaryBorder.strokeEnd = focusStrokeSecondary.strokeEnd
        focusStrokeSecondaryBorder.lineCap = kCALineCapRound
        
        
        self.layer.addSublayer(focusStrokePrimaryBorder)
        self.layer.addSublayer(focusStrokePrimary)
        self.layer.addSublayer(focusStrokeSecondaryBorder)
        self.layer.addSublayer(focusStrokeSecondary)
        
        
        //Add animations
        let animationGroup = CAAnimationGroup()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            
            self.focusStrokePrimaryBorder.removeFromSuperlayer()
            self.focusStrokePrimary.removeFromSuperlayer()
            self.focusStrokeSecondaryBorder.removeFromSuperlayer()
            self.focusStrokeSecondary.removeFromSuperlayer()
            self.layer.removeAllAnimations()
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
        
        
        //Rotation animation
        let rotate = CABasicAnimation(keyPath: "transform.rotation")
        rotate.fromValue = -CGFloat(M_PI)/2
        rotate.toValue = 3 * CGFloat(M_PI)/2
        rotate.duration = 0.8
        rotate.fillMode = kCAFillModeForwards
        rotate.removedOnCompletion = false
        
        
        //Initialize animation group
        animationGroup.animations = [easeIn, easeOut]
        animationGroup.duration = 0.8
        animationGroup.removedOnCompletion = false
        animationGroup.fillMode = kCAFillModeForwards
        
        
        //Add animation group
        self.layer.addAnimation(rotate, forKey: nil)
        focusStrokePrimary.addAnimation(animationGroup, forKey: nil)
        focusStrokePrimaryBorder.addAnimation(animationGroup, forKey: nil)
        focusStrokeSecondary.addAnimation(animationGroup, forKey: nil)
        focusStrokeSecondaryBorder.addAnimation(animationGroup, forKey: nil)
        CATransaction.commit()
    
    }
}