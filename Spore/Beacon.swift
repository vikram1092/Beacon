//
//  ReceivedAnnotation.swift
//  Spore
//
//  Created by Vikram Ramkumar on 4/18/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Beacon: MKAnnotationView {
    
    
    var beaconShape = CAShapeLayer()
    var color = UIColor()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal init(color: UIColor) {
        
        let frameBounds = 10
        super.init(frame: CGRect(x: -frameBounds/2, y: -frameBounds/2, width: frameBounds, height: frameBounds))
        
        drawAnnotation(color)
    }
    
    
    internal func drawAnnotation(color: UIColor) {
        
        beaconShape.path = UIBezierPath(ovalInRect: self.frame).CGPath
        beaconShape.fillColor = UIColor.clearColor().CGColor
        beaconShape.strokeColor = color.CGColor
        beaconShape.lineWidth = 3
        beaconShape.strokeStart = 0.0
        beaconShape.strokeEnd = 1.0

        self.layer.addSublayer(beaconShape)
    }
    
}