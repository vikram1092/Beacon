//
//  ShapeToCGPath.swift
//  Beacon
//
//  Created by Vikram Ramkumar on 8/16/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class ShapeToGlobe: UIView {
    
    
    //1: Turn your SVG into a CGPath:
    let globePath = PocketSVG.pathFromSVGFileNamed("globeMiniature").takeUnretainedValue()
    var mapPath = UIBezierPath().CGPath
    let shapeLayer = CAShapeLayer()
    var mapMode = false
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        //Initialize Views
        initializeViews()
        
        //4: Display it!
        self.layer.addSublayer(shapeLayer)
    }
    
    
    internal func initializeViews() {
        
        
        //2: To display it on screen, you can create a CAShapeLayer
        //and set myPath as its path property:
        shapeLayer.path = globePath
        
        //3: Fiddle with it using CAShapeLayer's properties:
        shapeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = 1.0
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.lineCap = kCALineCapRound
        
    }
    
    
    internal func changeToMapMode(increaseFactor: CGFloat, strokeStart: CGFloat) {
        
        
        print("changeToMapMode")
        if !mapMode {
            
            //Trigger map mode on
            mapMode = true
            
            
            //Set CA Transaction to handle animations
            CATransaction.begin()
            CATransaction.setCompletionBlock( {
                
                
                //Change path
                self.mapPath = UIBezierPath(ovalInRect: CGRect(x: -increaseFactor/2, y: -increaseFactor/2, width: self.bounds.width + increaseFactor, height: self.bounds.height + increaseFactor)).CGPath
                
                //Change path
                let pathAnimation = CABasicAnimation(keyPath: "path")
                pathAnimation.fromValue = self.globePath
                pathAnimation.toValue = self.mapPath
                pathAnimation.duration = 0.2
                pathAnimation.fillMode = kCAFillModeForwards
                pathAnimation.removedOnCompletion = false
                
                //Change line width
                let strokeAnimation = CABasicAnimation(keyPath: "lineWidth")
                strokeAnimation.fromValue = 2
                strokeAnimation.toValue = 2.5
                strokeAnimation.duration = 0.2
                strokeAnimation.fillMode = kCAFillModeForwards
                strokeAnimation.removedOnCompletion = false
                
                //Change stroke start
                let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
                strokeStartAnimation.fromValue = 0.0
                if strokeStart == 0.0 {
                    
                    strokeStartAnimation.toValue = 0.0
                }
                else {
                    
                    strokeStartAnimation.toValue = 0.03
                }
                strokeStartAnimation.duration = 0.2
                strokeStartAnimation.fillMode = kCAFillModeForwards
                strokeStartAnimation.removedOnCompletion = false
                
                
                //Change stroke end
                let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
                strokeEndAnimation.fromValue = 1.0
                if strokeStart == 0.0 {
                    
                    strokeEndAnimation.toValue = 1.0
                }
                else {
                    
                    strokeEndAnimation.toValue = strokeStart - 0.03
                }
                strokeEndAnimation.duration = 0.2
                strokeEndAnimation.fillMode = kCAFillModeForwards
                strokeEndAnimation.removedOnCompletion = false
                
                //Rotate like country view
                let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
                rotateAnimation.fromValue = 0.0
                rotateAnimation.toValue = -CGFloat(M_PI)/2
                rotateAnimation.duration = 0.2
                rotateAnimation.fillMode = kCAFillModeForwards
                rotateAnimation.removedOnCompletion = false
                
                //Add animations to layer
                self.shapeLayer.addAnimation(pathAnimation, forKey: nil)
                self.shapeLayer.addAnimation(strokeAnimation, forKey: nil)
                self.shapeLayer.addAnimation(strokeStartAnimation, forKey: nil)
                self.shapeLayer.addAnimation(strokeEndAnimation, forKey: nil)
                self.layer.addAnimation(rotateAnimation, forKey: nil)
                

            })
            
            
            //Go to initial state
            let initialAnimation = CABasicAnimation(keyPath: "path")
            initialAnimation.fromValue = globePath
            initialAnimation.toValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: self.bounds.height)).CGPath
            initialAnimation.duration = 0.1
            initialAnimation.fillMode = kCAFillModeForwards
            initialAnimation.removedOnCompletion = false
            
            shapeLayer.addAnimation(initialAnimation, forKey: nil)
            CATransaction.commit()
        }
    }
    
    
    internal func changeToTableMode() {
        
        
        print("changeToTableMode")
        if mapMode {
            
            //Trigger map mode off
            mapMode = false
            
            
            //Set CA Transaction to handle animations
            CATransaction.begin()
            CATransaction.setCompletionBlock( {
                
            //Change path
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.fromValue = self.shapeLayer.path
            pathAnimation.toValue = self.globePath
            pathAnimation.duration = 0.1
            pathAnimation.fillMode = kCAFillModeForwards
            pathAnimation.removedOnCompletion = false
            
            //Change line width
            let strokeAnimation = CABasicAnimation(keyPath: "lineWidth")
            strokeAnimation.fromValue = self.shapeLayer.lineWidth
            strokeAnimation.toValue = 2
            strokeAnimation.duration = 0.1
            strokeAnimation.fillMode = kCAFillModeForwards
            strokeAnimation.removedOnCompletion = false
            
            //Change stroke start
            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.fromValue = self.shapeLayer.strokeStart
            strokeStartAnimation.toValue = 0.0
            strokeStartAnimation.duration = 0.1
            strokeStartAnimation.fillMode = kCAFillModeForwards
            strokeStartAnimation.removedOnCompletion = false
            
            
            //Change stroke end
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.fromValue = self.shapeLayer.strokeEnd
            strokeEndAnimation.toValue = 1.0
            strokeEndAnimation.duration = 0.1
            strokeEndAnimation.fillMode = kCAFillModeForwards
            strokeEndAnimation.removedOnCompletion = false
            
            //Rotate like country view
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotateAnimation.fromValue = -CGFloat(M_PI)/2
            rotateAnimation.toValue = 0.0
            rotateAnimation.duration = 0.1
            rotateAnimation.fillMode = kCAFillModeForwards
            rotateAnimation.removedOnCompletion = false
            
            //Add animations to layer
            self.shapeLayer.addAnimation(pathAnimation, forKey: nil)
            self.shapeLayer.addAnimation(strokeAnimation, forKey: nil)
            self.shapeLayer.addAnimation(strokeStartAnimation, forKey: nil)
            self.shapeLayer.addAnimation(strokeEndAnimation, forKey: nil)
            self.layer.addAnimation(rotateAnimation, forKey: nil)
            })
            
            
            //Go to initial state
            let initialAnimation = CABasicAnimation(keyPath: "path")
            initialAnimation.fromValue = mapPath
            initialAnimation.toValue = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: self.bounds.width, height: self.bounds.height)).CGPath
            initialAnimation.duration = 0.2
            initialAnimation.fillMode = kCAFillModeForwards
            initialAnimation.removedOnCompletion = false
            
            shapeLayer.addAnimation(initialAnimation, forKey: nil)
            CATransaction.commit()
            
        }
    }
    

    internal func resetStroke() {
        
        initializeViews()
    }
}