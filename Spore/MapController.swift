//
//  MapController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 1/11/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
// 4 & 39

import Foundation
import UIKit
import GoogleMaps

class MapController: UIViewController {
    
    var userName = ""
    var userEmail = ""
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        
        //Run view load as normal
        super.viewDidLoad()
        
        //Retreive user details
        userName = userDefaults.objectForKey("userName") as! String
        userEmail = userDefaults.objectForKey("userEmail") as! String
        
        let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 0)
        
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        self.view = mapView
        
        //mapView.animateToLocation(mapView.myLocation.coordinate)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}