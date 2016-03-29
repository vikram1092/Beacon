//
//  Privacy Policy Controller.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/11/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class AboutController: UIViewController {
    
    
    @IBOutlet var about: UILabel!
    
    let aboutText = "About \n \n Planet Earth sends its regards. "
    
    
    
    override func viewDidLoad() {
        
        //Load view as normal
        super.viewDidLoad()
        
        about.text = aboutText
    }
    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
}