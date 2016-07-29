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
    
    
    @IBOutlet var textView: UITextView!
    
    
    override func viewDidLoad() {
        
        //Load view as normal
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        textView.scrollEnabled = true
    }
    
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
}