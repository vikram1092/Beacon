//
//  Orbiter.swift
//  Spore
//
//  Created by Vikram Ramkumar on 3/20/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


internal enum UIActivityIndicatorViewStyle : Int {
    
    case Blue
    case White
    case Yellow
    case Peach
}

class Orbiter: UIActivityIndicatorView {
    
    
    let circle = CAShapeLayer()
    let circleView = UIView()
    
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
    }
    
    
    internal override func startAnimating() {
        
    }
    
    
}