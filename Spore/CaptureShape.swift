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
    
    
    let auxRing = CAShapeLayer()
    let beaconRing = CAShapeLayer()
    let border1 = CAShapeLayer()
    let border2 = CAShapeLayer()
    let record = CAShapeLayer()
    let record2 = CAShapeLayer()
    var beacons = UIImageView()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        super.init(coder: aDecoder)
        
        //Initialize variables
        let frame = super.frame
        self.transform = CGAffineTransformMakeRotation(-CGFloat(M_PI)/2)
        
        
        //Set auxRing
        auxRing.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        auxRing.fillColor = UIColor.clearColor().CGColor
        auxRing.strokeColor = UIColor.whiteColor().CGColor
        //(red: 0.85, green: 0.85, blue: 0.85, alpha: 0.7).CGColor
            //UIColor(red: 195.0/255.0, green: 77.0/255.0, blue: 84.0/255.0, alpha: 1).CGColor
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
        
        
        //Initialize beacons image
        beacons = self.viewWithTag(5) as! UIImageView
        beacons.image = UIImage(named: "BeaconsButton")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        beacons.tintColor = UIColor.whiteColor()
        beacons.contentMode = UIViewContentMode.Center
        beacons.transform = CGAffineTransformMakeRotation(CGFloat(M_PI/2))
        
        
        //Add all to view
        self.layer.addSublayer(border2)
        self.layer.addSublayer(auxRing)
        self.layer.addSublayer(border1)
        self.layer.addSublayer(beaconRing)
        self.addSubview(beacons)
        
    }
    
    
    internal func startRecording() {
        
        
        //Add recording layer
        record.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        record.fillColor = UIColor.clearColor().CGColor
        record.strokeColor = UIColor(red: 195.0/255.0, green: 77.0/255.0, blue: 84.0/255.0, alpha: 1).CGColor
        //UIColor(red: 50.0/255.0, green: 137.0/255.0, blue: 203.0/255.0, alpha: 1).CGColor
        record.lineWidth = beaconRing.lineWidth
        record.strokeStart = 1.0
        record.strokeEnd = 1.0
        record.lineCap = kCALineCapRound
        
        //Add recording layer
        record2.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        record2.fillColor = UIColor.clearColor().CGColor
        record2.strokeColor = UIColor(red: 50.0/255.0, green: 137.0/255.0, blue: 203.0/255.0, alpha: 1).CGColor
        record2.lineWidth = beaconRing.lineWidth
        record2.strokeStart = auxRing.strokeEnd
        record2.strokeEnd = auxRing.strokeEnd
        record2.lineCap = kCALineCapRound
        
        self.layer.addSublayer(record)
        self.layer.addSublayer(record2)
        
        //Declare animations and parameters for recording
        let progress = CABasicAnimation(keyPath: "strokeStart")
        let progress2 = CABasicAnimation(keyPath: "strokeStart")
        let expansion = CABasicAnimation(keyPath: "path")
        let recordingDuration = 10.0

        
        //Configure recording animation
        progress.duration = recordingDuration
        progress.fromValue = 1.0
        progress.toValue = 0.4
        progress.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progress.removedOnCompletion = false
        progress.fillMode = kCAFillModeForwards
        
        //Configure recording animation
        progress2.duration = recordingDuration
        progress2.fromValue = 0.35
        progress2.toValue = 0.05
        progress2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        progress2.removedOnCompletion = false
        progress2.fillMode = kCAFillModeForwards
        
        //Configure expansion for beaconRing
        expansion.duration = 1
        expansion.fromValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        expansion.toValue = UIBezierPath(ovalInRect: CGRect(x: -6.0, y: -6.0, width: frame.width + 12, height: frame.height + 12)).CGPath
        expansion.removedOnCompletion = false
        expansion.fillMode = kCAFillModeForwards
        
        //Add animations to layers
        beaconRing.addAnimation(expansion, forKey: nil)
        border1.addAnimation(expansion, forKey: nil)
        auxRing.addAnimation(expansion, forKey: nil)
        border2.addAnimation(expansion, forKey: nil)
        record.addAnimation(expansion, forKey: nil)
        record2.addAnimation(expansion, forKey: nil)
        record.addAnimation(progress, forKey: nil)
        record2.addAnimation(progress2, forKey: nil)
        
    }
    
    
    internal func showBeaconsView() {
        
        
        //Show beacons view
        UIView.animateWithDuration(0.2) { 
            
            self.beacons.alpha = 1
        }
    }
    
    
    internal func hideBeaconsView() {
        
        UIView.animateWithDuration(0.2) { 
            
            self.beacons.alpha = 0
        }
    }
    
    
    internal func stopRecording() {
        
        
        //Remove animations to layers, reset dimensions and remove the recording layer
        beaconRing.removeAllAnimations()
        border1.removeAllAnimations()
        auxRing.removeAllAnimations()
        border2.removeAllAnimations()
        
        record.removeFromSuperlayer()
        record2.removeFromSuperlayer()
        
    }
    
}