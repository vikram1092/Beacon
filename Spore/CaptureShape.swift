//
//  CameraButton.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/26/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class CaptureShape: UIView {
    
    let background = CAShapeLayer()
    let border = CAShapeLayer()
    let record = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let frame = super.frame
        self.transform = CGAffineTransformMakeRotation( -90.0 * CGFloat(M_PI) / 180.0)
        
        //Set background
        background.path = UIBezierPath(ovalInRect: CGRect(x: 5.0, y: 5.0, width: frame.width - 10, height: frame.height - 10)).CGPath
        background.fillColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.7).CGColor
        
        //Set border
        border.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        border.fillColor = UIColor.clearColor().CGColor
        border.strokeColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).CGColor
        border.lineWidth = 3
        border.strokeStart = 0.4
        border.strokeEnd = 1
        border.borderColor = UIColor.blackColor().CGColor
        border.lineCap = kCALineCapRound

        self.layer.addSublayer(background)
        self.layer.addSublayer(border)
    }
    
    
    internal func startRecording() {
        
        //Set recording stroke
        record.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        record.fillColor = UIColor.clearColor().CGColor
        record.strokeColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.9).CGColor
        record.lineWidth = 3
        record.strokeStart = 1.0
        record.strokeEnd = 1.0
        record.lineCap = kCALineCapRound
        
        self.layer.addSublayer(record)
        
        //Animate the timer
        let progress = CABasicAnimation(keyPath: "strokeStart")
        let expansion = CABasicAnimation(keyPath: "path")
        let width = CABasicAnimation(keyPath: "lineWidth")
        
        //Configure animation
        progress.duration = 10
        progress.fromValue = 1.0
        progress.toValue = 0.4
        progress.removedOnCompletion = false
        progress.fillMode = kCAFillModeForwards
        
        //Configure expansion
        expansion.duration = 1
        expansion.fromValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        expansion.toValue = UIBezierPath(ovalInRect: CGRect(x: -8.0, y: -8.0, width: frame.width + 16, height: frame.height + 16)).CGPath
        expansion.removedOnCompletion = false
        expansion.fillMode = kCAFillModeForwards
        
        
        //Configure width change
        width.duration = 2
        width.fromValue = 3
        width.toValue = 5
        width.removedOnCompletion = false
        width.fillMode = kCAFillModeForwards
            
            
        record.addAnimation(progress, forKey: nil)
        record.addAnimation(expansion, forKey: nil)
        record.addAnimation(width, forKey: nil)
        
        border.addAnimation(expansion, forKey: nil)
        border.addAnimation(width, forKey: nil)
    }
    
    internal func stopRecording() {
        
        border.removeAllAnimations()
        border.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        border.lineWidth = 3
        record.removeFromSuperlayer()
    }
    
}