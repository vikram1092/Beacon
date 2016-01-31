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
import Mapbox

class MapController: UIViewController, MGLMapViewDelegate {
    
    var userName = ""
    var userEmail = ""
    var userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var mapView: MGLMapView!
    
    override func viewDidLoad() {
        
        //Run view load as normal
        super.viewDidLoad()
        
        //Retreive user details
        userName = userDefaults.objectForKey("userName") as! String
        userEmail = userDefaults.objectForKey("userEmail") as! String
        
        /*let camera = GMSCameraPosition.cameraWithLatitude(-33.86,
            longitude: 151.20, zoom: 0)
        
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        self.view = mapView
        
        mapView.animateToLocation(mapView.myLocation.coordinate)*/
        
        delay(1) { () -> () in
            
            let classes = self.mapView.annotations!
            
            print("classes length: " + String(classes.count))
            for x in classes {
                
                print("Class: " + x.description)
            }
        }

        
    }
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}