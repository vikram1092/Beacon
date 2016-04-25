//
//  MapController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 1/11/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
// 4 & 39

import Foundation
import UIKit
import Parse
import MapKit

class MapController: UIViewController, MKMapViewDelegate {
    
    var countries = NSArray()
    var userName = ""
    var userEmail = ""
    var userDefaults = NSUserDefaults.standardUserDefaults()
    var userList = Array<PFObject>()
    var loadedCountries = Array<String>()
    var loadedMarkers = Array<CLLocation>()
    var countryColor = UIColor()
    var countriesAreLoaded = false
    var markersAreLoaded = false
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        
        //Run view load as normal
        super.viewDidLoad()
        
        getUserDefaults()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(true)
        
        //Load the user list and annotations onto the map
        if !activityIndicator.isAnimating() {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                
                self.loadUserList()
            }
        }
    }
    
    
    internal func getUserDefaults() {
        
        //Get user details
        if userDefaults.objectForKey("userName") != nil {
            
            userName = userDefaults.objectForKey("userName") as! String
            print(userName)
        }
        
        if userDefaults.objectForKey("userEmail") != nil {
            
            userEmail = userDefaults.objectForKey("userEmail") as! String
            print(userEmail)
        }
    }
    
    
    internal func loadUserList() {
    
        //Retreive local user photo list
        //self.countriesAreLoaded = false
        let query = PFQuery(className: "photo")
        query.fromLocalDatastore()
        
        print("Querying local userList")
        query.addAscendingOrder("updatedAt")
        query.findObjectsInBackgroundWithBlock { (objects, retreivalError) -> Void in
            
            if retreivalError != nil {
                
                print("Problem retreiving list: " + retreivalError!.description)
            }
            else if objects!.count > 0 {
                
                //Save list of objects & reload table
                self.userList = objects!
                
                //Update user list with new photos
                print("Running country annotations")
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                    
                    self.processUserList()
                }
            }
        }
    }
    
    
    internal func processUserList() {
        
        
        //Start activity indicator
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.activityIndicator.startAnimating()
        }
        
        //Get JSON data
        print("Starting to display userList")
        let filePath = NSBundle.mainBundle().pathForResource("Countries", ofType: "geojson")
        print(filePath)
        let data = NSData(contentsOfFile: filePath!)!
        
        do {
            //Instantiate country GeoJSON data
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            //Get array of countries from JSON
            countries = json.objectForKey("features") as! NSArray
            
            //Loop through all userlist elements
            for element in userList {
                
                //Check if country already loaded. If not, proceed & add the country to loaded list
                if loadedCountries.indexOf(element.objectForKey("countryCode") as! String) == nil {
                    
                    getDetailsToDrawCountry(element.objectForKey("countryCode") as! String)
                    loadedCountries.append(element.objectForKey("countryCode") as! String)
                }
            }
            
            //Stop activity indicator if the markers are already loaded
            countriesAreLoaded = true
            print("countriesAreLoaded: \(countriesAreLoaded)")
            
            /*if markersAreLoaded {
                
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    
                    self.activityIndicator.stopAnimating()
                }
            }*/
            
            //Load markers after countries are loaded
            loadMarkers()
        }
        catch let error as NSError { print("Error getting GeoJSON data:" + error.description) }
    }
    
    
    internal func goToCountry(location: CLLocationCoordinate2D) {
        
        print("User picture coordinates:" + String(location))
        let span = MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
        mapView.regionThatFits(region)
    }
    
    
    internal func getDetailsToDrawCountry(countryCode: String) {
        
        
        //Initialize dummy index
        var index = -1
        
        //Get index of country
        for countryElement in countries {
            
            let isoCode = countryElement.objectForKey("properties")!.objectForKey("ISO_A2") as! String
            
            //Check if current JSON country iso code matches with desired country
            if isoCode == countryCode.uppercaseString {
                
                print(countryElement.objectForKey("properties")!.objectForKey("ISO_A2") as! String)
                index = countries.indexOfObject(countryElement)
                break
            }
        }
        
        //Draw country on map if index is valid
        if (index != -1) {
            
            //Set color for country
            let color = UIColor(red: CGFloat(arc4random_uniform(255))/255.0, green: CGFloat(arc4random_uniform(255))/255.0, blue: CGFloat(arc4random_uniform(255))/255.0, alpha: 1)

            
            //Check if country is one polygon or multiple.
            //If multiple, handle each one of them
            if countries[index].objectForKey("geometry")!.objectForKey("type") as! String == "Polygon" {
                
                //Get single polygon and draw
                let polygon = countries[index].objectForKey("geometry")!.objectForKey("coordinates") as! NSMutableArray
                drawCountry(polygon, color: color)
            }
            else {
                
                //Get array of polygons and draw all of them
                let polygons = countries[index].objectForKey("geometry")!.objectForKey("coordinates") as! NSMutableArray
                
                for polygon in polygons {
                    
                    drawCountry(polygon as! NSMutableArray, color: color)
                }
            }
        }
    }
    
    
    internal func drawCountry(polygon: NSMutableArray, color: UIColor) {
        
        //Configure path
        var location = CLLocationCoordinate2D()
        var path = Array<CLLocationCoordinate2D>()
        //let path = GMSMutablePath()
        
        //Iterate through all coordinates in polygon & add to path
        for element in polygon {
            for currentCoord in (element as! NSMutableArray) {
                
                let coordinate = currentCoord as! NSMutableArray
                location.longitude = coordinate[0] as! CLLocationDegrees
                location.latitude = coordinate[1] as! CLLocationDegrees
                
                path.append(location)
                //path.addCoordinate(location)
            }
        }
        
        let pointer = UnsafeMutablePointer<CLLocationCoordinate2D>(path)
        let country = CountryPolyline(coordinates: pointer, count: path.count)
        
        //Assign color
        country.color = color
        
        //Add polygon to map in main thread
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            print("Adding polygon!")
            self.mapView.addOverlay(country)
        })
    }
    
    
    internal func loadMarkers() {
        
        
        //Load markers for where user's photos went
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            
            //Mark markers as not loaded and run query
            print(self.userEmail)
            self.markersAreLoaded = false
            let query = PFQuery(className: "photo")
            query.whereKey("sentBy", equalTo: self.userEmail)
            query.whereKeyExists("receivedLatitude")
            query.findObjectsInBackgroundWithBlock { (photoObjects, markerError) -> Void in
                
                if markerError != nil {
                    
                    print("Error finding marker: \(markerError)")
                }
                else if photoObjects!.count > 0 {
                    
                    //For each row received, get location and plot on map
                    print("Query returned \(photoObjects!.count) rows")
                    for photoObject in photoObjects! {
                        
                        let latitude = photoObject.objectForKey("receivedLatitude") as? Double
                        let longitude = photoObject.objectForKey("receivedLongitude") as? Double
                        
                        if latitude != nil {
                            
                            let markerCoord2D = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                            let markerCoord = CLLocation(latitude: latitude!, longitude: longitude!)
                            print(markerCoord2D)
                            
                            if self.loadedMarkers.indexOf(markerCoord) == nil {
                                
                                //Configure annotation
                                print("Loading marker")
                                self.loadedMarkers.append(markerCoord)
                                let marker = MKPointAnnotation()
                                marker.coordinate = markerCoord2D
                                
                                //Add annotation to map
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    
                                    self.mapView.addAnnotation(marker)
                                })
                            }
                            
                        }
                    }
                }
                
                //Stop activity indicator if the countries are already loaded
                self.markersAreLoaded = true
                if self.countriesAreLoaded {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.activityIndicator.stopAnimating()
                    })
               }
            }
        }
    }
    
    
    internal func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = (polylineRenderer.overlay as! CountryPolyline).color
        polylineRenderer.lineWidth = 1
        
        return polylineRenderer
    }
    
    
    internal func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        var view = MKAnnotationView()
        
        if annotation is MKPointAnnotation {
            
            view = Beacon(color: UIColor.redColor())
        }
        else {
            view.annotation = annotation
        }
        
        return view
    }
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        print("Status bar style method - Map Controller")
        return UIStatusBarStyle.Default
    }
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}