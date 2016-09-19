//
//  CountryBackground.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/23/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit
import ParseUI

class CountryBackground: UIView {
    
    
    let background = CAShapeLayer()
    let progressLayer = CAShapeLayer()
    var progressView = UIView()
    let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
    var isAnimating = false
    var country = UIImageView()
    var shapeView = ShapeToPathView()
    var mapMode = false
    var replyMode = false
    var countryMode = true
    let transitionTime = 0.3
    var initialized = false
    
    var color = BeaconColors().redColor
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        super.init(coder: aDecoder)
        
        initializeViews()
        
        //Register for interruption notifications
        NotificationCenter.default.addObserver(self, selector: #selector(CountryBackground.resumeAnimating), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        
    }
    
    
    internal func initializeViews() {
        
        //Initialize if not initialized already
        if !initialized {
            
            initialized = true
            let useFrame = CGRect(x: 0, y: 0, width: 75, height: 75)
            
            //Create view
            progressView.frame = useFrame
            progressView.backgroundColor = UIColor.clear
            progressView.transform = CGAffineTransform(rotationAngle: -CGFloat(M_PI)/2)
            self.addSubview(progressView)
            
            //Create background layer
            background.path = UIBezierPath(ovalIn: CGRect(x: 4.0, y: 4.0, width: useFrame.width - 8, height: useFrame.height - 8)).cgPath
            background.fillColor = self.color.cgColor
            self.layer.addSublayer(background)
            
            //Rotate view for progress bar, and rotate country image back
            country = self.viewWithTag(5) as! UIImageView
            shapeView = self.viewWithTag(7) as! ShapeToPathView
            self.bringSubview(toFront: shapeView)
            self.bringSubview(toFront: country)
        }
    }
    
    
    internal func setProgress(_ progress: Float) {
        
        
        //Set progress layer
        let useFrame = CGRect(x: 0, y: 0, width: 75, height: 75)
        progressLayer.path = UIBezierPath(ovalIn: useFrame).cgPath
        
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = background.fillColor
        progressLayer.lineWidth = 2.5
        progressLayer.strokeStart = 1.0 - CGFloat(progress)
        progressLayer.strokeEnd = 1.0
        progressLayer.lineCap = kCALineCapRound
        
        progressView.layer.addSublayer(progressLayer)
    }
    
    
    internal func changeBackgroundColor(_ newColor: UIColor) {
        
        
        //Change all color variables to new color
        color = newColor
        background.fillColor = newColor.cgColor
        progressLayer.fillColor = newColor.cgColor
    }
    
    
    internal func noProgress() {
        
        //Remove progress layer
        progressLayer.removeFromSuperlayer()
    }
    
    
    internal func startAnimating() {
    
        
        //Animate progress layer
        isAnimating = true
        progressView.layer.removeAllAnimations()
        
        rotateAnimation.fromValue = CGFloat(-M_PI/2)
        rotateAnimation.toValue = CGFloat(3 * M_PI/2)
        rotateAnimation.duration = 1
        rotateAnimation.repeatCount = HUGE
        
        
        progressView.layer.add(rotateAnimation, forKey: "rotate")
    
    }
    
    
    internal func resumeAnimating() {
        
        //Resume animating if view was animating
        if isAnimating {
            
            progressView.layer.add(rotateAnimation, forKey: "rotate")
        }
    }
    
    
    internal func stopAnimating() {
        
        
        //Remove animations and hide
        isAnimating = false
        progressView.layer.removeAllAnimations()
    }
    
    
    internal func changeToReplyMode(_ animated: Bool) {
        
        
        //Change view to show reply
        print("changeToReplyMode")
        if !replyMode {
            
            //Trigger map mode on
            mapMode = false
            replyMode = true
            countryMode = false
            
            //Change shape view to reply mode
            shapeView = self.viewWithTag(7) as! ShapeToPathView
            shapeView.changeToReplyMode(animated)
            
            if animated {
                
                UIView.animate(withDuration: transitionTime, animations: {
                    
                    //Hide country view
                    self.country.alpha = 0
                    
                    //Show shape view
                    self.shapeView.alpha = 1
                    
                })
            }
            else {
                
                //Hide country view
                self.country.alpha = 0
                
                //Show shape view
                self.shapeView.alpha = 1
            }
            
        }
        else if country.alpha != 0 {
            
            UIView.animate(withDuration: self.transitionTime, animations: {
                
                //Hide the country view because it glitches with animations
                self.country.alpha = 0
            })
        }
    }
    
    
    internal func changeToMapMode() {
        
        
        //Change view to show map
        print("changeToMapMode")
        if !mapMode {
            
            //Trigger map mode on
            mapMode = true
            replyMode = false
            countryMode = false
            
            //Change shape view to reply mode
            shapeView = self.viewWithTag(7) as! ShapeToPathView
            shapeView.changeToMapMode()
            
            
            UIView.animate(withDuration: transitionTime, animations: {
                
                //Hide country view
                self.country.alpha = 0
                
                //Show shape view
                self.shapeView.alpha = 1
                
            })
        }
        else if country.alpha != 0 {
            
            UIView.animate(withDuration: self.transitionTime, animations: {
                
                //Hide the country view because it glitches with animations
                self.country.alpha = 0
            })
        }
    }
    
    
    internal func changeToCountryMode(_ animated: Bool) {
        
        
        //Change view to show country
        print("changeToCountryMode")
        if !countryMode {
            
            mapMode = false
            replyMode = false
            countryMode = true
            
            
            //Hide shape view, animate or depending on variable
            if animated {
                
                UIView.animate(withDuration: transitionTime, animations: {
                    
                    //Show country view
                    self.country.alpha = 1
                    
                    //Hide shape view
                    self.shapeView.alpha = 0
                    
                })
            }
            else {
                
                //Show country view
                self.country.alpha = 1
                
                //Hide shape view
                self.shapeView.alpha = 0
            }
            
        }
        else {
            
            //Hide the shape view because it glitches with animations
            shapeView.alpha = 0
            country.alpha = 1
        }
    }
    
    
    internal func getImage() -> UIImage {
        
        //Get country image
        return country.image!
    }
    
    
    internal func getColor() -> UIColor {
        
        //Get current color
        return color
    }
    
}
