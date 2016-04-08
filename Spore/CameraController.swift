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
import FBSDKCoreKit
import FBSDKLoginKit

class CameraController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, AVAudioSessionDelegate {
    
    
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
    @IBOutlet var alertView: UIView!
    @IBOutlet var alertButton: UIButton!
    
    var captureSession = AVCaptureSession()
    var audioSession = AVAudioSession()
    var stillImageOutput = AVCaptureStillImageOutput()
    var movieFileOutput = AVCaptureMovieFileOutput()
    var previewLayer = AVCaptureVideoPreviewLayer?()
    var moviePlayer = AVPlayerLayer()
    let cameraQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL)
    
    let focusShape = CAShapeLayer()
    var locManager = CLLocationManager()
    let fileManager = NSFileManager.defaultManager()
    let videoPath = NSTemporaryDirectory() + "userVideo.mov"
    let compressedVideoPath = NSTemporaryDirectory() + "userVideoCompressed.mov"
    let compressionGroup = dispatch_group_create()
    
    var userLocation = PFGeoPoint()
    var userCountry = ""
    var userName = ""
    var userEmail = ""
    var flashToggle = false
    var firstTime = true
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    //If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    var microphone : AVCaptureDevice?
    
    
    override func viewDidLoad() {
        
        //Run view load as normal
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        //Run as normal
        super.viewWillAppear(true)
        
        
        //Initialize buttons
        closeButton.hidden = true
        photoSendButton.hidden = true
        flashButton.hidden = false
        backButton.hidden = false
        captureButton.hidden = false
        cameraSwitchButton.hidden = false
        
        //Hide alert layers
        alertView.alpha = 0
        alertView.userInteractionEnabled = false
        
        //Hide tab bar
        self.tabBarController!.tabBar.hidden = true
    }
    
    
    override func viewDidLayoutSubviews() {
        
        //Adjusts camera to the screen after loading view
        if previewLayer != nil {
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                let bounds = self.cameraImage.bounds
                self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.previewLayer!.bounds = bounds
                self.previewLayer!.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
            })
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        //Appear as normal
        super.viewDidAppear(true)
        
        if userDefaults.objectForKey("userName") == nil {
            
            //Go back to login screen
            segueToLogin()
        }
        else if firstTime {
            
            //Set up camera and begin session
            initialViewSetup()
            initialSessionSetup()
            
            //Check if user is banned
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.userIsBanned()
            })
        }
        else if !firstTime && !captureSession.running && captureDevice != nil {
            
            //Start camera session that's already set up
            dispatch_async(cameraQueue, { () -> Void in
                
                self.captureSession.startRunning()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.cameraImage.layer.addSublayer(self.previewLayer!)
                })
            })
        }
    }
    
    
    internal func initialViewSetup() {
        
        //Get user details
        userName = userDefaults.objectForKey("userName") as! String
        userEmail = userDefaults.objectForKey("userEmail") as! String
        
        
        //Clear video temp files
        clearVideoTempFiles()
        
        //Add subviews to views
        cameraImage.addSubview(snapTimer)
        captureButton.addSubview(captureShape)
        
        //Initialize location manager
        locManager = CLLocationManager.init()
        self.locManager.delegate = self
    }
    
    
    internal func initialSessionSetup() {
    
        
        
        //Check permissions
        if checkAllPermissions() {
            
            
            //Get user location every time view appears
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                
                self.getUserLocation()
            }
            
            // Set up camera session & microphone
            captureSession.sessionPreset = AVCaptureSessionPresetMedium
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
            
            //If camera is found, begin session
            if captureDevice != nil {
                
                dispatch_async(cameraQueue, { () -> Void in
                    
                    self.beginSession()
                })
            }
            
        }
        else {
            
            //Request permissions
            requestPermissions()
        }
    }
    
    
    internal func beginSession() {
        
    
        //Start camera session, outputs and inputs
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        addCameraOutputs()
        addCameraInputs()
        
        //Configure device modes
        initializeCaptureDevice()
        
        //Configure capture session audio session
        captureSession.automaticallyConfiguresApplicationAudioSession = false
        
        //Create and add the camera preview layer to camera image
        print("add session to layer")
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.hidden = true
        
        //Commit configuration, run camera, add layer and configure layout subviews
        print("start running")
        captureSession.commitConfiguration()
        captureSession.startRunning()
        print("end running")
        
        //Add preview layer and perform view fixes again
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            print("add camera image")
            self.previewLayer!.hidden = false
            if self.firstTime {
                
                print("adding sublayer")
                self.cameraImage.layer.addSublayer(self.previewLayer!)
                self.viewDidLayoutSubviews()
            }
            self.firstTime = false
        }
    }
    
    
    internal func initializeCaptureDevice() {
        
        do {
            
            try captureDevice!.lockForConfiguration()
        }
        catch let error as NSError { print("Error locking device: \(error)") }
        
        
        if captureDevice!.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus) {
            
            print("Continuous auto focus supported")
            captureDevice!.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
        }
        
        if captureDevice!.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure){
            
            print("Continuous auto exposure supported")
            captureDevice!.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
        }
        
        captureDevice!.unlockForConfiguration()
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
            if try captureSession.canAddInput(AVCaptureDeviceInput(device: microphone)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: microphone))
            }
            
            if try captureSession.canAddInput(AVCaptureDeviceInput(device: captureDevice)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            }
        }
        catch {
            
            showAlert("Camera not found. \nPlease check your settings.")
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
        segueToTable()
    }
    
    
    @IBAction func switchCamera(sender: AnyObject) {
        
        
        dispatch_async(cameraQueue, { () -> Void in
            
            self.captureSession.stopRunning()
            
            //Reconfigure all parameters & stop current session
            let devices = AVCaptureDevice.devices()
            let position = self.captureDevice!.position
            
            //Remove camera input from session
            let inputs = self.captureSession.inputs
            print(inputs.count)
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(inputs[1] as! AVCaptureInput)
        
            
            // Loop through all the capture devices on this phone
            for device in devices {
                // Make sure this particular device supports video
                if (device.hasMediaType(AVMediaTypeVideo)) {
                    // Finally check the position and confirm we've got the OTHER camera
                    if(device.position == AVCaptureDevicePosition.Back && position == AVCaptureDevicePosition.Front) {
                        
                        self.captureDevice = device as? AVCaptureDevice
                        
                        //Enable flash
                        self.flashButton.enabled = true
                        
                        //Configure device modes
                        self.initializeCaptureDevice()
                        
                        break
                    }
                    else if(device.position == AVCaptureDevicePosition.Front && position == AVCaptureDevicePosition.Back) {
                        
                        self.captureDevice = device as? AVCaptureDevice
                        
                        //Disable flash
                        self.flashButton.enabled = false
                        
                        //Configure device modes
                        self.initializeCaptureDevice()
                        
                        break
                    }
                }
            }
            
            //Add input of new device to the camera
            do {
                
                let newDevice = try AVCaptureDeviceInput(device: self.captureDevice)
                
                if self.captureSession.canAddInput(newDevice) {
                    
                    self.captureSession.addInput(newDevice)
                }
                
            }
            catch let error as NSError { print("Error removing input: \(error)") }
            
            
            //Commit configuration of session and begin camera session again with the new camera
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            
        })
    }
    
    
    @IBAction func takePhoto(sender: UITapGestureRecognizer) {
        
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
    
    
    @IBAction func takeVideo(sender: UILongPressGestureRecognizer) {
        
        switch sender.state {
            
        case .Began:
            
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
            
        case .Ended:
            
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
            
        default:
            print("")
            
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
        clearVideoTempFiles()
        
        //Update screen elements
        self.closeButton.hidden = true
        self.photoSendButton.hidden = true
        self.flashButton.hidden = false
        self.backButton.hidden = false
        self.captureButton.hidden = false
        self.cameraSwitchButton.hidden = false
        self.cameraImage.image = nil
    }
    
    
    internal func clearVideoTempFiles() {
        
        if fileManager.fileExistsAtPath(videoPath) || fileManager.fileExistsAtPath(compressedVideoPath){
            
            do {
                
                try fileManager.removeItemAtPath(videoPath)
                try fileManager.removeItemAtPath(compressedVideoPath)
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
        
        if userCountry == "" {
            
            getUserLocation()
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.sendPhotoToDatabase()
            })
        }
        else {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.sendPhotoToDatabase()
            })
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
        print(userCountry)
        photoObject["countryCode"] = userCountry
        photoObject["spam"] = false
        
        if fileManager.fileExistsAtPath(videoPath) {
            
            //Compress video and send
            do {
                let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(videoPath)
                
                print((attr!.fileSize()/1024)/1024)
            } catch {
                print("Error: \(error)")
            }
            
            
            dispatch_group_enter(compressionGroup)
            
            //Compress video just taken by user as PFFile
            self.compressVideoFile(NSURL(fileURLWithPath: self.videoPath), outputURL: NSURL(fileURLWithPath: self.compressedVideoPath), handler: { (session) -> Void in
                
                print("Reached completion of compression")
                if session.status == AVAssetExportSessionStatus.Completed
                {
                    let compressedData = NSData(contentsOfFile: self.compressedVideoPath)
                    
                    if compressedData != nil {
                        print("File size after compression: \(Double(compressedData!.length / 1048576)) mb")
                    }
                }
                else
                {
                    let alert = UIAlertView(title: "Uh oh", message: " There was a problem compressing the video, try again. Error: \(session.error!.localizedDescription)", delegate: nil, cancelButtonTitle: "Okay")
                    
                    alert.show()
                    
                }
                
                dispatch_group_leave(self.compressionGroup)
            })
            
            
            
            dispatch_group_wait(compressionGroup, DISPATCH_TIME_FOREVER)
            
            
            if fileManager.fileExistsAtPath(compressedVideoPath) {
                
                photoObject["photo"] = PFFile(data: NSData(contentsOfFile: compressedVideoPath)!)
                photoObject["isVideo"] = true
                clearVideoTempFiles()
                print("saved video to PFFile")
            }
            
            //Save video to local library
            saveVideoLocally()
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
                
                //Segue back to table
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    // The photo has been saved, update user photos
                    print("New photo saved!")
                    self.updateUserPhotos()
                    
                    self.activityIndicator.stopAnimating()
                    self.closePhoto(self)
                    self.segueToTable()
                })
            }
            else {
                
                // There was a problem, check error.description
                print("Error saving photo")
                print(error!.description)
            }
        }
    }
    
    
    internal func saveVideoLocally() {
        
        //Save video locally in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                
                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(NSURL(fileURLWithPath: self.videoPath))
                
                }, completionHandler: { success, error in
                    if !success { NSLog("Failed to create video: %@", error!) }
            })
        })
    }
    
    
    internal func compressVideoFile(inputURL: NSURL, outputURL: NSURL, handler:(session: AVAssetExportSession)-> Void)
    {
        
        let urlAsset = AVURLAsset(URL: inputURL, options: nil)
        let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality)
        
        exportSession!.outputURL = outputURL
        exportSession!.outputFileType = AVFileTypeQuickTimeMovie
        exportSession!.shouldOptimizeForNetworkUse = true
        
        exportSession!.exportAsynchronouslyWithCompletionHandler { () -> Void in
            
            handler(session: exportSession!)
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
            
            showAlert("Error getting user's location. \nPlease check your location services settings or permissions.")
        }
    }
    
    
    internal func showAlert(alertText: String) {
        
        alertButton.setTitle(alertText, forState: .Normal)
        alertButton.titleLabel?.textAlignment = NSTextAlignment.Center
        alertButton.sizeToFit()
        
        alertView.alpha = 1
    }
    
    
    internal func getCountryCode(locGeoPoint: PFGeoPoint) {
        
        //Get country for current row
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)
        print(location)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, locationError) -> Void in
            
            if locationError != nil {
                
                print("Reverse geocoder error: " + locationError!.description)
                
                
                self.showAlert("Error getting user's country. \nPlease check your internet connection or permissions.")
            }
            else if placemarks!.count > 0 {
                
                //Get and save user's country
                print("Geo location country code: " + String(placemarks![0].ISOcountryCode!))
                self.userCountry = placemarks![0].ISOcountryCode!.lowercaseString
                
                //Save counry as user country
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    print("Saving user's country")
                    self.userDefaults.setObject(self.userCountry, forKey: "userCountry")
                })
                
            }
            else {
                print("Problem with the data received from geocoder")
            }
        }
    }
    
    
    @IBAction func cameraTapped(sender: UITapGestureRecognizer) {
        
        if captureSession.running && alertView.alpha == 0 {
            
            //Configure variables
            let touchPoint = sender.locationInView(sender.view)
            let focusPointx = touchPoint.x/sender.view!.bounds.width
            let focusPointy = touchPoint.y/sender.view!.bounds.height
            let focusPoint = CGPoint(x: focusPointx, y: focusPointy)
            
            //Draw focus shape
            print("Focusing")
            drawFocus(touchPoint)
            
            //Focus camera
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.focusCamera(focusPoint)
            })
        }
    }
    
    
    internal func focusCamera(focusPoint: CGPoint) {
        
        
        //Focus camera on point
        do {
            
            print("Locking for shifting focus")
            try captureDevice!.lockForConfiguration()
            
            if captureDevice!.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) {
                
                print("Auto focus supported")
                captureDevice!.focusMode = AVCaptureFocusMode.AutoFocus
                captureDevice!.focusPointOfInterest = focusPoint
            }
            
            if captureDevice!.isExposureModeSupported(AVCaptureExposureMode.AutoExpose) {
                
                print("Auto exposure supported")
                captureDevice!.exposureMode = AVCaptureExposureMode.AutoExpose
                captureDevice!.exposurePointOfInterest = focusPoint
            }
            
            if captureDevice!.isWhiteBalanceModeSupported(AVCaptureWhiteBalanceMode.AutoWhiteBalance) {
                
                print("Auto white balance supported")
                captureDevice!.whiteBalanceMode = AVCaptureWhiteBalanceMode.AutoWhiteBalance
            }
            
            captureDevice!.unlockForConfiguration()
            
        }
        catch let error as NSError { print("Error locking device for focus: \(error)") }
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
    
    
    internal func checkAllPermissions() -> Bool {
        
        
        let cameraPermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        
        if cameraPermission == AVAuthorizationStatus.Authorized && locationPermission == CLAuthorizationStatus.AuthorizedWhenInUse && microphonePermission == AVAuthorizationStatus.Authorized {
            return true
        }
        
        return false
    }
    
    
    internal func requestPermissions() {
        
        
        let cameraPermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        
        
        //Check camera  permission
        if cameraPermission == AVAuthorizationStatus.NotDetermined {
            
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (Bool) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initialSessionSetup()
                    }
                    else { self.requestPermissions() }
                })
            })
        }
        else if cameraPermission == AVAuthorizationStatus.Denied || cameraPermission == AVAuthorizationStatus.Restricted {
            
            showAlert("Please enable camera from your settings, you'll need it to use this app.")
        }
        //Check location permission
        else if locationPermission == CLAuthorizationStatus.NotDetermined {
            
            locManager.requestWhenInUseAuthorization()
        }
        else if locationPermission == CLAuthorizationStatus.Denied || locationPermission == CLAuthorizationStatus.Restricted {
            
            showAlert("Please enable locations from your settings, you'll need it to use this app.")
        }
        //Check microphone permission
        else if microphonePermission == AVAuthorizationStatus.NotDetermined {
            
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (Bool) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initialSessionSetup()
                    }
                    else { self.requestPermissions() }
                })
            })
        }
        else if microphonePermission == AVAuthorizationStatus.Denied || cameraPermission == AVAuthorizationStatus.Restricted {
            
            showAlert("Please enable microphone from your settings, you'll need it to use this app.")
        }
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        
        print("Status bar hiding method - Camera Controller")
        return true
    }
    
    
    internal func userIsBanned() {
        
        //Show alert if user is banned
        let query = PFQuery(className: "users")
        print("user email: " + userEmail)
        query.whereKey("email", equalTo: userEmail)
        query.getFirstObjectInBackgroundWithBlock { (userObject, error) -> Void in
            
            if error != nil {
                
                print("Error getting user banned status: " + error!.description)
            }
            else {
                
                let bannedStatus = userObject!.objectForKey("banned") as! BooleanLiteralType
                
                if bannedStatus {
                    
                    //Alert user about ban & segue
                    print("User is banned.")
                    let alert = UIAlertController(title: "You've been banned", message: "Allow us to investigate this issue & check back soon.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            self.logoutUser()
                            self.segueToLogin()
                        })
                    }))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    
                    print("User is not banned!")
                }
            }
        }
    }
    
    
    internal func logoutUser() {
        
        //Logout user
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        
        //Reset name and email local variables
        userDefaults.setObject(nil, forKey: "userName")
        userDefaults.setObject(nil, forKey: "userEmail")
        userDefaults.setObject(nil, forKey: "userCountry")
    }
    
    
    internal func segueToTable() {
        
        //Move within tab controller
        self.tabBarController?.selectedIndex = 1
        self.tabBarController!.tabBar.hidden = false
    }
    
    
    internal func segueToLogin() {
        
        //Segue to login screen
        print("Segue-ing")
        performSegueWithIdentifier("CameraToLoginSegue", sender: self)
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "CameraToLoginSegue" && segue.destinationViewController.isViewLoaded() {
            
            let loginController = segue.destinationViewController as! LoginController
            
            //Set buttons on appearance
            loginController.loginButton.alpha = 1
            loginController.alertButton.alpha = 0
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}