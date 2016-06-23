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
    let ring = CAShapeLayer()
    let border = CAShapeLayer()
    let record = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        //Initialize variables
        let frame = super.frame
        self.transform = CGAffineTransformMakeRotation( -90.0 * CGFloat(M_PI) / 180.0)
        
        
        //Set background
        background.path = UIBezierPath(ovalInRect: CGRect(x: 8.0, y: 8.0, width: frame.width - 16, height: frame.height - 16)).CGPath
        background.fillColor = UIColor.clearColor().CGColor
        background.strokeColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.9).CGColor
        background.lineWidth = 2
        
        
        //Set ring
        ring.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        ring.fillColor = UIColor.clearColor().CGColor
        ring.strokeColor = UIColor.whiteColor().CGColor
        ring.lineWidth = 3
        ring.strokeStart = 0.4
        ring.strokeEnd = 1
        ring.borderWidth = 1
        ring.borderColor = UIColor.blackColor().CGColor
        ring.lineCap = kCALineCapRound
        
        //Set border
        border.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        border.fillColor = ring.fillColor
        border.strokeColor = UIColor.blackColor().CGColor
        border.lineWidth = ring.lineWidth + 0.5
        border.strokeStart = ring.strokeStart
        border.strokeEnd = ring.strokeEnd
        border.borderColor = UIColor.blackColor().CGColor
        border.lineCap = kCALineCapRound
        
        self.layer.addSublayer(background)
        self.layer.addSublayer(border)
        self.layer.addSublayer(ring)
        
        
    }
    
    
    internal func startRecording() {
        
        //Set recording stroke
        record.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        record.fillColor = UIColor.clearColor().CGColor
        record.strokeColor = UIColor(red: 50.0/255.0, green: 137.0/255.0, blue: 203.0/255.0, alpha: 1).CGColor
        record.lineWidth = 3
        record.strokeStart = 1.0
        record.strokeEnd = 1.0
        record.lineCap = kCALineCapRound
        
        self.layer.addSublayer(record)
        
        //Declare animations for recording
        let progress = CABasicAnimation(keyPath: "strokeStart")
        let expansion = CABasicAnimation(keyPath: "path")
        let ringWidth = CABasicAnimation(keyPath: "lineWidth")
        let borderWidth = CABasicAnimation(keyPath: "lineWidth")
        
        //Configure recording
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
        
        
        //Configure ring and record width change
        ringWidth.duration = 2
        ringWidth.fromValue = 3
        ringWidth.toValue = 5
        ringWidth.removedOnCompletion = false
        ringWidth.fillMode = kCAFillModeForwards
        
        //Configure border change. Difference is in the lineWidth values
        borderWidth.duration = 2
        borderWidth.fromValue = 4
        borderWidth.toValue = 6
        borderWidth.removedOnCompletion = false
        borderWidth.fillMode = kCAFillModeForwards
            
        //Add animations to layers
        record.addAnimation(progress, forKey: nil)
        record.addAnimation(expansion, forKey: nil)
        record.addAnimation(ringWidth, forKey: nil)
        
        ring.addAnimation(expansion, forKey: nil)
        ring.addAnimation(ringWidth, forKey: nil)
        
        border.addAnimation(expansion, forKey: nil)
        border.addAnimation(borderWidth, forKey: nil)
    }
    
    internal func stopRecording() {
        
        
        //Remove animations to layers, reset dimensions and remove the recording layer
        ring.removeAllAnimations()
        border.removeAllAnimations()
        
        ring.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        ring.lineWidth = 3
        
        border.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        border.lineWidth = ring.lineWidth + 1
        
        record.removeFromSuperlayer()
    }
    
}