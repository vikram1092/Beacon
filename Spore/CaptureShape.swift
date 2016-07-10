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
    
    
    //Declare animations and parameters for recording
    let progress = CABasicAnimation(keyPath: "strokeStart")
    let progress2 = CABasicAnimation(keyPath: "strokeStart")
    let expansion = CABasicAnimation(keyPath: "path")
    let rotate = CABasicAnimation(keyPath: "transform.rotation")
    let reverseRotate = CABasicAnimation(keyPath: "transform.rotation")
    let primaryColor = UIColor(red: 195.0/255.0, green: 58.0/255.0, blue: 62.0/255.0, alpha: 1).CGColor
    let secondaryColor = UIColor(red: 50.0/255.0, green: 137.0/255.0, blue: 203.0/255.0, alpha: 1).CGColor
    var sendView = UILabel()
    let recordingDuration = 10.0
    var timer = NSTimer()
    var timerValue = 0.0
    
    //Declare shape layers
    let auxRing = CAShapeLayer()
    let beaconRing = CAShapeLayer()
    let border1 = CAShapeLayer()
    let border2 = CAShapeLayer()
    let record = CAShapeLayer()
    let record2 = CAShapeLayer()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        super.init(coder: aDecoder)
        
        //Initialize variables
        let frame = super.frame
        self.transform = CGAffineTransformMakeRotation(-CGFloat(M_PI)/2)
        
        
        //Set auxRing
        auxRing.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        auxRing.fillColor = UIColor.clearColor().CGColor
        auxRing.strokeColor = UIColor.whiteColor().CGColor
        auxRing.lineWidth = 5
        auxRing.strokeStart = 0.05
        auxRing.strokeEnd = 0.35
        auxRing.lineCap = kCALineCapRound
        
        
        //Set auxRing's border
        border2.path = auxRing.path
        border2.fillColor = UIColor.clearColor().CGColor
        border2.strokeColor = UIColor.blackColor().CGColor
        border2.lineWidth = auxRing.lineWidth + 0.5
        border2.strokeStart = auxRing.strokeStart
        border2.strokeEnd = auxRing.strokeEnd
        border2.lineCap = kCALineCapRound
        
        
        
        //Set beaconRing
        beaconRing.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        beaconRing.fillColor = UIColor.clearColor().CGColor
        beaconRing.strokeColor = UIColor.whiteColor().CGColor
        beaconRing.lineWidth = 5
        beaconRing.strokeStart = 0.4
        beaconRing.strokeEnd = 1
        beaconRing.borderWidth = 1
        beaconRing.borderColor = UIColor.blackColor().CGColor
        beaconRing.lineCap = kCALineCapRound
        
        
        //Set beaconRing's border
        border1.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        border1.fillColor = beaconRing.fillColor
        border1.strokeColor = UIColor.blackColor().CGColor
        border1.lineWidth = beaconRing.lineWidth + 0.5
        border1.strokeStart = beaconRing.strokeStart
        border1.strokeEnd = beaconRing.strokeEnd
        border1.borderColor = UIColor.blackColor().CGColor
        border1.lineCap = kCALineCapRound
        
        
        //Add all to view
        self.layer.addSublayer(border2)
        self.layer.addSublayer(auxRing)
        self.layer.addSublayer(border1)
        self.layer.addSublayer(beaconRing)
        
        
        //Initialize sending view
        sendView = self.viewWithTag(1) as! UILabel
        sendView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI)/2)
        
    }
    
    
    internal func startRecording() {
        
        
        //Initialize record layers
        initializeRecordLayers()
        self.layer.addSublayer(record)
        self.layer.addSublayer(record2)
        
        
        //Start timer
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(incrementTimer), userInfo: nil, repeats: true)
        timer.fire()
        
        
        //Initialize animations
        initializeAnimations()
        
        
        //Add animations to layers
        beaconRing.addAnimation(expansion, forKey: "expansion")
        border1.addAnimation(expansion, forKey: "expansion")
        auxRing.addAnimation(expansion, forKey: "expansion")
        border2.addAnimation(expansion, forKey: "expansion")
        record.addAnimation(expansion, forKey: "expansion")
        record2.addAnimation(expansion, forKey: "expansion")
        record.addAnimation(progress, forKey: "progress")
        record2.addAnimation(progress2, forKey: "progress")
        
    }
    
    
    internal func initializeRecordLayers() {
        
        
        //Initialize recording layer 1
        record.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        record.fillColor = UIColor.clearColor().CGColor
        record.strokeColor = primaryColor
        record.lineWidth = beaconRing.lineWidth
        record.strokeStart = 1.0
        record.strokeEnd = 1.0
        record.lineCap = kCALineCapRound
        
        //Initialize recording layer 2
        record2.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        record2.fillColor = UIColor.clearColor().CGColor
        record2.strokeColor = secondaryColor
        record2.lineWidth = beaconRing.lineWidth
        record2.strokeStart = auxRing.strokeEnd
        record2.strokeEnd = auxRing.strokeEnd
        record2.lineCap = kCALineCapRound
        
    }
    
    
    internal func initializeAnimations() {
        
        
        //Configure recording animation
        progress.duration = recordingDuration
        progress.fromValue = 1.0
        progress.toValue = 0.4
        progress.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progress.removedOnCompletion = false
        progress.fillMode = kCAFillModeBoth
        
        //Configure recording animation
        progress2.duration = recordingDuration
        progress2.fromValue = 0.35
        progress2.toValue = 0.05
        progress2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progress2.removedOnCompletion = false
        progress2.fillMode = kCAFillModeBoth
        
        //Configure expansion for beaconRing
        expansion.duration = 0.5
        expansion.fromValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        expansion.toValue = UIBezierPath(ovalInRect: CGRect(x: -6.0, y: -6.0, width: frame.width + 12, height: frame.height + 12)).CGPath
        expansion.removedOnCompletion = false
        expansion.fillMode = kCAFillModeBoth
        
    }
    
    
    internal func incrementTimer() {
        
        timerValue += timer.timeInterval * 0.1
    }
    
    
    internal func transitionToSendMode() {
        
        
        //Add layers and animations if they're not there (in case user is taking a picture)
        if !self.layer.sublayers!.contains(record) {
            
            
            //Initialize and add record layers
            initializeRecordLayers()
            
            self.layer.addSublayer(record)
            self.layer.addSublayer(record2)
            
            //Initialize and add animations
            initializeAnimations()
            
            beaconRing.addAnimation(expansion, forKey: "expansion")
            border1.addAnimation(expansion, forKey: "expansion")
            auxRing.addAnimation(expansion, forKey: "expansion")
            border2.addAnimation(expansion, forKey: "expansion")
            record.addAnimation(expansion, forKey: "expansion")
            record2.addAnimation(expansion, forKey: "expansion")
        }
        
        
        //Complete rings and show send views
        completeRings()
        showSendView()
        spin()
    }
    
    
    internal func completeRings() {
        
        
        
        //Adjust progress animations and add them again to complete the rings
        progress.fromValue = max(record.strokeStart - 0.6 * CGFloat(timerValue) - 0.1, 0.4)
        progress2.fromValue = max(record2.strokeStart - 0.3 * CGFloat(timerValue) - 0.05, 0.05)
        
        progress.duration = 0.5
        progress2.duration = 0.5
        
        record.addAnimation(progress, forKey: nil)
        record2.addAnimation(progress2, forKey: nil)
        
    }
    
    
    internal func spin() {
        
        
        //Spin animation
        rotate.fromValue = -CGFloat(M_PI)/2
        rotate.toValue = 3 * CGFloat(M_PI)/2
        rotate.duration = 20
        rotate.repeatCount = HUGE
        rotate.fillMode = kCAFillModeForwards
        rotate.removedOnCompletion = false
        
        
        //Counter spin animation for send view
        reverseRotate.fromValue = CGFloat(M_PI)/2
        reverseRotate.toValue = -3 * CGFloat(M_PI)/2
        reverseRotate.duration = 20
        reverseRotate.repeatCount = HUGE
        reverseRotate.fillMode = kCAFillModeForwards
        reverseRotate.removedOnCompletion = false
        
        self.layer.addAnimation(rotate, forKey: nil)
        sendView.layer.addAnimation(reverseRotate, forKey: nil)
    }
    
    
    internal func showSendView() {
        
        //Show send view
        UIView.animateWithDuration(0.5) { 
            
            self.sendView.alpha = 1.0
        }
    }
    
    
    internal func resetShape() {
        
        
        //Reset timer, remove animations to layers, reset dimensions and remove the recording layer
        timer.invalidate()
        timerValue = 0.0
        sendView.alpha = 0.0
        
        self.layer.removeAllAnimations()
        sendView.layer.removeAllAnimations()
        beaconRing.removeAllAnimations()
        border1.removeAllAnimations()
        auxRing.removeAllAnimations()
        border2.removeAllAnimations()
        record.removeAllAnimations()
        record2.removeAllAnimations()
        
        let originalPath = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        beaconRing.path = originalPath
        auxRing.path = originalPath
        border1.path = originalPath
        border2.path = originalPath
        
        
        record.removeFromSuperlayer()
        record2.removeFromSuperlayer()
    }
    
}