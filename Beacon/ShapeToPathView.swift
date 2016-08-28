//
//  ShapeToCGPath.swift
//  Beacon
//
//  Created by Vikram Ramkumar on 8/16/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class ShapeToPathView: UIView {
    
    
    // Define CGPaths from SVG files
    let mapPath = PocketSVG.pathFromSVGFileNamed("globe").takeUnretainedValue()
    let replyPath = PocketSVG.pathFromSVGFileNamed("reply").takeUnretainedValue()
    let shapeLayer = CAShapeLayer()
    
    
    convenience init() {
        
        self.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        //Initialize Views
        initializeViews()
        
        //4: Display it!
        self.layer.addSublayer(shapeLayer)
    }
    
    
    internal func initializeViews() {
        
        
        //Set initial shape
        shapeLayer.path = replyPath
        shapeLayer.strokeColor = UIColor.whiteColor().CGColor
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 1.0
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.lineCap = kCALineCapRound
        
        self.layer.addSublayer(shapeLayer)
        
    }
    
    
    internal func changeToMapMode() {
        
        
        print("changeToMapMode")
        //Transition shape to reply state
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = shapeLayer.path
        pathAnimation.toValue = mapPath
        pathAnimation.duration = 0.4
        pathAnimation.fillMode = kCAFillModeForwards
        pathAnimation.removedOnCompletion = false
        
        shapeLayer.addAnimation(pathAnimation, forKey: nil)
    
    }
    
    
    internal func changeToReplyMode(animated: Bool) {
        
        
        print("changeToReplyMode")
        //Change to reply mode with animation or no animation
        if animated {
            
            
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.fromValue = shapeLayer.path
            pathAnimation.toValue = replyPath
            pathAnimation.duration = 0.4
            pathAnimation.fillMode = kCAFillModeForwards
            pathAnimation.removedOnCompletion = false
            
            shapeLayer.addAnimation(pathAnimation, forKey: nil)
        }
        else {
            
            shapeLayer.path = replyPath
        }
    }
}