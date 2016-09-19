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
    var trianglePath = CGMutablePath()
    let backgroundTriangle = CAShapeLayer()
    
    let triangleSideLength = CGFloat(30)
    let offset = CGFloat(6)
    let rectColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
    let headingColor = BeaconColors().blueColor
    let textColor = UIColor.darkGray
    let userDefaults = UserDefaults.standard
    
    
    override init(frame: CGRect) {
        
        
        super.init(frame: frame)
        
        self.alpha = 0
        
        //Initialize background
        backgroundRect.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: 15).cgPath
        backgroundRect.fillColor = rectColor
        backgroundRect.shadowColor = UIColor.black.cgColor
        backgroundRect.shadowOpacity = 0.4
        backgroundRect.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        
        //Initialize path
        trianglePath.move(to: CGPoint(x: frame.width/2 - triangleSideLength/2, y: frame.height + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 + triangleSideLength/2, y: frame.height + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2, y: frame.height + triangleSideLength/2 + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 - triangleSideLength/2 - 1, y: frame.height + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 - triangleSideLength/2, y: frame.height + offset))
        
        //Initialize triangle layer
        backgroundTriangle.path = trianglePath
        backgroundTriangle.fillColor = rectColor
        backgroundTriangle.shadowColor = UIColor.black.cgColor
        backgroundTriangle.shadowOpacity = 0.4
        backgroundTriangle.shadowOffset = CGSize(width: 0.0, height: 0.0)
        
        //Add all layers
        self.layer.addSublayer(backgroundTriangle)
        self.layer.addSublayer(backgroundRect)
    }
    
    
    internal func showText(_ heading: String, text: String) {
        
        
        //Set heading label
        headingLabel.frame = CGRect(x: 10, y: 10, width: self.bounds.width - 20, height: 30)
        headingLabel.text = heading
        headingLabel.font = UIFont.boldSystemFont(ofSize: 17)
        headingLabel.numberOfLines = 1
        headingLabel.textColor = headingColor
        headingLabel.textAlignment = NSTextAlignment.center
        
        
        
        //Set border line
        let path = UIBezierPath()
        let height = CGFloat(43)
        path.move(to: CGPoint(x: 50, y: height))
        path.addLine(to: CGPoint(x: self.bounds.width - 50, y: height))
        borderLine.path = path.cgPath
        borderLine.fillColor = UIColor.clear.cgColor
        borderLine.strokeColor = UIColor.darkGray.cgColor
        
        
        
        //Set text label
        textLabel.frame = CGRect(x: 10, y: 50, width: self.bounds.width - 20, height: 40)
        textLabel.text = text
        textLabel.font = UIFont.boldSystemFont(ofSize: 12)
        textLabel.numberOfLines = 0
        textLabel.textColor = textColor
        textLabel.textAlignment = NSTextAlignment.center
        
        
        //Add views
        self.addSubview(headingLabel)
        self.addSubview(textLabel)
        self.layer.addSublayer(borderLine)
        
        //Show view
        UIView.animate(withDuration: 0.3, animations: { 
            
            self.alpha = 1
        }) 
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    internal func pointTriangleUp() {
        
        
        //Configure the triangle to be on top
        let frame = self.frame
        trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: frame.width/2 - triangleSideLength/2, y: -offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 + triangleSideLength/2, y: -offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2, y: -triangleSideLength/2 - offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 - triangleSideLength/2 - 1, y: -offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 - triangleSideLength/2, y: -offset))
        
        backgroundTriangle.path = trianglePath
        self.layer.addSublayer(backgroundTriangle)
    }
    
    
    internal func pointTriangleDown() {
        
        
        //Configure the triangle to be at the bottom
        let frame = self.frame
        trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: frame.width/2 - triangleSideLength/2, y: frame.height + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 + triangleSideLength/2, y: frame.height + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2, y: frame.height + triangleSideLength/2 + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 - triangleSideLength/2 - 1, y: frame.height + offset))
        trianglePath.addLine(to: CGPoint(x: frame.width/2 - triangleSideLength/2, y: frame.height + offset))
        
        backgroundTriangle.path = trianglePath
        self.layer.addSublayer(backgroundTriangle)
    }
    
    
    internal func moveTriangle(_ place: CGPoint) {
        
        //Move trianlge to given point
        backgroundTriangle.position = place
    }
    
    
    internal func removeView(_ key: String?) {
        
        
        //Disappear view upon touch
        UIView.animate(withDuration: 0.3, animations: {
            
            self.alpha = 0
            
        }, completion: { (Bool) in
            
            //Set key if not nil and remove view
            if key != nil {
                
                self.userDefaults.set(true, forKey: key!)
            }
            
            self.removeFromSuperview()
        }) 
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        //Remove view upon touch
        removeView(nil)
        
    }
}
