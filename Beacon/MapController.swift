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
    
    
    let MERCATOR_OFFSET = 268435456.0
    let MERCATOR_RADIUS = 85445659.44705395
    
    var countries = NSArray()
    var userID = ""
    var userDefaults = NSUserDefaults.standardUserDefaults()
    var userList = Array<PFObject>()
    var countryColor = UIColor()
    var countriesAreLoaded = true
    
    var loadedSentMarkers = Array<SentAnnotation>()
    var loadedSentCoordinates = Array<CLLocationCoordinate2D>()
    var sentMarkersAreLoaded = false
    let sentClusteringManager = SentClusteringManager()
    
    var loadedReceivedMarkers = Array<ReceivedAnnotation>()
    var loadedReceivedCoordinates = Array<CLLocationCoordinate2D>()
    var receivedMarkersAreLoaded = false
    let receivedClusteringManager = ReceivedClusteringManager()
    
    let receivedColor = BeaconColors().redColor
    let sentColor = BeaconColors().yellowColor
    
    var tutorialBeaconControlReceivedView = TutorialView()
    var tutorialBeaconControlSentView = TutorialView()
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var beaconControl: UISegmentedControl!
    @IBOutlet var activityIndicator: BeaconingIndicator!
    
    
    override func viewDidLoad() {
        
        
        //Run view load as normal
        super.viewDidLoad()
        
        //Get user info
        getUserDefaults()
        
        //Initialize corner radius for beacon control
        beaconControl.layer.cornerRadius = 15.0
        beaconControl.layer.borderColor = UIColor(red: 50.0/255.0, green: 137.0/255.0, blue:203.0/255.0, alpha: 1).CGColor
        beaconControl.layer.borderWidth = 1.5
        beaconControl.layer.masksToBounds = true
        
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        
        //Load view as normal
        super.viewDidAppear(true)
        
        //Load the user list and annotations onto the map if they're not being loaded already
        //Else, resume animation
        if !activityIndicator.isAnimating {
            
            //Start activity indicator
            self.activityIndicator.startAnimating()
            
            //Dispatch processes on another thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                
                self.loadSentMarkers()
                self.loadReceivedMarkers()
            }
        }
        
        //Show beacon control tutorial view
        showTutorialBeaconControlReceivedView()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        
        //Remove all overlays
        mapView.removeOverlays(mapView.overlays)
        
        //Remove beacon control tutorial view
        removeTutorialBeaconControlReceivedView()
    } 
    
    
    internal func getUserDefaults() {
        
        
        //Get user details
        if userDefaults.objectForKey("userID") != nil {
            
            userID = userDefaults.objectForKey("userID") as! String
        }
    }
    
    
    internal func goToCountry(location: CLLocationCoordinate2D) {

        
        let span = MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
        mapView.regionThatFits(region)
    }
    
    
    internal func getDetailsToDrawCountry(countryCode: String) {
        
        
        //Set countries loaded flag
        countriesAreLoaded = false
        
        //Initialize index
        var index = -1
        
        //Initialize country array if not already loaded
        if countries.count == 0 {
            
            loadCountryArray()
        }
        
        //Get index of country
        for countryElement in countries {
            
            let isoCode = countryElement.objectForKey("properties")!.objectForKey("ISO_A2") as! String
            
            //Check if current JSON country iso code matches with desired country
            if isoCode == countryCode.uppercaseString {
                
                index = countries.indexOfObject(countryElement)
                break
            }
        }
        
        //Draw country on map if index is valid
        if (index != -1) {
            
            
            //Set color for country
            let color = receivedColor

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
        
        //Reset countries loaded
        self.countriesAreLoaded = true
        
        //Stop activity indicator if the countries are already loaded
        if self.sentMarkersAreLoaded && self.receivedMarkersAreLoaded {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.activityIndicator.stopAnimating()
            })
        }
    }
    
    
    internal func loadCountryArray() {
        
        
        //Load array of country JSON objects
        let filePath = NSBundle.mainBundle().pathForResource("Countries", ofType: "geojson")
        let data = NSData(contentsOfFile: filePath!)!
        
        do {
            
            //Instantiate country GeoJSON data
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            //Get array of countries from JSON
            countries = json.objectForKey("features") as! NSArray
        }
        catch let error as NSError { print("Error getting GeoJSON data:" + error.description) }
    }

    
    internal func drawCountry(polygon: NSMutableArray, color: UIColor) {
        
        
        //Configure path
        var location = CLLocationCoordinate2D()
        var path = Array<CLLocationCoordinate2D>()
        
        
        //Iterate through all coordinates in polygon & add to path
        for element in polygon {
    
            for currentCoord in (element as! NSMutableArray) {
                
                let coordinate = currentCoord as! NSMutableArray
                location.longitude = coordinate[0] as! CLLocationDegrees
                location.latitude = coordinate[1] as! CLLocationDegrees
        
                if path.count == 0 {
            
                    path.append(location)
                }
                else if path.count > 0 {
                
                    let last = path.last!
                    if !(location.longitude < 180.0 && last.longitude > 180.0) && !(location.longitude > 180.0 && last.longitude < 180.0) {
                        
                        path.append(location)
                    }
                }
            }
        }
        
        
        //Add polygon to map in main thread if map is the selected index
        let pointer = UnsafeMutablePointer<CLLocationCoordinate2D>(path)
        let country = CountryPolyline(coordinates: pointer, count: path.count)
        
        //Assign color
        country.color = color
        
        if self.tabBarController?.selectedIndex == 2 {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                print("Adding polygon!")
                self.mapView.addOverlay(country)
            })
        }
    }
    
    
    internal func loadSentMarkers() {
        
        
        sentMarkersAreLoaded = false
        
        //Load markers for where user's photos went
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            
            //Mark markers as not loaded and run query
            let query = PFQuery(className: "photo")
            query.whereKey("sentBy", equalTo: self.userID)
            query.whereKeyExists("receivedLatitude")
            query.orderByDescending("createdAt")
            query.limit = 1000
            
            query.findObjectsInBackgroundWithBlock { (photoObjects, markerError) -> Void in
                
                if markerError != nil {
                    
                    print("Error finding marker: \(markerError)")
                }
                else if photoObjects!.count > 0 {
                    
                    //For each row received, get location and plot on map
                    for photoObject in photoObjects! {
                        
                        let latitude = photoObject.objectForKey("receivedLatitude") as? Double
                        let longitude = photoObject.objectForKey("receivedLongitude") as? Double
                        
                        if latitude != nil {
                            
                            let markerCoord2D = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)

                            //Add annotation to map
                            if !self.loadedInArray(markerCoord2D, array: self.loadedSentMarkers) && !(latitude == 0.0 && longitude == 0.0) {
                                
                                //Configure annotation
                                print("Loading sent marker")
                                let marker = SentAnnotation()
                                marker.coordinate = markerCoord2D
                                
                                self.loadedSentMarkers.append(marker)
                                self.sentClusteringManager.addAnnotation(marker)
                            }
                        }
                    }
                    
                }
                
                //Perform clustering after load
                if self.beaconControl.selectedSegmentIndex == 1 {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.performClustering()
                    })
                }
                
                //Stop activity indicator if the countries are already loaded
                self.sentMarkersAreLoaded = true
                
                if self.countriesAreLoaded && self.receivedMarkersAreLoaded {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.activityIndicator.stopAnimating()
                    })
                }
            }
        }
    }
    
    
    internal func loadReceivedMarkers() {
        
        
        receivedMarkersAreLoaded = false
        
        //Load markers for where user's photos went
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            
            //Mark markers as not loaded and run query
            let query = PFQuery(className: "photo")
            query.whereKey("receivedBy", equalTo: self.userID)
            query.whereKeyExists("sentFrom")
            query.orderByDescending("receivedAt")
            query.fromLocalDatastore()
            query.limit = 1000
            
            query.findObjectsInBackgroundWithBlock { (photoObjects, markerError) -> Void in
                
                if markerError != nil {
                    
                    print("Error finding marker: \(markerError)")
                }
                else if photoObjects!.count > 0 {
                    
                    //For each row received, get location and plot on map
                    for photoObject in photoObjects! {
                        
                        if photoObject.objectForKey("sentFrom") != nil {
                            
                            let coordinates = photoObject.objectForKey("sentFrom") as! PFGeoPoint
                            let latitude = coordinates.latitude
                            let longitude = coordinates.longitude
                            let markerCoord2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            
                            
                            //Add annotation to map
                            if !self.loadedInArray(markerCoord2D, array: self.loadedReceivedMarkers) && !(latitude == 0.0 && longitude == 0.0){
                                
                                //Configure annotation
                                print("Loading received marker")
                                let marker = ReceivedAnnotation()
                                marker.coordinate = markerCoord2D
                                
                                self.loadedReceivedMarkers.append(marker)
                                self.receivedClusteringManager.addAnnotation(marker)
                            }
                        }
                    }
                    
                }
                
                //Perform clustering after load
                if self.beaconControl.selectedSegmentIndex == 0 {
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        self.performClustering()
                    })
                }
                
                //Stop activity indicator if the countries are already loaded
                self.receivedMarkersAreLoaded = true
                
                if self.countriesAreLoaded && self.sentMarkersAreLoaded {
                    
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
    
    
    internal func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        
        //Restrict zoom level
        if mapView.region.span.longitudeDelta < 0.2 {
            
            mapView.setRegion(MKCoordinateRegion(center: mapView.centerCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)), animated: true)
        }
        
        //Perform annotation clustering
        performClustering()
    }
    
    
    internal func performClustering() {
        
        
        NSOperationQueue().addOperationWithBlock({
            
            let mapBoundsWidth = Double(self.mapView.bounds.size.width)
            let mapRectWidth:Double = self.mapView.visibleMapRect.size.width
            let scale:Double = mapBoundsWidth / mapRectWidth
            
            //Conditionally refresh things based on beacon control selection
            if self.beaconControl.selectedSegmentIndex == 0 {
                
                let receivedAnnotationArray = self.receivedClusteringManager.clusteredAnnotationsWithinMapRect(self.mapView.visibleMapRect, withZoomScale:scale)
                self.receivedClusteringManager.displayAnnotations(receivedAnnotationArray, onMapView:self.mapView)
            }
            else if self.beaconControl.selectedSegmentIndex == 1 {
                
                let sentAnnotationArray = self.sentClusteringManager.clusteredAnnotationsWithinMapRect(self.mapView.visibleMapRect, withZoomScale:scale)
                self.sentClusteringManager.displayAnnotations(sentAnnotationArray, onMapView:self.mapView)
            }
        })
    }
    
    
    internal func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        var reuseId = ""
        var view = MKAnnotationView()
        
        if annotation.isKindOfClass(SentAnnotationCluster) {
            
            reuseId = "Cluster"
            view = SentAnnotationClusterView(annotation: annotation, reuseIdentifier: reuseId, options: nil)
        }
        if annotation.isKindOfClass(ReceivedAnnotationCluster) {
            
            reuseId = "Cluster"
            view = ReceivedAnnotationClusterView(annotation: annotation, reuseIdentifier: reuseId, options: nil)
        }
        else if annotation is SentAnnotation {
            
            view = SentBeacon(color: sentColor)
        }
        else if annotation is ReceivedAnnotation {
            
            view = ReceivedBeacon(color: receivedColor)
        }
        else {
            view.annotation = annotation
        }
        
        return view
    }
    
    
    
    
    @IBAction func beaconControlChanged(sender: AnyObject) {
        
        
        //First remove all existing annotations
        mapView.removeAnnotations(mapView.annotations)
        
        if beaconControl.selectedSegmentIndex == 0 {
            
            //Load received markers, show tutorial view
            mapView.addAnnotations(loadedReceivedMarkers)
            removeTutorialBeaconControlSentView()
            showTutorialBeaconControlReceivedView()
            
        }
        else if beaconControl.selectedSegmentIndex == 1 {
            
            //Load sent markers
            mapView.addAnnotations(loadedSentMarkers)
            removeTutorialBeaconControlReceivedView()
            showTutorialBeaconControlSentView()
        }
        
        //Cluster annotations
        performClustering()
    }
    
    
    internal func loadedInArray(location: CLLocationCoordinate2D, array: Array<MKAnnotation>) -> Bool {
        
        
        for marker in array {
            
            let coordinate = marker.coordinate
            if location.latitude == coordinate.latitude && location.longitude == coordinate.longitude {
                
                print("coordinate found")
                return true
            }
        }
        
        print("coordinate not found")
        return false
    }
    
    
    
    
    internal func showTutorialBeaconControlReceivedView() {
        
        
        //Show label if the user default is nil
        print("showTutorialBeaconControlReceivedView")
        if userDefaults.objectForKey("tutorialBeaconControlReceived") == nil {
            
            let heading = "Received Beacons"
            let text = "Where you got beacons from"
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(200)
                self.tutorialBeaconControlReceivedView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2 - self.beaconControl.bounds.width/4, y: self.beaconControl.frame.maxY + 25, width: width, height: height))
                self.tutorialBeaconControlReceivedView.showText(heading, text: text)
                self.tutorialBeaconControlReceivedView.pointTriangleUp()
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialBeaconControlReceivedView)
                self.view.bringSubviewToFront(self.tutorialBeaconControlReceivedView)
            })
        }
    }
    
    
    internal func removeTutorialBeaconControlReceivedView() {
        
        //Remove take beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialBeaconControlReceived") == nil {
            
            tutorialBeaconControlReceivedView.removeView("tutorialBeaconControlReceived")
        }
    }
    
    
    internal func showTutorialBeaconControlSentView() {
        
        
        //Show label if the user default is nil
        print("showTutorialBeaconControlSentView")
        if userDefaults.objectForKey("tutorialBeaconControlSent") == nil {
            
            let heading = "Beacons You Sent"
            let text = "Where your beacons went\nafter you sent them"
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(200)
                self.tutorialBeaconControlSentView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2 + self.beaconControl.bounds.width/4, y: self.beaconControl.frame.maxY + 25, width: width, height: height))
                self.tutorialBeaconControlSentView.showText(heading, text: text)
                self.tutorialBeaconControlSentView.pointTriangleUp()
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialBeaconControlSentView)
                self.view.bringSubviewToFront(self.tutorialBeaconControlSentView)
            })
        }
    }
    
    
    internal func removeTutorialBeaconControlSentView() {
        
        //Remove take beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialBeaconControlSent") == nil {
            
            tutorialBeaconControlSentView.removeView("tutorialBeaconControlSent")
        }
    }
    
    

    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        
        print("Status bar style method - Map Controller")
        return UIStatusBarStyle.Default
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}