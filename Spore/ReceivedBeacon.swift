//
//  ReceivedAnnotation.swift
//  Spore
//
//  Created by Vikram Ramkumar on 4/18/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import MapKit

class ReceivedBeacon: MKAnnotationView {
    
    
    var beaconShape = CAShapeLayer()
    var beaconStroke = CAShapeLayer()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal init(color: UIColor) {
        
        let frameBounds = 20
        super.init(frame: CGRect(x: -frameBounds/2, y: -frameBounds/2, width: frameBounds, height: frameBounds))
        
        drawAnnotation(color)
    }
    
    
    internal func drawAnnotation(color: UIColor) {
        
        beaconShape.path = UIBezierPath(ovalInRect: self.bounds).CGPath
        beaconShape.fillColor = color.CGColor
        beaconShape.strokeStart = 0.0
        beaconShape.strokeEnd = 1.0
        
        let factor = self.bounds.width
        let startPoint  = factor * 0.0
        let size = factor
        beaconStroke.path = UIBezierPath(ovalInRect: CGRect(x: startPoint, y: startPoint, width: size, height: size)).CGPath
        beaconStroke.fillColor = UIColor.clearColor().CGColor
        beaconStroke.strokeColor = UIColor.whiteColor().CGColor
        beaconStroke.lineWidth = 3
        beaconStroke.strokeStart = 0
        beaconStroke.strokeEnd = 1
        beaconStroke.lineCap = kCALineCapRound

        self.layer.addSublayer(beaconShape)
        self.layer.addSublayer(beaconStroke)
        
        self.userInteractionEnabled = false
    }
}