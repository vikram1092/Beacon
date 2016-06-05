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
    
    
    let color = UIColor(red: 189.0/255.0, green: 27.0/255.0, blue: 83.0/255.0, alpha: 1).CGColor
    let initialDepth = CGFloat(10.0)
    var number = 13
    var isAnimating = false
    var readyToUpdateViews = true
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
        
        if !beaconIndicator.isAnimating {
            
            let depth = min(initialDepth + ratio * 2, 35)
            beaconIndicator.center = CGPoint(x: beaconIndicator.center.x, y:  depth)
            beaconIndicator.transform = CGAffineTransformMakeRotation( -90.0 * (depth/2.0) / 180.0)
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