//
//  DotView.swift
//  Spore
//
//  Created by Vikram Ramkumar on 6/12/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


let horizontalBounds = CGFloat(15)
let verticalBounds = CGFloat(15)

class DotView: UIView {

    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }
    

    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
    }
    
    
    internal func initializeViews() {
        
        //Set view
        for y in 0...Int(self.bounds.height/verticalBounds) {
            
            //Set offset
            var horizontalOffset = CGFloat(0.0)
            if y % 2 == 0 {
                
                horizontalOffset = CGFloat(-10.0)
            }
            
            //Set dots
            for x in 0...Int(self.bounds.width/horizontalBounds) {
                
                let horizontalPosition = (CGFloat(x) * horizontalBounds) + horizontalOffset
                let verticalPosition = CGFloat(y) * verticalBounds
            
                let dot = Dot()
                dot.center = CGPoint(x: horizontalPosition, y: verticalPosition)
                self.addSubview(dot)
            }
        }
    }
}