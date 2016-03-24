//
//  CountryBackground.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/23/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class CountryBackground: UIView {
    
    
    let background = CAShapeLayer()
    let progressView = CAShapeLayer()

    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let frame = super.frame
        
        background.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        background.fillColor = UIColor(red: 255.0/255.0, green: 103.0/255.0, blue: 102.0/255.0, alpha: 1).CGColor
        
        self.layer.addSublayer(background)
    }
    
    
    internal func setProgress(progress: Float) {
        
        
        progressView.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        progressView.fillColor = UIColor.clearColor().CGColor
        progressView.strokeColor = UIColor(red: 254.0/255.0, green: 202.0/255.0, blue: 22.0/255.0, alpha: 1).CGColor
        progressView.lineWidth = 4
        progressView.strokeStart = 0.0
        progressView.strokeEnd = CGFloat(progress)
        
        self.layer.addSublayer(progressView)
    }
    
    internal func noProgress() {
        
        progressView.removeFromSuperlayer()
    }
}
