//
//  tutorialView.swift
//  Beacon
//
//  Created by Vikram Ramkumar on 7/16/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class TutorialView: UIView {
    
    
    let headingLabel = UILabel()
    let textLabel = UILabel()
    let borderLine = CAShapeLayer()
    let backgroundRect = CAShapeLayer()
    var trianglePath = CGPathCreateMutable()
    let backgroundTriangle = CAShapeLayer()
    
    let triangleSideLength = CGFloat(30)
    let offset = CGFloat(6)
    let rectColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).CGColor
    let headingColor = BeaconColors().blueColor
    let textColor = UIColor.darkGrayColor()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    
    override init(frame: CGRect) {
        
        
        super.init(frame: frame)
        
        self.alpha = 0
        
        //Initialize background
        backgroundRect.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: 15).CGPath
        backgroundRect.fillColor = rectColor
        backgroundRect.shadowColor = UIColor.blackColor().CGColor
        backgroundRect.shadowOpacity = 0.4
        backgroundRect.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        
        //Initialize path
        CGPathMoveToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2, frame.height + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 + triangleSideLength/2, frame.height + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2, frame.height + triangleSideLength/2 + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2 - 1, frame.height + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2, frame.height + offset)
        
        //Initialize triangle layer
        backgroundTriangle.path = trianglePath
        backgroundTriangle.fillColor = rectColor
        backgroundTriangle.shadowColor = UIColor.blackColor().CGColor
        backgroundTriangle.shadowOpacity = 0.4
        backgroundTriangle.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        //Add all layers
        self.layer.addSublayer(backgroundTriangle)
        self.layer.addSublayer(backgroundRect)
    }
    
    
    internal func showText(heading: String, text: String) {
        
        
        //Set heading label
        headingLabel.frame = CGRect(x: 10, y: 10, width: self.bounds.width - 20, height: 30)
        headingLabel.text = heading
        headingLabel.font = UIFont.boldSystemFontOfSize(17)
        headingLabel.numberOfLines = 1
        headingLabel.textColor = headingColor
        headingLabel.textAlignment = NSTextAlignment.Center
        
        
        
        //Set border line
        let path = UIBezierPath()
        let height = CGFloat(43)
        path.moveToPoint(CGPoint(x: 50, y: height))
        path.addLineToPoint(CGPoint(x: self.bounds.width - 50, y: height))
        borderLine.path = path.CGPath
        borderLine.fillColor = UIColor.clearColor().CGColor
        borderLine.strokeColor = UIColor.darkGrayColor().CGColor
        
        
        
        //Set text label
        textLabel.frame = CGRect(x: 10, y: 50, width: self.bounds.width - 20, height: 40)
        textLabel.text = text
        textLabel.font = UIFont.boldSystemFontOfSize(12)
        textLabel.numberOfLines = 0
        textLabel.textColor = textColor
        textLabel.textAlignment = NSTextAlignment.Center
        
        
        //Add views
        self.addSubview(headingLabel)
        self.addSubview(textLabel)
        self.layer.addSublayer(borderLine)
        
        //Show view
        UIView.animateWithDuration(0.3) { 
            
            self.alpha = 1
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal func pointTriangleUp() {
        
        
        //Configure the triangle to be on top
        let frame = self.frame
        trianglePath = CGPathCreateMutable()
        CGPathMoveToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2, -offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 + triangleSideLength/2, -offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2, -triangleSideLength/2 - offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2 - 1, -offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2, -offset)
        
        backgroundTriangle.path = trianglePath
        self.layer.addSublayer(backgroundTriangle)
    }
    
    
    internal func pointTriangleDown() {
        
        
        //Configure the triangle to be at the bottom
        let frame = self.frame
        trianglePath = CGPathCreateMutable()
        CGPathMoveToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2, frame.height + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 + triangleSideLength/2, frame.height + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2, frame.height + triangleSideLength/2 + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2 - 1, frame.height + offset)
        CGPathAddLineToPoint(trianglePath, nil, frame.width/2 - triangleSideLength/2, frame.height + offset)
        
        backgroundTriangle.path = trianglePath
        self.layer.addSublayer(backgroundTriangle)
    }
    
    
    internal func moveTriangle(place: CGPoint) {
        
        //Move trianlge to given point
        backgroundTriangle.position = place
    }
    
    
    internal func removeView(key: String?) {
        
        
        //Disappear view upon touch
        UIView.animateWithDuration(0.3, animations: {
            
            self.alpha = 0
            
        }) { (Bool) in
            
            //Set key if not nil and remove view
            if key != nil {
                
                self.userDefaults.setBool(true, forKey: key!)
            }
            
            self.removeFromSuperview()
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        
        //Remove view upon touch
        removeView(nil)
        
    }
}