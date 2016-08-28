//
//  TableMessageView.swift
//  Beacon
//
//  Created by Vikram Ramkumar on 8/26/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class TableMessageView: UILabel {
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
    }
    
    
    override func drawTextInRect(rect: CGRect) {
        
        
        let width = CGFloat(180)
        let height = rect.height
        let rect = CGRect(x: self.center.x - width/2, y: 0, width: width, height: height)
        
        super.drawTextInRect(rect)
    }
}