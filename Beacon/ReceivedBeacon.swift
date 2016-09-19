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
    let color = BeaconColors().redColor
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        drawAnnotation(color: color)
        
    }
    
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        drawAnnotation(color: color)
    }
    
    
    internal func drawAnnotation(color: UIColor) {
        
        
        let factor = CGFloat(20)
        
        beaconShape.path = UIBezierPath(ovalIn: CGRect(x: -factor/2, y: -factor/2, width: factor, height: factor)).cgPath
        beaconShape.fillColor = color.cgColor
        beaconShape.strokeStart = 0.0
        beaconShape.strokeEnd = 1.0
        
        
        beaconStroke.path = UIBezierPath(ovalIn: CGRect(x: -factor/2, y: -factor/2, width: factor, height: factor)).cgPath
        beaconStroke.fillColor = UIColor.clear.cgColor
        beaconStroke.strokeColor = UIColor.white.cgColor
        beaconStroke.lineWidth = 2
        beaconStroke.strokeStart = 0
        beaconStroke.strokeEnd = 1
        beaconStroke.lineCap = kCALineCapRound

        self.layer.addSublayer(beaconShape)
        self.layer.addSublayer(beaconStroke)
        
        self.isUserInteractionEnabled = false
    }
}
