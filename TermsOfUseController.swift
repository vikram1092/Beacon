//
//  Terms of Use Controller.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/11/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import UIKit


class TermsOfUseController: UIViewController {
    
    
    @IBOutlet var termsOfUse: UILabel!
    
    let termsText = "TERMS OF USE \n \n Don't be lewdicrous. "
    
    
    
    override func viewDidLoad() {
        
        //Load view as normal
        super.viewDidLoad()
        
        termsOfUse.text = termsText
    }
    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
}