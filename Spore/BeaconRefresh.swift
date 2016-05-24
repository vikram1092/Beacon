//
//  BeaconRefresh.swift
//  Spore
//
//  Created by Vikram Ramkumar on 5/10/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class BeaconRefresh: UIView {
    
    
    let color = UIColor(red: 189.0/255.0, green: 27.0/255.0, blue: 83.0/255.0, alpha: 1).CGColor
    let initialDepth = CGFloat(5.0)
    let number = 13
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let width = self.bounds.width - initialDepth
        let ratio = width/CGFloat(number + 1)
        
        for i in 1...number {
            
            let beacon = BeaconRefreshView()
            self.addSubview(beacon)
            beacon.center = CGPoint(x: -beacon.bounds.width/2 + (ratio * CGFloat(i)), y: initialDepth)
        }
    }
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        let width = self.bounds.width - initialDepth
        let ratio = width/CGFloat(number + 1)
        
        for i in 1...number {
            
            let beacon = BeaconRefreshView()
            self.addSubview(beacon)
            beacon.center = CGPoint(x: ratio * CGFloat(i), y: initialDepth)
        }
    }
    
    
    internal func updateViews(evenRatio: CGFloat, oddRatio: CGFloat) {
        
        //Move views according to ratio
        for i in 0..<self.subviews.count {
            
            let subview = self.subviews[i]
            let subviewCenterX = subview.center.x
            let centerX = self.bounds.width/2
            let distanceRatio = CGFloat(1.0) //max(log10(1 - abs(subviewCenterX - centerX)/centerX) * 10, 0.0)
            
            print(distanceRatio)
            
            //Evens are odds and odds are even in this array
            if i % 2 == 0 {
                
                subview.center = CGPoint(x: subview.center.x, y:  initialDepth + oddRatio + distanceRatio)
            }/*
            else if i % 3 == 2 {
                
                subview.center = CGPoint(x: subview.center.x, y:  initialDepth + evenRatio + distanceRatio)
            }*/
            else {
                
                subview.center = CGPoint(x: subview.center.x, y:  initialDepth + evenRatio + distanceRatio)
            }
        }
        
    }
}