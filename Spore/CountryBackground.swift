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
    
    var backgroundLayerColor = UIColor(red: 248.0/255.0, green: 95.0/255.0, blue: 96.0/255.0, alpha: 1).CGColor
    var progressLayerColor = UIColor(red: 254.0/255.0, green: 202.0/255.0, blue: 22.0/255.0, alpha: 1).CGColor

    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        let frame = super.frame
        
        background.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        background.fillColor = backgroundLayerColor
        
        self.layer.addSublayer(background)
    }
    
    
    internal func setProgress(progress: Float) {
        
        
        progressView.path = UIBezierPath(ovalInRect: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height)).CGPath
        progressView.fillColor = UIColor.clearColor().CGColor
        progressView.strokeColor = progressLayerColor
        progressView.lineWidth = 4
        progressView.strokeStart = 1.0 - CGFloat(progress)
        progressView.strokeEnd = 1.0
        
        self.layer.addSublayer(progressView)
    }
    
    
    internal func changeBackgroundColor(color: CGColor) {
        
        background.fillColor = color
    }
    
    internal func noProgress() {
        
        progressView.removeFromSuperlayer()
    }
}
