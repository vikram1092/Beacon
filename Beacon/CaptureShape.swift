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
    let progress = CABasicAnimation(keyPath: "strokeEnd")
    let progress2 = CABasicAnimation(keyPath: "strokeEnd")
    let expansion = CABasicAnimation(keyPath: "path")
    let rotate = CABasicAnimation(keyPath: "transform.rotation")
    let reverseRotate = CABasicAnimation(keyPath: "transform.rotation")
    let primaryColor = BeaconColors().redColor
    let secondaryColor = BeaconColors().blueColor
    var sendView = UILabel()
    let recordingDuration = 10.0
    var timer = Timer()
    var timerValue = 0.0
    var initialized = false
    
    //Declare shape layers
    let auxRing = CAShapeLayer()
    let beaconRing = CAShapeLayer()
    let border1 = CAShapeLayer()
    let border2 = CAShapeLayer()
    let record = CAShapeLayer()
    let record2 = CAShapeLayer()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal func initializeViews() {
        
        
        if !initialized {
            
            //Initialize variables
            initialized = true
            let frame = self.bounds
            self.transform = CGAffineTransform(rotationAngle: -CGFloat(M_PI)/2)
            
            
            //Set auxRing
            auxRing.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
            auxRing.fillColor = UIColor.clear.cgColor
            auxRing.strokeColor = UIColor.white.cgColor
            auxRing.lineWidth = 5
            auxRing.strokeStart = 0.05
            auxRing.strokeEnd = 0.35
            auxRing.lineCap = kCALineCapRound
            
            
            //Set auxRing's border
            border2.path = auxRing.path
            border2.fillColor = UIColor.clear.cgColor
            border2.strokeColor = UIColor.black.cgColor
            border2.lineWidth = auxRing.lineWidth + 0.5
            border2.strokeStart = auxRing.strokeStart
            border2.strokeEnd = auxRing.strokeEnd
            border2.lineCap = kCALineCapRound
            
            
            
            //Set beaconRing
            beaconRing.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
            beaconRing.fillColor = UIColor.clear.cgColor
            beaconRing.strokeColor = UIColor.white.cgColor
            beaconRing.lineWidth = 5
            beaconRing.strokeStart = 0.4
            beaconRing.strokeEnd = 1
            beaconRing.borderWidth = 1
            beaconRing.borderColor = UIColor.black.cgColor
            beaconRing.lineCap = kCALineCapRound
            
            
            //Set beaconRing's border
            border1.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
            border1.fillColor = beaconRing.fillColor
            border1.strokeColor = UIColor.black.cgColor
            border1.lineWidth = beaconRing.lineWidth + 0.5
            border1.strokeStart = beaconRing.strokeStart
            border1.strokeEnd = beaconRing.strokeEnd
            border1.borderColor = UIColor.black.cgColor
            border1.lineCap = kCALineCapRound
            
            
            //Add all to view
            self.layer.addSublayer(border2)
            self.layer.addSublayer(auxRing)
            self.layer.addSublayer(border1)
            self.layer.addSublayer(beaconRing)
            
            
            //Initialize sending view
            sendView = self.viewWithTag(1) as! UILabel
            sendView.backgroundColor = secondaryColor
            sendView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI)/2)
            sendView.clipsToBounds = true
            sendView.layer.cornerRadius = sendView.bounds.width/2
            sendView.layer.borderWidth = 0.5

        }
    }
    
    
    internal func startRecording() {
        
        
        //Initialize record layers
        initializeRecordLayers()
        self.layer.addSublayer(record)
        self.layer.addSublayer(record2)
        
        
        //Start timer
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(incrementTimer), userInfo: nil, repeats: true)
        timer.fire()
        
        
        //Initialize animations
        initializeAnimations()
        
        
        //Add animations to layers
        beaconRing.add(expansion, forKey: "expansion")
        border1.add(expansion, forKey: "expansion")
        auxRing.add(expansion, forKey: "expansion")
        border2.add(expansion, forKey: "expansion")
        record.add(expansion, forKey: "expansion")
        record2.add(expansion, forKey: "expansion")
        record.add(progress, forKey: "progress")
        record2.add(progress2, forKey: "progress")
        
    }
    
    
    internal func initializeRecordLayers() {
        
        
        //Initialize recording layer 1
        record.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
        record.fillColor = UIColor.clear.cgColor
        record.strokeColor = primaryColor.cgColor
        record.lineWidth = beaconRing.lineWidth
        record.strokeStart = 0.4
        record.strokeEnd = 0.4
        record.lineCap = kCALineCapRound
        
        //Initialize recording layer 2
        record2.path = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
        record2.fillColor = UIColor.clear.cgColor
        record2.strokeColor = secondaryColor.cgColor
        record2.lineWidth = beaconRing.lineWidth
        record2.strokeStart = auxRing.strokeStart
        record2.strokeEnd = auxRing.strokeStart
        record2.lineCap = kCALineCapRound
        
    }
    
    
    internal func initializeAnimations() {
        
        
        //Configure recording animation
        progress.duration = recordingDuration
        progress.fromValue = 0.4
        progress.toValue = 1.0
        progress.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progress.isRemovedOnCompletion = false
        progress.fillMode = kCAFillModeBoth
        
        //Configure recording animation
        progress2.duration = recordingDuration
        progress2.fromValue = 0.05
        progress2.toValue = 0.35
        progress2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progress2.isRemovedOnCompletion = false
        progress2.fillMode = kCAFillModeBoth
        
        //Configure expansion for beaconRing
        expansion.duration = 0.5
        expansion.fromValue = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
        expansion.toValue = UIBezierPath(ovalIn: CGRect(x: -6.0, y: -6.0, width: frame.width + 12, height: frame.height + 12)).cgPath
        expansion.isRemovedOnCompletion = false
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
            
            beaconRing.add(expansion, forKey: "expansion")
            border1.add(expansion, forKey: "expansion")
            auxRing.add(expansion, forKey: "expansion")
            border2.add(expansion, forKey: "expansion")
            record.add(expansion, forKey: "expansion")
            record2.add(expansion, forKey: "expansion")
        }
        
        //Do animations to transition
        completeRings()
        showSendView()
        spin()
        
    }
    
    
    internal func completeRings() {
        
        
        //Adjust progress animations and add them again to complete the rings
        progress.fromValue = max(record.strokeStart + 0.6 * CGFloat(timerValue) + 0.1, 0.4)
        progress2.fromValue = max(record2.strokeStart + 0.3 * CGFloat(timerValue) + 0.05, 0.05)
        
        progress.duration = 0.5
        progress2.duration = 0.5
        
        //Animate completion and remove underlying rings
        CATransaction.begin()
        CATransaction.setCompletionBlock { 
            
            //Remove white rings
            if self.sendView.alpha != 0 {
                
                self.beaconRing.removeFromSuperlayer()
                self.auxRing.removeFromSuperlayer()
            }
        }
        
        record.add(progress, forKey: nil)
        record2.add(progress2, forKey: nil)
        
        CATransaction.commit()
    }
    
    
    internal func spin() {
        
        
        //Spin animation
        rotate.fromValue = -CGFloat(M_PI)/2
        rotate.toValue = 3 * CGFloat(M_PI)/2
        rotate.duration = 20
        rotate.repeatCount = HUGE
        rotate.fillMode = kCAFillModeForwards
        rotate.isRemovedOnCompletion = false
        
        
        //Counter spin animation for send view
        reverseRotate.fromValue = CGFloat(M_PI)/2
        reverseRotate.toValue = -3 * CGFloat(M_PI)/2
        reverseRotate.duration = 20
        reverseRotate.repeatCount = HUGE
        reverseRotate.fillMode = kCAFillModeForwards
        reverseRotate.isRemovedOnCompletion = false
        
        self.layer.add(rotate, forKey: nil)
        sendView.layer.add(reverseRotate, forKey: nil)
        
    }
    
    
    internal func showSendView() {
        
        //Show send view
        UIView.animate(withDuration: 0.5, animations: { 
            
            self.sendView.alpha = 1.0
        }) 
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
        
        let originalPath = UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).cgPath
        beaconRing.path = originalPath
        auxRing.path = originalPath
        border1.path = originalPath
        border2.path = originalPath
        
        
        record.removeFromSuperlayer()
        record2.removeFromSuperlayer()
        self.layer.addSublayer(beaconRing)
        self.layer.addSublayer(auxRing)
    }
}
