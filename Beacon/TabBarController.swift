//
//  TabBarController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/20/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(true)
    }
    
    override var childViewControllerForStatusBarStyle : UIViewController? {
        
        print("Status bar style method - Tab Bar Controller")
        if self.selectedViewController == nil {
            
            return CameraController()
        }
        return self.selectedViewController
    }
    
    override var childViewControllerForStatusBarHidden : UIViewController? {
        
        print("Status bar hiding method - Tab Bar Controller")
        if self.selectedViewController == nil {
            
            return CameraController()
        }
        return self.selectedViewController
    }
}
