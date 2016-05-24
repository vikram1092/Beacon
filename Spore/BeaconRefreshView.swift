//
//  BeaconRefreshView.swift
//  Spore
//
//  Created by Vikram Ramkumar on 5/17/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class BeaconRefreshView: UIView {
    
    
    let dot = CAShapeLayer()
    let color = UIColor.whiteColor().CGColor
    let bound = 10
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        //Set beacon dot
        let dotBounds = self.bounds.height
        dot.path = UIBezierPath(ovalInRect: CGRect(x: self.bounds.width, y: self.bounds.height, width: dotBounds, height: dotBounds)).CGPath
        dot.fillColor = color
        
        self.layer.addSublayer(dot)
    }
    
    init() {
        
        super.init(frame: CGRect(x: 0, y: 0, width: bound, height: bound))
        
        //Set beacon dot
        dot.path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: bound, height: bound)).CGPath
        dot.fillColor = color
        
        self.layer.addSublayer(dot)
    }
}