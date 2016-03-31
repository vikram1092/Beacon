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
import Photos

class CameraController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    
    @IBOutlet var cameraImage: UIImageView!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var photoSendButton: UIButton!
    @IBOutlet var cameraSwitchButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var snapTimer: SnapTimer!
    @IBOutlet var captureShape: CaptureShape!
    @IBOutlet var blurView: UIView!
    @IBOutlet var alertButton: UIButton!
    
    var captureSession = AVCaptureSession()
    var audioSession = AVAudioSession()
    var stillImageOutput = AVCaptureStillImageOutput()
    var movieFileOutput = AVCaptureMovieFileOutput()
    var previewLayer = AVCaptureVideoPreviewLayer?()
    var moviePlayer = AVPlayerLayer()
    let focusShape = CAShapeLayer()
    var locManager = CLLocationManager()
    let fileManager = NSFileManager.defaultManager()
    let notifications = NSNotificationCenter.defaultCenter()
    let videoPath = NSTemporaryDirectory() + "userVideo.mov"
    
    var userLocation = PFGeoPoint()
    var userCountryCode = ""
    var userCountryReceived = false
    var userName = ""
    var userEmail = ""
    var flashToggle = false
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    //If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    var microphone : AVCaptureDevice?
    
    
    override func viewDidLoad() {
        
        
        //Retreive user details
        userName = userDefaults.objectForKey("userName") as! String
        userEmail = userDefaults.objectForKey("userEmail") as! String
        
        
        //Setup audio session
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.MixWithOthers)
            try audioSession.setActive(true)
        }
        catch let error as NSError { print("Error setting audio session category \(error)") }
        
        //Configure interruption notifications
        notifications.addObserver(self, selector: Selector("cameraInterrupted"), name: AVCaptureSessionWasInterruptedNotification, object: captureSession)
        
        //Clear video temp file
        clearVideoTempFile()
        
        //Add subviews to views
        cameraImage.addSubview(snapTimer)
        captureButton.addSubview(captureShape)
        
        //Initialize gesture recognizers and add to capture button
        let tap = UITapGestureRecognizer(target: self, action: Selector("takePhoto"))
        let hold = UILongPressGestureRecognizer(target: self, action: Selector("takeVideo:"))
        captureButton.addGestureRecognizer(tap)
        captureButton.addGestureRecognizer(hold)
        
        //Run view load as normal
        super.viewDidLoad()
        
        //Ask for location services permission
        self.locManager.requestWhenInUseAuthorization()
        
        //Initialize location manager
        locManager = CLLocationManager.init()
        self.locManager.delegate = self
        
        // Set up camera session & microphones
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        microphone = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
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
        closeButton.hidden = true
        photoSendButton.hidden = true
        flashButton.hidden = false
        backButton.hidden = false
        captureButton.hidden = false
        cameraSwitchButton.hidden = false
        
        //Hide alert layers
        blurView.alpha = 0
        blurView.userInteractionEnabled = false
        
        //Hide tab bar
        self.tabBarController!.tabBar.hidden = true
        
        //Configure capture session
        print("Capture session running: " + String(captureSession.running))
        if !captureSession.running && captureDevice != nil {
            beginSession()
        }
        
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
        
        
        super.viewDidAppear(true)
        
        //Get user location every time view appears
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
            self.getUserLocation()
        }
    }

    
    internal func beginSession() {
        
        
        
    
        //Start camera session, outputs and inputs
        captureSession = AVCaptureSession()
        addCameraOutputs()
        addCameraInputs()
        
        //Create and add the camera preview layer to camera image
        print("add session to layer")
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        //Add layer, run camera and configure layout subviews
        print("add camera image")
        cameraImage.layer.addSublayer(self.previewLayer!)
        print("start running")
        
        captureSession.startRunning()
        
        //Perform view fixes again
        viewDidLayoutSubviews()
    }
    
    
    internal func addCameraOutputs() {
        
        //Configure outputs
        stillImageOutput = AVCaptureStillImageOutput()
        movieFileOutput = AVCaptureMovieFileOutput()
        movieFileOutput.maxRecordedDuration = CMTime(seconds: 10, preferredTimescale: CMTimeScale())
        
        //Add camera outputs
        if captureSession.canAddOutput(stillImageOutput) {
            
            captureSession.addOutput(stillImageOutput)
            captureSession.addOutput(movieFileOutput)
        }
    }
    
    
    internal func addCameraInputs() {
        
        
        //Add camera inputs
        do {
            
            print("add inputs")
            if try captureSession.canAddInput(AVCaptureDeviceInput(device: captureDevice)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            }
            
            if try captureSession.canAddInput(AVCaptureDeviceInput(device: microphone)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: microphone))
            }
        }
        catch {
            
            //Error message for no camera found, or camera permission denied by user
            print("Camera not found.")
            let alert = UIAlertController(title: "Error displaying camera.", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func flashButtonPressed(sender: AnyObject) {
        
        //Toggle the flash variable
        print("Toggling flash!")
        flashToggle = !flashToggle
        
        //Get configuration lock on device
        do {
            try captureDevice?.lockForConfiguration()
        } catch _ {print("Error getting loc for device")}
        
        
        //Configure flash according to toggle
        if flashToggle {
            
            print("Flash is on")
            flashButton.setImage(UIImage(named: "FlashButtonOn"), forState: UIControlState.Normal)
            flashButton.reloadInputViews()
            
            captureDevice!.flashMode = AVCaptureFlashMode.On
            captureDevice!.unlockForConfiguration()
        }
        else {
            
            print("Flash is off")
            flashButton.setImage(UIImage(named: "FlashButtonOff"), forState: UIControlState.Normal)
            flashButton.reloadInputViews()
            
            if captureDevice!.torchMode == AVCaptureTorchMode.On {
                captureDevice!.torchMode = AVCaptureTorchMode.Off
            }
            
            captureDevice!.flashMode = AVCaptureFlashMode.On
            captureDevice!.unlockForConfiguration()
        }
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        
        //Segue back
        segueBackToTable()
    }
    
    
    @IBAction func switchCamera(sender: AnyObject) {
        
        //Reconfigure all parameters & stop current session
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
                    
                    break
                }
                else if(device.position == AVCaptureDevicePosition.Front && position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    
                    //Disable flash
                    flashButton.enabled = false
                    
                    break
                }
            }
        }
        
        //Begin camera session again with the new camera
        beginSession()
    }
    
    
    internal func takePhoto() {
        
        
        //Capture image
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { (buffer:CMSampleBuffer!, error:NSError!) -> Void in
            
            let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            let data_image = UIImage(data: image)
            self.cameraImage.image = data_image
            self.captureSession.stopRunning()
        }
        
        print("Pressed!")
        
        //Change elements on screen
        self.backButton.hidden = true
        self.captureButton.hidden = true
        self.flashButton.hidden = true
        self.cameraSwitchButton.hidden = true
        self.closeButton.hidden = false
        self.photoSendButton.hidden = false
    }
    
    
    internal func takeVideo(gestureRecognizer: UILongPressGestureRecognizer) {
        
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            //Change elements on screen
            self.backButton.hidden = true
            self.flashButton.hidden = true
            self.cameraSwitchButton.hidden = true
            
            //Turn on torch if flash is on
            toggleTorchMode()
            
            //Set path for video
            let url = NSURL(fileURLWithPath: videoPath)
            
            //Start recording
            print("Beginning video recording")
            movieFileOutput.stopRecording()
            movieFileOutput.startRecordingToOutputFileURL(url, recordingDelegate: VideoDelegate())
            
            //Start recording animation
            captureShape.startRecording()
            
        }
        else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            
            //Stop everything
            print("Ending video recording")
            movieFileOutput.stopRecording()
            captureSession.stopRunning()
            captureShape.stopRecording()
            
            //Turn off torch if it was turned on
            toggleTorchMode()
            
            //Change elements on screen
            self.backButton.hidden = true
            self.captureButton.hidden = true
            self.flashButton.hidden = true
            self.cameraSwitchButton.hidden = true
            self.closeButton.hidden = false
            self.photoSendButton.hidden = false
            
            //Start movie player
            initializeMoviePlayer()
            
        }
    }
    
    
    internal func initializeMoviePlayer() {
        
        
        //Initialize movie layer
        let player = AVPlayer(URL: NSURL(fileURLWithPath: videoPath))
        moviePlayer = AVPlayerLayer(player: player)
        
        //Set frame and video gravity
        moviePlayer.frame = self.view.bounds
        moviePlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        //Set loop function
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "restartVideoFromBeginning",
            name: AVPlayerItemDidPlayToEndTimeNotification,
            object: moviePlayer.player!.currentItem)
        cameraImage.layer.addSublayer(moviePlayer)
        
        //Bring timer to front
        cameraImage.bringSubviewToFront(snapTimer)
        
        //Play video
        moviePlayer.player!.play()
        
        //Start timer
        snapTimer.startTimer(player.currentItem!.asset.duration)
    }

    
    internal func toggleTorchMode() {
        
        //Toggle torch mode if user wants flash and if device has flash
        if flashToggle && captureDevice!.hasFlash {
            
            do {
                try captureDevice!.lockForConfiguration()
            } catch _ {print("Error getting loc for device")}
            
            if captureDevice!.torchMode == AVCaptureTorchMode.Off {
                
                captureDevice!.torchMode = AVCaptureTorchMode.On
                captureDevice!.unlockForConfiguration()
            }
            else {
                
                captureDevice!.torchMode = AVCaptureTorchMode.Off
                captureDevice!.unlockForConfiguration()
            }
        }
    }
    
    
    internal func restartVideoFromBeginning()  {
        
        
        //Create a CMTime for zero seconds so we can go back to the beginning
        let seconds : Int64 = 0
        let preferredTimeScale : Int32 = 1
        let seekTime : CMTime = CMTimeMake(seconds, preferredTimeScale)
        
        //Seek video to beginning
        if moviePlayer.player != nil {
            moviePlayer.player!.seekToTime(seekTime)
            
            //Bring timer to front
            cameraImage.bringSubviewToFront(snapTimer)
            
            //Play movie
            moviePlayer.player!.play()
            
            //Reset timer
            snapTimer.startTimer(moviePlayer.player!.currentItem!.asset.duration)
        }
    }
    
    
    @IBAction func closePhoto(sender: AnyObject) {
        
        //Begin camera session again, stop video, & toggle buttons
        moviePlayer.player = nil
        moviePlayer.removeFromSuperlayer()
        snapTimer.alpha = 0
        captureSession.startRunning()
        clearVideoTempFile()
        
        //Update screen elements
        self.closeButton.hidden = true
        self.photoSendButton.hidden = true
        self.flashButton.hidden = false
        self.backButton.hidden = false
        self.captureButton.hidden = false
        self.cameraSwitchButton.hidden = false
        self.cameraImage.image = nil
    }
    
    
    internal func clearVideoTempFile() {
        
        if fileManager.fileExistsAtPath(videoPath) {
            
            do {
                
                try fileManager.removeItemAtPath(videoPath)
            }
            catch let error as NSError {
                
                print("Error deleting video: \(error)")
            }
        }
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
        
        if userCountryCode == "" {
            
            getUserLocation()
            sendPhotoToDatabase()
        }
        else {
            sendPhotoToDatabase()
        }
    }
    
    
    internal func sendPhotoToDatabase() {
        
        
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
        
        if fileManager.fileExistsAtPath(videoPath) {
            
            //Set video just taken by user as PFFile
            photoObject["photo"] = PFFile(data: NSData(contentsOfFile: videoPath)!)
            photoObject["isVideo"] = true
            clearVideoTempFile()
            print("saved video to PFFile")
            
            
            //Save video locally in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                    
                    PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL(fileURLWithPath: self.videoPath))
                    
                    }, completionHandler: { success, error in
                        if !success { NSLog("Failed to create video: %@", error!) }
                })
            })
        }
        else {
            
            //Set photo just taken by user as PFFile
            photoObject["photo"] = PFFile(data: UIImageJPEGRepresentation(self.cameraImage.image!, CGFloat(0.6))!)
            photoObject["isVideo"] = false
            
            //Save image to local library
            UIImageWriteToSavedPhotosAlbum(cameraImage.image!, self, nil, nil)
        }
        
        //Send the updated photo object to database
        photoObject.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                
                // The photo has been saved, update user photos
                print("New photo saved!")
                self.updateUserPhotos()
                
                //Segue back to table
                self.activityIndicator.stopAnimating()
                self.closePhoto(self)
                self.segueBackToTable()
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
            
            showAlert("Error getting user's location. \nPlease check your internet connection or permissions.")
            
            /*
            //Error message for user location not found
            let alert = UIAlertController(title: "Error getting user location.", message: "Please check your internet connection or permissions.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                
                self.segueBackToTable()
            }))
            
            presentViewController(alert, animated: true, completion: nil)*/
        }
    }
    
    
    internal func showAlert(alertText: String) {
        
        alertButton.setTitle(alertText, forState: .Normal)
        alertButton.titleLabel?.textAlignment = NSTextAlignment.Center
        alertButton.sizeToFit()
        
        UIView.animateWithDuration(1) { () -> Void in
            
            self.blurView.alpha = 1
        }
    }
    
    
    internal func getCountryCode(locGeoPoint: PFGeoPoint) {
        
        //Get country for current row
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)
        print(location)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, locationError) -> Void in
            
            if locationError != nil {
                
                print("Reverse geocoder error: " + locationError!.description)
                
                
                self.showAlert("Error getting user's country. \nPlease check your internet connection or permissions.")
                
                /*
                //Error message for user location not found
                let alert = UIAlertController(title: "Error getting user country.", message: "Please check your internet connection or permissions.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    
                    self.segueBackToTable()
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)*/
            }
            else if placemarks!.count > 0 {
                
                //Get and save user's country
                print("Geo location country code: " + String(placemarks![0].ISOcountryCode!))
                self.userCountryCode = placemarks![0].ISOcountryCode!.lowercaseString
                
                //Save counry as user country
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    print("Saving user's country")
                    self.userDefaults.setObject(self.userCountryCode, forKey: "userCountry")
                })
                
            }
            else {
                print("Problem with the data received from geocoder")
            }
        }
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first!
        
        if (touch.view!.viewWithTag(1) != nil && captureDevice!.isFocusModeSupported(AVCaptureFocusMode.AutoFocus)) && captureSession.running && blurView.alpha == 0 {
            
            //Get point
            let focusPoint = CGPoint(x: touch.locationInView(self.view).x, y: touch.locationInView(self.view).y)
            
            //Draw focus shape
            print("Focusing")
            drawFocus(focusPoint)
            
            //Focus camera on point
            do {
                
                print("Locking for shifting focus")
                try captureDevice!.lockForConfiguration()
                captureDevice!.focusPointOfInterest = focusPoint
                captureDevice!.focusMode = AVCaptureFocusMode.AutoFocus
                captureDevice?.unlockForConfiguration()
                
            }
            catch let error as NSError { print("Error locking device for focus: \(error)") }
        }
    }
    
    
    internal func drawFocus(focusPoint: CGPoint) {
        
        //Define focus shape
        let objectSize = CGSize(width: 60.0, height: 60.0)
        let focusShapeOrigin = CGPoint(x: focusPoint.x - 30.0, y: focusPoint.y - 30.0)
        
        focusShape.path = UIBezierPath(ovalInRect: CGRect(origin: focusShapeOrigin, size: objectSize)).CGPath
        focusShape.fillColor = UIColor.clearColor().CGColor
        focusShape.strokeColor = UIColor.whiteColor().CGColor
        focusShape.strokeStart = 0.0
        focusShape.strokeEnd = 1.0
        
        self.view.layer.addSublayer(focusShape)
        
        delay(1.5) { () -> () in
            
            
            self.focusShape.removeFromSuperlayer()
        }
    }
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    internal func cameraInterrupted() {
        
        print("Camera interrupted")
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