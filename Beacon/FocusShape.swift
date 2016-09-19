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
        self.isUserInteractionEnabled = false
    }
    
    
    init(drawPoint: CGPoint) {
        
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        
        self.isUserInteractionEnabled = false
        self.center = drawPoint
        drawFocus(drawPoint)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal func drawFocus(_ focusPoint: CGPoint) {
        
        
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
        focusStrokePrimary.path = UIBezierPath(ovalIn: CGRect(origin: originalShapeOrigin, size: originalSize)).cgPath
        focusStrokePrimary.strokeColor = UIColor.white.cgColor
        focusStrokePrimary.fillColor = UIColor.clear.cgColor
        focusStrokePrimary.lineWidth = 3
        focusStrokePrimary.strokeStart = 0.0
        focusStrokePrimary.strokeEnd = 0.6
        focusStrokePrimary.lineCap = kCALineCapRound
        
        focusStrokePrimaryBorder.path = UIBezierPath(ovalIn: CGRect(origin: originalShapeOrigin, size: originalSize)).cgPath
        focusStrokePrimaryBorder.strokeColor = UIColor.lightGray.cgColor
        focusStrokePrimaryBorder.fillColor = UIColor.clear.cgColor
        focusStrokePrimaryBorder.lineWidth = focusStrokePrimary.lineWidth + 1.0
        focusStrokePrimaryBorder.strokeStart = focusStrokePrimary.strokeStart
        focusStrokePrimaryBorder.strokeEnd = focusStrokePrimary.strokeEnd
        focusStrokePrimaryBorder.lineCap = kCALineCapRound
        
        
        focusStrokeSecondary.path = UIBezierPath(ovalIn: CGRect(origin: originalShapeOrigin, size: originalSize)).cgPath
        focusStrokeSecondary.strokeColor = UIColor.white.cgColor
        focusStrokeSecondary.fillColor = UIColor.clear.cgColor
        focusStrokeSecondary.lineWidth = 3
        focusStrokeSecondary.strokeStart = 0.7
        focusStrokeSecondary.strokeEnd = 0.9
        focusStrokeSecondary.lineCap = kCALineCapRound
        
        focusStrokeSecondaryBorder.path = UIBezierPath(ovalIn: CGRect(origin: originalShapeOrigin, size: originalSize)).cgPath
        focusStrokeSecondaryBorder.strokeColor = UIColor.lightGray.cgColor
        focusStrokeSecondaryBorder.fillColor = UIColor.clear.cgColor
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
        easeIn.fromValue = UIBezierPath(ovalIn: CGRect(origin: originalShapeOrigin, size: originalSize)).cgPath
        easeIn.toValue = UIBezierPath(ovalIn: CGRect(origin: finalShapeOrigin, size: expandedSize)).cgPath
        easeIn.duration = 0.2
        easeIn.beginTime = 0.0
        easeIn.isRemovedOnCompletion = false
        easeIn.fillMode = kCAFillModeForwards
        
        
        //Ease out animation
        let easeOut = CABasicAnimation(keyPath: "path")
        easeOut.fromValue = UIBezierPath(ovalIn: CGRect(origin: finalShapeOrigin, size: expandedSize)).cgPath
        easeOut.toValue = UIBezierPath(ovalIn: CGRect(origin: disappearingOrigin, size: disappearingSize)).cgPath
        easeOut.duration = 0.2
        easeOut.beginTime = 0.4
        easeOut.isRemovedOnCompletion = false
        easeOut.fillMode = kCAFillModeForwards
        
        
        //Rotation animation
        let rotate = CABasicAnimation(keyPath: "transform.rotation")
        rotate.fromValue = -CGFloat(M_PI)/2
        rotate.toValue = 3 * CGFloat(M_PI)/2
        rotate.duration = 0.8
        rotate.fillMode = kCAFillModeForwards
        rotate.isRemovedOnCompletion = false
        
        
        //Initialize animation group
        animationGroup.animations = [easeIn, easeOut]
        animationGroup.duration = 0.8
        animationGroup.isRemovedOnCompletion = false
        animationGroup.fillMode = kCAFillModeForwards
        
        
        //Add animation group
        self.layer.add(rotate, forKey: nil)
        focusStrokePrimary.add(animationGroup, forKey: nil)
        focusStrokePrimaryBorder.add(animationGroup, forKey: nil)
        focusStrokeSecondary.add(animationGroup, forKey: nil)
        focusStrokeSecondaryBorder.add(animationGroup, forKey: nil)
        CATransaction.commit()
    
    }
}
