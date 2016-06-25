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
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        super.init(coder: aDecoder)
        
        //Initialize variables
        let frame = super.frame
        self.transform = CGAffineTransformMakeRotation( -90.0 * CGFloat(M_PI) / 180.0)
        
        
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
        
        
        //Add all to view
        self.layer.addSublayer(border2)
        self.layer.addSublayer(auxRing)
        self.layer.addSublayer(border1)
        self.layer.addSublayer(beaconRing)
        
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
        
        self.layer.addSublayer(record)
        
        //Declare animations and parameters for recording
        let progress = CABasicAnimation(keyPath: "strokeStart")
        let expansion = CABasicAnimation(keyPath: "path")
        let contraction = CABasicAnimation(keyPath: "path")
        let beaconRingWidth = CABasicAnimation(keyPath: "lineWidth")
        let border2Width = CABasicAnimation(keyPath: "lineWidth")
        let strokeStartExpansion = CABasicAnimation(keyPath: "strokeStart")
        let strokeEndExpansion = CABasicAnimation(keyPath: "strokeEnd")
        let recordingDuration = 10.0
        let otherDuration = 1.0
        
        //Configure recording animation
        progress.duration = recordingDuration
        progress.fromValue = 1.0
        progress.toValue = 0.4
        progress.removedOnCompletion = false
        progress.fillMode = kCAFillModeForwards
        
        
        //Configure expansion for beaconRing
        expansion.duration = 1
        expansion.fromValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        expansion.toValue = UIBezierPath(ovalInRect: CGRect(x: -8.0, y: -8.0, width: frame.width + 16, height: frame.height + 16)).CGPath
        expansion.removedOnCompletion = false
        expansion.fillMode = kCAFillModeForwards
        
        
        //Configure beaconRing and record layers' width change
        beaconRingWidth.duration = otherDuration
        beaconRingWidth.fromValue = beaconRing.lineWidth
        beaconRingWidth.toValue = beaconRing.lineWidth + 2
        beaconRingWidth.removedOnCompletion = false
        beaconRingWidth.fillMode = kCAFillModeForwards
        
        
        //Configure border1 change. Difference is in the lineWidth values
        border2Width.duration = otherDuration
        border2Width.fromValue = beaconRing.lineWidth + 1
        border2Width.toValue = beaconRing.lineWidth + 3
        border2Width.beginTime = CACurrentMediaTime() + 0.5
        border2Width.removedOnCompletion = false
        border2Width.fillMode = kCAFillModeForwards
        
        
        //Configure contraction for auxRing
        contraction.duration = otherDuration
        contraction.fromValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        contraction.toValue = UIBezierPath(ovalInRect: CGRect(x: 20.0, y: 20.0, width: frame.width - 40, height: frame.height - 40)).CGPath
        contraction.beginTime = CACurrentMediaTime() + 0.5
        contraction.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        contraction.removedOnCompletion = false
        contraction.fillMode = kCAFillModeForwards
        
        //Add strokeStartExpanson for auxRing
        strokeStartExpansion.duration = otherDuration
        strokeStartExpansion.fromValue = 0.05
        strokeStartExpansion.toValue = 0.0
        strokeStartExpansion.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        strokeStartExpansion.beginTime = CACurrentMediaTime() + 0.5
        strokeStartExpansion.removedOnCompletion = false
        strokeStartExpansion.fillMode = kCAFillModeForwards
        
        
        //Add strokeExpanson for auxRing
        strokeEndExpansion.duration = otherDuration
        strokeEndExpansion.fromValue = 0.35
        strokeEndExpansion.toValue = 1.0
        strokeEndExpansion.beginTime = CACurrentMediaTime() + 0.5
        strokeEndExpansion.removedOnCompletion = false
        strokeEndExpansion.fillMode = kCAFillModeForwards
        
        
        //Add animations to layers
        record.addAnimation(progress, forKey: nil)
        record.addAnimation(expansion, forKey: nil)
        
        beaconRing.addAnimation(expansion, forKey: nil)
        
        border1.addAnimation(expansion, forKey: nil)
        
        auxRing.addAnimation(contraction, forKey: nil)
        auxRing.addAnimation(strokeStartExpansion, forKey: nil)
        auxRing.addAnimation(strokeEndExpansion, forKey: nil)
        //auxRing.addAnimation(border2Width, forKey: nil)
        
        border2.addAnimation(contraction, forKey: nil)
        border2.addAnimation(strokeStartExpansion, forKey: nil)
        border2.addAnimation(strokeEndExpansion, forKey: nil)
        //border2.addAnimation(border2Width, forKey: nil)
        
    }
    
    internal func stopRecording() {
        
        //Remove animations to layers, reset dimensions and remove the recording layer
        beaconRing.removeAllAnimations()
        border1.removeAllAnimations()
        auxRing.removeAllAnimations()
        border2.removeAllAnimations()
        
        record.removeFromSuperlayer()
    }
    
}