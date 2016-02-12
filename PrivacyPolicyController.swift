//
//  Privacy Policy Controller.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/11/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class PrivacyPolicyController: UIViewController {
    
    
    @IBOutlet var privacyPolicy: UILabel!
    
    let privacyText = "PRIVACY POLICY \n \n Your pictures will not be shared with random people. "
    
    override func viewDidLoad() {
        
        //Load view as normal
        super.viewDidLoad()
        
        //
        privacyPolicy.text = privacyText
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
}