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
    
    
    override func viewDidAppear(animated: Bool) {
        
        self.setNeedsStatusBarAppearanceUpdate()
        super.viewDidAppear(true)
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        
        return self.selectedViewController
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        
        return self.selectedViewController
    }
}