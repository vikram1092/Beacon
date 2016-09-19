//
//  DotView.swift
//  Spore
//
//  Created by Vikram Ramkumar on 6/12/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit



class DotView: UIView {
    
    
    let horizontalBounds = CGFloat(15)
    let verticalBounds = CGFloat(30)
    var isAnimating = false
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }
    

    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
    }
    
    
    internal func initializeViews() {
        
        //Set view
        for y in 0...Int(self.bounds.height/verticalBounds) {
            
            
            //Set dots
            for x in -2...Int(self.bounds.width/horizontalBounds) + 1 {
                
                let horizontalPosition = (CGFloat(x) * horizontalBounds)
                let verticalPosition = CGFloat(y) * verticalBounds
            
                let dot = Dot()
                dot.center = CGPoint(x: horizontalPosition, y: verticalPosition)
                self.addSubview(dot)
            }
        }
    }
    
    
    internal func startAnimating(_ intensity: CGFloat) {
        
        if !isAnimating {
            
            isAnimating = true
        }
        
        UIView.animate(withDuration: 5, animations: { 
            
            self.center = CGPoint(x: self.center.x + intensity, y: self.center.y)
            }, completion: { (Bool) in
                
                self.startAnimating(-intensity)
        }) 
    }
    
    
    internal func stopAnimating() {
        
        self.layer.removeAllAnimations()
    }
}
