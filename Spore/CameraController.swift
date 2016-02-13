//
//  CameraController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/19/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse
import AVFoundation

class CameraController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    
    @IBOutlet var cameraImage: UIImageView!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var photoSendButton: UIButton!
    @IBOutlet var cameraSwitchButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    
    var previewLayer = AVCaptureVideoPreviewLayer?()
    var captureSession = AVCaptureSession()
    var stillImageOutput = AVCaptureStillImageOutput!()
    var locManager = CLLocationManager()
    var userLocation = PFGeoPoint()
    var userCountryCode = ""
    var userName = ""
    var userEmail = ""
    var flashToggle = false
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    
    //If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        
        //Initialize flash variable
        flashToggle = false
        
        //Retreive user details
        userName = userDefaults.objectForKey("userName") as! String
        userEmail = userDefaults.objectForKey("userEmail") as! String
        
        //Initialize location manager
        locManager = CLLocationManager.init()
        self.locManager.delegate = self
        
        //Run view load as normal
        super.viewDidLoad()
        
        //Ask for location services permission
        self.locManager.requestWhenInUseAuthorization()
        
        // Set up camera session
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        
        //If camera is found, begin session and capture user location in background
        if captureDevice != nil {
            beginSession()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //Initialize buttons
        self.closeButton.hidden = true
        self.photoSendButton.hidden = true
        self.flashButton.hidden = false
        self.backButton.hidden = false
        self.captureButton.hidden = false
        self.cameraSwitchButton.hidden = false
        
        self.tabBarController!.tabBar.hidden = true
        
        //Run as normal
        super.viewWillAppear(true)
    }
    
    
    
    override func viewDidLayoutSubviews() {
        
        
        //Adjusts camera to the screen after loading view
        let bounds = cameraImage.bounds
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer!.bounds = bounds
        previewLayer!.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        //Get user location every time view appears
        getUserLocation()
    }
    
    
    internal func beginSession() {
        
        //Start camera session
        stillImageOutput = AVCaptureStillImageOutput()
        print("add output")
        captureSession.addOutput(self.stillImageOutput)
        
        do {
            print("add input")
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        }
        catch {
            
            //Error message for no camera found, or camera permission denied by user
            print("Camera not found.")
            let alert = UIAlertController(title: "Error displaying camera.", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
            
            presentViewController(alert, animated: true, completion: nil)
        }
        
        //Create and add the camera layer to Image View
        print("add session to layer")
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        //Add layer, run camera and configure layout subviews
        print("add camera image")
        cameraImage.layer.addSublayer(self.previewLayer!)
        print("start running")
        
        captureSession.startRunning()
        viewDidLayoutSubviews()
    }
    
    
    @IBAction func flashButtonPressed(sender: AnyObject) {
        
        //Toggle the flash variable
        print("Toggling flash!")
        flashToggle = !flashToggle
        
        //Configure flash according to toggle
        if flashToggle {
            
            print("Flash is on")
            flashButton.setImage(UIImage(named: "FlashButtonOn"), forState: UIControlState.Normal)
            flashButton.reloadInputViews()
            
            do {
                try captureDevice?.lockForConfiguration()
            } catch _ {print("Error getting loc for device")}
            
            captureDevice!.flashMode = AVCaptureFlashMode.On
            captureDevice!.unlockForConfiguration()
        }
        else {
            
            print("Flash is off")
            flashButton.setImage(UIImage(named: "FlashButtonOff"), forState: UIControlState.Normal)
            flashButton.reloadInputViews()
            
            do {
                try captureDevice?.lockForConfiguration()
            } catch _ {print("Error getting loc for device")}
            
            captureDevice!.flashMode = AVCaptureFlashMode.On
            captureDevice!.unlockForConfiguration()
        }
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        
        //Segue back
        segueBackToTable()
    }
    
    
    @IBAction func switchCamera(sender: AnyObject) {
        
        //Reconfigure all parameters & stop cuurrent session
        let devices = AVCaptureDevice.devices()
        let position = captureDevice!.position
        
        captureSession.stopRunning()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        previewLayer!.removeFromSuperlayer()

        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the OTHER camera
                if(device.position == AVCaptureDevicePosition.Back && position == AVCaptureDevicePosition.Front) {
                    captureDevice = device as? AVCaptureDevice
                    
                    //Enable flash
                    flashButton.enabled = true
                }
                else if(device.position == AVCaptureDevicePosition.Front && position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    
                    //Disable flash
                    flashButton.enabled = false
                }
            }
        }
        
        //Begin camera session again with the new camera
        beginSession()
    }
    
    
    @IBAction func takePhoto(sender: AnyObject) {
        
        print("Pressed!")
        
        //Capture image
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { (buffer:CMSampleBuffer!, error:NSError!) -> Void in
            
            let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            let data_image = UIImage(data: image)
            self.cameraImage.image = data_image
            self.captureSession.stopRunning()
            
            //Change buttons on screen
            self.backButton.hidden = true
            self.captureButton.hidden = true
            self.flashButton.hidden = true
            self.cameraSwitchButton.hidden = true
            self.closeButton.hidden = false
            self.photoSendButton.hidden = false
        }
    }
    
    
    @IBAction func closePhoto(sender: AnyObject) {
        
        //Begin camera session again & toggle buttons
        self.captureSession.startRunning()
        self.closeButton.hidden = true
        self.photoSendButton.hidden = true
        self.flashButton.hidden = false
        self.backButton.hidden = false
        self.captureButton.hidden = false
        self.cameraSwitchButton.hidden = false
    }
    
    
    internal func updateUserPhotos() {
        
        let userToReceivePhotos = userDefaults.integerForKey("userToReceivePhotos") + 1
        print("userToReceiveStatus saving..." + String(userToReceivePhotos))
        userDefaults.setInteger(userToReceivePhotos, forKey: "userToReceivePhotos")
        print("Saved userToReceivePhotos")
    }
    
    
    @IBAction func sendPhoto(sender: AnyObject) {
        
        
        //Kick off activity indicator & hide button
        activityIndicator.startAnimating()
        photoSendButton.hidden = true
        
        //Update user photos
        updateUserPhotos()
        
        let photoObject = PFObject(className:"photo")
        
        //Set date and sender
        let date = NSDate()
        print(date)
        photoObject["sentAt"] = date
        print(userEmail)
        photoObject["sentBy"] = userEmail
        
        //Set user's geolocation
        print(String(userLocation.latitude) + ", " + String(userLocation.longitude))
        photoObject["sentFrom"] = self.userLocation
        
        //Set user's country's code
        print(userCountryCode)
        photoObject["countryCode"] = userCountryCode
        photoObject["spam"] = false
        
        //Set photo just taken by user as PFFile
        photoObject["photo"] = PFFile(data: UIImageJPEGRepresentation(self.cameraImage.image!, CGFloat(0.5))!)
        print("saved photo to PFFile")
        
        //Send the updated photo object to database
        photoObject.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                
                // The photo has been saved, go back to the main screen
                print("New photo saved!")
                
                //Segue back to table
                self.activityIndicator.stopAnimating()
                self.segueBackToTable()
                self.closePhoto(self)
            }
            else {
                
                // There was a problem, check error.description
                print("Error saving photo")
                print(error!.description)
            }
        }
    }
    
    
    internal func getUserLocation() {
        
        //Gets the user's current location
        locManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locManager.startUpdatingLocation()
    }
    
    
    internal func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //Gets user location and adds it to the main location variable
        if let locValue:CLLocationCoordinate2D = manager.location!.coordinate {
            userLocation = PFGeoPoint(latitude: locValue.latitude, longitude: locValue.longitude)
            print("locations = \(locValue.latitude) \(locValue.longitude)")
            
            //Stop updating location and get the country code for this location
            locManager.stopUpdatingLocation()
            getCountryCode(userLocation)
        }
        else {
            
            //Error message for user location not found
            let alert = UIAlertController(title: "Error getting user location.", message: "Please check your internet connection or permissions.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                
                self.segueBackToTable()
            }))
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    internal func getCountryCode(locGeoPoint: PFGeoPoint) {
        
        //Get country for current row
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)
        print(location)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, locationError) -> Void in
            
            if locationError != nil {
                
                print("Reverse geocoder error: " + locationError!.description)
                
                //Error message for user location not found
                let alert = UIAlertController(title: "Error getting user location.", message: "Please check your internet connection or permissions.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    
                    self.segueBackToTable()
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
            else if placemarks!.count > 0 {
                
                print("Geo location country code: " + String(placemarks![0].ISOcountryCode))
                self.userCountryCode = placemarks![0].ISOcountryCode!.lowercaseString
            }
            else {
                print("Problem with the data received from geocoder")
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    internal func segueBackToTable() {
        
        //Move within tab controller
        self.tabBarController?.selectedIndex = 0
        self.tabBarController!.tabBar.hidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}