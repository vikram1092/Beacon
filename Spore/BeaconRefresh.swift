//
//  BeaconRefresh2.swift
//  Spore
//
//  Created by Vikram Ramkumar on 5/10/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class BeaconRefresh: UIView {
    
    
    let initialDepth = CGFloat(5.0)
    let finalDepth = CGFloat(120.0)
    var number = 13
    var isAnimating = false
    var beaconIndicator = BeaconingIndicator()
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        initializeViews()
    }
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        initializeViews()
    }
    
    
    internal func initializeViews() {
        
        let size = CGFloat(25.0)
        let originX = self.center.x - size/2.0
        
        beaconIndicator = BeaconingIndicator(frame: CGRect(x: originX, y: initialDepth, width: size, height: size))
        beaconIndicator.changeColor(UIColor.whiteColor().CGColor)
        
        self.addSubview(beaconIndicator)
    }
    
    
    internal func updateViews(ratio: CGFloat) {
        
        //Update view to rotate as per scroll ratio given
        if !beaconIndicator.isAnimating {
            
            let depth = min(max(50,initialDepth + ratio * 2), finalDepth)
            let rotation = (depth - initialDepth) * CGFloat(M_PI)/(finalDepth - initialDepth)
            let offset = (-3 * CGFloat(M_PI)/2)
            beaconIndicator.transform = CGAffineTransformMakeRotation(rotation + offset)
        }
    }
    
    
    internal func startAnimating() {
        
        isAnimating = true
        beaconIndicator.startAnimating()
    }
    
    
    internal func stopAnimating() {
        
        beaconIndicator.stopAnimatingWithoutHiding()
        isAnimating = false
    }
}