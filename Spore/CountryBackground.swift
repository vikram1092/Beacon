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
    let progressView = CAShapeLayer()
    
    
    var backgroundLayerColor = UIColor(red: 164.0/255.0, green: 137.0/255.0, blue: 201.0/255.0, alpha: 1).CGColor
    //var progressLayerColor = UIColor(red: 84.0/255.0, green: 48.0/255.0, blue: 126.0/255.0, alpha: 1).CGColor
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let frame = super.frame
        
        //Rotate view for progress bar, and rotate country image back
        self.transform = CGAffineTransformMakeRotation( -90.0 * CGFloat(M_PI) / 180.0)
        let country = self.viewWithTag(5)
        let photo = self.viewWithTag(7)
        
        background.path = UIBezierPath(ovalInRect: CGRect(x: 4.0, y: 4.0, width: frame.width - 8, height: frame.height - 8)).CGPath
        background.fillColor = self.backgroundColor?.CGColor
        self.layer.addSublayer(background)
        
        country?.transform = CGAffineTransformMakeRotation( 90.0 * CGFloat(M_PI) / 180.0)
        photo?.transform = CGAffineTransformMakeRotation( 90.0 * CGFloat(M_PI) / 180.0)
        self.bringSubviewToFront(country!)
    }
    
    
    internal func setProgress(progress: Float) {
        
        
        progressView.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        
        progressView.fillColor = UIColor.clearColor().CGColor
        progressView.strokeColor = background.fillColor
        progressView.lineWidth = 2.5
        progressView.strokeStart = 1.0 - CGFloat(progress)
        progressView.strokeEnd = 1.0
        progressView.lineCap = kCALineCapRound
        
        
        self.layer.addSublayer(progressView)
    }
    
    
    internal func changeBackgroundColor(color: CGColor) {
        
        background.fillColor = color
        progressView.fillColor = color
    }
    
    
    internal func noProgress() {
        
        progressView.removeFromSuperlayer()
    }
}
