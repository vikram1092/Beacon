//
//  Line.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/29/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class Line: UIView {
    
    
    override func drawRect(rect: CGRect) {
        
        let path = UIBezierPath()
        UIColor.whiteColor().setStroke()
        let ybounds = self.bounds.height
        path.moveToPoint(CGPoint(x: 1, y: ybounds-1))
        
        for i in 0 ..< 50 {
            
            path.addLineToPoint(CGPoint(x: CGFloat(arc4random_uniform(20)) + CGFloat(i*10), y: ybounds-1-CGFloat(i*18)))
        }
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 2
        
        
        UIView.animateWithDuration(2) { () -> Void in
            
            path.stroke()
        }
    }
}
