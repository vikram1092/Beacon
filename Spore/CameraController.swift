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

class CameraController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, AVAudioRecorderDelegate {
    
    
    @IBOutlet var cameraImage: UIImageView!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var photoSendButton: UIButton!
    @IBOutlet var cameraSwitchButton: UIButton!
    @IBOutlet var activityIndicator: BeaconingIndicator!
    @IBOutlet var snapTimer: SnapTimer!
    @IBOutlet var captureShape: CaptureShape!
    @IBOutlet var alertView: UIView!
    @IBOutlet var alertButton: UIButton!
    @IBOutlet var zoomRecognizer: UIPinchGestureRecognizer!
    
    var captureSession = AVCaptureSession()
    var audioSession = AVAudioSession()
    var audioRecorder: AVAudioRecorder!
    var stillImageOutput = AVCaptureStillImageOutput()
    var movieFileOutput = AVCaptureMovieFileOutput()
    var previewLayer = AVCaptureVideoPreviewLayer?()
    var moviePlayer = AVPlayerLayer()
    var focusShape = FocusShape()
    var videoTimer = NSTimer()
    let cameraQueue = dispatch_queue_create("", DISPATCH_QUEUE_SERIAL)
    var captureSessionInterrupted = false
    let recorderSettings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
        AVFormatIDKey : NSNumber(int: Int32(kAudioFormatAppleLossless)),
        AVNumberOfChannelsKey : NSNumber(int: 1),
        AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue)),
        AVEncoderBitRateKey : NSNumber(int: Int32(320000))]
    
    var locManager = CLLocationManager()
    let fileManager = NSFileManager.defaultManager()
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let videoPath = NSTemporaryDirectory() + "userVideo.mov"
    let initialVideoPath = NSTemporaryDirectory() + "initialVideo.mov"
    let initialAudioPath = NSTemporaryDirectory() + "initialAudio.m4a"
    let videoFileExtension = ".mov"
    let imageFileExtension = ".jpg"
    let compressionGroup = dispatch_group_create()
    
    var userLocation = PFGeoPoint()
    var userCountry = ""
    var userState = ""
    var userCity = ""
    var userName = ""
    var userEmail = ""
    var firstTime = true
    var saveMedia = true
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    //If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    var microphone : AVCaptureDevice?
    
    
    override func viewDidLoad() {
        
        //Run view load as normal
        super.viewDidLoad()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
            //Register for interruption notifications
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleCaptureSessionInterruption:"), name: AVCaptureSessionWasInterruptedNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleAudioSessionInterruption:"), name: AVAudioSessionInterruptionNotification, object: nil)
            
        }
        
        //Set color for activity indicator
        self.activityIndicator.changeColor(UIColor.whiteColor().CGColor)
        
        //Adjust views
        self.backButton.imageEdgeInsets = UIEdgeInsets(top: 26, left: 20, bottom: 20, right: 36)
        self.cameraSwitchButton.imageEdgeInsets = UIEdgeInsets(top: 26, left: 36, bottom: 20, right: 20)
        self.flashButton.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 26, right: 36)
        self.closeButton.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 26, right: 36)
        self.cameraImage.addSubview(self.snapTimer)
        self.captureButton.addSubview(self.captureShape)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        print("viewWillAppear")
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
        closeAlert()
        
        //Hide tab bar
        self.tabBarController!.tabBar.hidden = true
    }
    
    
    override func viewDidLayoutSubviews() {
        
        print("viewDidLayoutSubviews")
        //Adjusts camera to the screen after updating view
        if previewLayer != nil {
        
            let bounds = cameraImage.bounds
            self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.previewLayer!.bounds = bounds
            self.previewLayer!.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        
        print("viewDidAppear")
        //Appear as normal
        super.viewDidAppear(true)
        
        //Resume animation if it was on
        activityIndicator.resumeAnimating()
        
        //Call the handler for dealing with possible scenarios
        initializingHandler()
        
        //Get user defaults
        getUserDefaults()
    }
    
    
    internal func initializingHandler() {
        
        
        print("initializingHandler")
        if userDefaults.objectForKey("userEmail") == nil{
            
            //Go back to login screen if no user is logged on
            segueToLogin()
        }
        else if firstTime && captureDevice == nil {
            
            //Start camera session that's already set up in serial queue
            dispatch_async(cameraQueue, { () -> Void in
                
                //Dispatch to high priority queue and monitor from camera queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    
                    //Set up camera and begin session
                    self.initialSessionSetup()
                    self.initialViewSetup()
                })
            })
            
            //Check if user is banned
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.userIsBanned()
            })
        }
        else if !firstTime && !captureSession.running && captureDevice != nil {
            
            //Start camera session that's already set up in serial queue
            dispatch_async(cameraQueue, { () -> Void in
                
                //Dispatch to high priority queue and monitor from camera queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    
                    self.captureSession.startRunning()
                    self.initializeLocationManager()
                })
            })
        }
    }
    
    
    internal func initialViewSetup() {
        
        print("initialViewSetup")
        //Clear video temp files
        clearVideoTempFiles()
    }
    
    
    internal func initialSessionSetup() {
    
        
        print("initialSessionSetup")
        //Check permissions
        if checkAllPermissions() {
            
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
                
                beginSession()
            }
            
        }
        else {
            
            //Request permissions
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.requestPermissions()
            })
        }
    }
    
    
    internal func beginSession() {
        
        
        print("beginSession")
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
        
        //Add preview layer and perform view fixes again
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            print("add camera image")
            self.previewLayer!.hidden = false
            if self.firstTime {
                
                print("adding sublayer")
                self.cameraImage.layer.addSublayer(self.previewLayer!)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.viewDidLayoutSubviews()
                })
                
                dispatch_async(self.cameraQueue, { () -> Void in
                    
                    self.captureSession.startRunning()
                    self.initializeLocationManager()
                })
                
                
            }
            
            self.firstTime = false
        }
    }
    
    
    internal func initializeLocationManager() {
        
        print("initializeLocationManager")
        //Initialize location manager
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.locManager = CLLocationManager.init()
            self.locManager.delegate = self
            
            //Get user location every time view appears
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                
                self.getUserLocation()
            }
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
        movieFileOutput.maxRecordedDuration = CMTimeMake(10, 1)
        
        //Add camera outputs
        if captureSession.canAddOutput(stillImageOutput) {
            
            captureSession.addOutput(stillImageOutput)
            captureSession.addOutput(movieFileOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    
    internal func addCameraInputs() {
        
        //Add camera inputs
        captureSession.beginConfiguration()
        
        do {
            
            print("add inputs")
            /*if try captureSession.canAddInput(AVCaptureDeviceInput(device: microphone)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: microphone))
            }*/
            
            if try captureSession.canAddInput(AVCaptureDeviceInput(device: captureDevice)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            }
        }
        catch {
            
            showAlert("Camera not found. \nPlease check your settings.")
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
        
        if userDefaults.objectForKey("saveMedia") != nil {
            
            saveMedia = userDefaults.boolForKey("saveMedia")
            print(saveMedia)
        }
    }
    
    
    @IBAction func flashButtonPressed(sender: AnyObject) {
        
        print("Toggling flash!")
        //Turn on torch if flash is on
        toggleTorchMode()
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        
        //Segue back
        segueToTable()
    }
    
    
    @IBAction func switchCamera(sender: AnyObject) {
        
        
        if captureSession.running {
            
            //Dispatch to camera dedicated serial queue
            dispatch_async(cameraQueue, { () -> Void in
                
                //Dispatch to high priority queue and monitor from serial queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    
                    self.captureSession.stopRunning()
                    
                    //Reconfigure all parameters & stop current session
                    let devices = AVCaptureDevice.devices()
                    let position = self.captureDevice!.position
                    
                    //Remove camera input from session
                    let inputs = self.captureSession.inputs
                    print(inputs.count)
                    self.captureSession.beginConfiguration()
                    self.captureSession.removeInput(inputs[0] as! AVCaptureInput)
                    
                    for input in inputs {
                        
                        let deviceInput = input as! AVCaptureDeviceInput
                        if deviceInput.device.hasMediaType(AVMediaTypeVideo) {
                            
                            self.captureSession.removeInput(deviceInput)
                        }
                    }
                    
                    // Loop through all the capture devices on this phone
                    for device in devices {
                        // Make sure this particular device supports video
                        if (device.hasMediaType(AVMediaTypeVideo)) {
                            // Finally check the position and confirm we've got the OTHER camera
                            if(device.position == AVCaptureDevicePosition.Back && position == AVCaptureDevicePosition.Front) {
                                
                                self.captureDevice = device as? AVCaptureDevice
                                
                                //Enable flash
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    
                                    self.flashButton.enabled = true
                                })
                                
                                //Configure device modes
                                self.initializeCaptureDevice()
                                
                                break
                            }
                            else if(device.position == AVCaptureDevicePosition.Front && position == AVCaptureDevicePosition.Back) {
                                
                                self.captureDevice = device as? AVCaptureDevice
                                
                                //Disable flash
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    
                                    self.flashButton.enabled = false
                                })
                                
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
            })
        }
    }
    
    
    @IBAction func takePhoto(sender: UITapGestureRecognizer) {
        
        //Capture image
        if !stillImageOutput.capturingStillImage && captureSession.running {
            
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { (buffer:CMSampleBuffer!, error:NSError!) -> Void in
                
                let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let data_image = UIImage(data: image)
                self.cameraImage.image = data_image
                self.captureSession.stopRunning()
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Change elements on screen
                    self.backButton.hidden = true
                    self.captureButton.hidden = true
                    self.flashButton.hidden = true
                    self.cameraSwitchButton.hidden = true
                    self.closeButton.hidden = false
                    self.photoSendButton.hidden = false
                })
            }
        }
        
        print("Pressed!")
    }
    
    
    @IBAction func takeVideo(sender: UILongPressGestureRecognizer) {
        
        
        switch sender.state {
            
        case .Began:
            
            //Change elements on screen
            self.backButton.hidden = true
            self.flashButton.hidden = true
            self.cameraSwitchButton.hidden = true
            
            //Set path for video
            let videoUrl = NSURL(fileURLWithPath: initialVideoPath)
            let audioUrl = NSURL(fileURLWithPath: initialAudioPath)
            
            //Set up audio recorder
            do {
                audioRecorder = try AVAudioRecorder(URL: audioUrl, settings: recorderSettings)
                audioRecorder.delegate = self
            }
            catch let error as NSError { print("Error recoding audio: \(error)")}
            
            //Start recording video and audio
            print("Beginning video recording")
            movieFileOutput.stopRecording()
            audioRecorder.stop()
            movieFileOutput.startRecordingToOutputFileURL(videoUrl, recordingDelegate: VideoDelegate())
            audioRecorder.record()
            
            //Start timer
            videoTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: Selector("stopTakingVideo"), userInfo: nil, repeats: false)
            
            //Start recording animation
            captureShape.startRecording()
            
        case .Ended:
            
            //Stop video if user stops and timer hasn't fired already
            print("Ended video recording")
            if videoTimer.valid {
                stopTakingVideo()
            }
            
        default:
            print("")
        }
    }
    
    
    internal func stopTakingVideo() {
        
        //Stop everything
        print("Ending video recording")
        videoTimer.invalidate()
        movieFileOutput.stopRecording()
        audioRecorder.stop()
        captureSession.stopRunning()
        captureShape.stopRecording()
        
        //Change elements on screen
        self.backButton.hidden = true
        self.captureButton.hidden = true
        self.flashButton.hidden = true
        self.cameraSwitchButton.hidden = true
        self.closeButton.hidden = false
        self.photoSendButton.hidden = false
        
        //Merge audio and video files into one file, then play for user
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
            
            self.mergeAudio(NSURL(fileURLWithPath: self.initialAudioPath), moviePathUrl: NSURL(fileURLWithPath: self.initialVideoPath), savePathUrl: NSURL(fileURLWithPath: self.videoPath))
        }
        
    }
    
    
    internal func mergeAudio(audioURL: NSURL, moviePathUrl: NSURL, savePathUrl: NSURL) {
        
        //Merge available audio and video files into one final video file
        let composition = AVMutableComposition()
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        let option = NSDictionary(object: true, forKey: "AVURLAssetPreferPreciseDurationAndTimingKey")
        let sourceAsset = AVURLAsset(URL: moviePathUrl, options: option as? [String : AnyObject])
        let audioAsset = AVURLAsset(URL: audioURL, options: option as? [String : AnyObject])
        
        //Default composition turns the video into landscape orientation. This returns the video into portrait orientation
        trackVideo.preferredTransform = CGAffineTransformMakeRotation(90.0 * CGFloat(M_PI) / 180.0)
        
        print(sourceAsset)
        print("playable: \(sourceAsset.playable)")
        print("exportable: \(sourceAsset.exportable)")
        print("readable: \(sourceAsset.readable)")
        
        let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
        let audios = audioAsset.tracksWithMediaType(AVMediaTypeAudio)
        
        if tracks.count > 0 && audios.count > 0 {
            
            //If audio exists, combine audio and video
            print("Audio & video")
            let assetTrack:AVAssetTrack = tracks[0] as AVAssetTrack
            let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
            let audioDuration:CMTime = assetTrackAudio.timeRange.duration
            
            do {
                
                try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,audioDuration), ofTrack: assetTrack, atTime: kCMTimeZero)
                try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,audioDuration), ofTrack: assetTrackAudio, atTime: kCMTimeZero)
                
                let assetExport: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
                assetExport.outputFileType = AVFileTypeQuickTimeMovie
                assetExport.outputURL = savePathUrl
                assetExport.shouldOptimizeForNetworkUse = true
                
                //Export to file and play it for the user
                assetExport.exportAsynchronouslyWithCompletionHandler({
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        //Start movie player
                        self.initializeMoviePlayer()
                    })
                })
            }
            catch let error as NSError { print("Error inserting time range: \(error)") }
        }
        else if fileManager.fileExistsAtPath(initialVideoPath) {
            
            //If video exists but audio doesn't, copy file to final location
            do {
                
                try fileManager.copyItemAtPath(initialVideoPath, toPath: videoPath)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    //Start movie player
                    self.initializeMoviePlayer()
                })
            }
            catch let error as NSError { print("Error copying file: \(error)") }
        }
    }
    
    
    internal func initializeMoviePlayer() {
        
        
        //Initialize movie layer
        print("initializeMoviePlayer")
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
        if captureDevice!.hasTorch {
            
            do {
                try captureDevice!.lockForConfiguration()
            } catch let error as NSError {print("Error getting lock for device \(error)")}
            
            if captureDevice!.torchMode == AVCaptureTorchMode.Off {
                
                //Turn on torch mode
                flashButton.setImage(UIImage(named: "FlashButtonOn"), forState: UIControlState.Normal)
                captureDevice!.torchMode = AVCaptureTorchMode.On
                captureDevice!.unlockForConfiguration()
            }
            else {
                
                //Turn off torch mode
                flashButton.setImage(UIImage(named: "FlashButtonOff"), forState: UIControlState.Normal)
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
        
        do {
            
            if fileManager.fileExistsAtPath(videoPath) {
                try fileManager.removeItemAtPath(videoPath)
            }
            
            if fileManager.fileExistsAtPath(initialVideoPath) {
                try fileManager.removeItemAtPath(initialVideoPath)
            }
            
            if fileManager.fileExistsAtPath(initialAudioPath) {
                try fileManager.removeItemAtPath(initialAudioPath)
            }
        }
        catch let error as NSError {
            
            print("Error deleting video: \(error)")
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
            
            dispatch_async(cameraQueue, { () -> Void in
                
                self.savePhotoToList()
            })
        }
        else {
            
            dispatch_async(cameraQueue, { () -> Void in
                
                self.savePhotoToList()
            })
        }
    }
    
    
    internal func savePhotoToList() {
        
        
        let photoObject = PFObject(className:"photo")
        
        //Set date and sender
        let date = NSDate()
        print(date)
        photoObject["sentAt"] = date
        print(userEmail)
        photoObject["sentBy"] = userEmail
        
        //Set local parameters
        photoObject["localTag"] = userEmail
        photoObject["localCreationTag"] = date
        
        //Set user's geolocation
        print(String(userLocation.latitude) + ", " + String(userLocation.longitude))
        photoObject["sentFrom"] = self.userLocation
        
        //Set user's geography details
        print(userCountry)
        photoObject["countryCode"] = userCountry
        
        print(userState)
        if userState != "" {
            
            photoObject["sentState"] = userState
        }
        print(userCity)
        if userCity != "" {
            
            photoObject["sentCity"] = userCity
        }
        photoObject["spam"] = false
        
        
        if fileManager.fileExistsAtPath(videoPath) {
            
            //Compress video and send
            do {
                let attr : NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(videoPath)
                
                print((attr!.fileSize()/1024)/1024)
            } catch {
                print("Error: \(error)")
            }
            
            
            //Save video to local library
            if saveMedia {
                saveVideoLocally()
            }
            
            //Declare compressed video path and save it
            var compressedVideoPathSuffix = "/compressedVideo_" + String(arc4random_uniform(100000)) + videoFileExtension
            
            while fileManager.fileExistsAtPath(documentsDirectory + compressedVideoPathSuffix) {
                compressedVideoPathSuffix = "/compressedVideo_" + String(arc4random_uniform(100000)) + videoFileExtension
            }
            
            photoObject["filePath"] = compressedVideoPathSuffix
            let compressedVideoPath = documentsDirectory + compressedVideoPathSuffix
            
            
            dispatch_group_enter(compressionGroup)
            
            //Compress video just taken by user as PFFile
            self.compressVideoFile(NSURL(fileURLWithPath: self.videoPath), outputURL: NSURL(fileURLWithPath: compressedVideoPath), handler: { (session) -> Void in
                
                print("Reached completion of compression")
                if session.status == AVAssetExportSessionStatus.Completed
                {
                    let compressedData = NSData(contentsOfFile: compressedVideoPath)
                    
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
            
            
            print("File exists: \(fileManager.fileExistsAtPath(compressedVideoPath))")
            if fileManager.fileExistsAtPath(compressedVideoPath) {
                
                photoObject["isVideo"] = true
                clearVideoTempFiles()
                print("saved video to file")
            }
            
        }
        else {
            
            //Save image to local file
            var imagePathSuffix = "/image_" + String(arc4random_uniform(100000)) + imageFileExtension
            
            while fileManager.fileExistsAtPath(documentsDirectory + imagePathSuffix) {
                imagePathSuffix = "/image_" + String(arc4random_uniform(100000)) + imageFileExtension
            }
            
            photoObject["filePath"] = imagePathSuffix
            let imagePath = documentsDirectory + imagePathSuffix
            let imageData = UIImageJPEGRepresentation(self.cameraImage.image!, CGFloat(0.6))
            imageData!.writeToFile(imagePath, atomically: true)
            
            print("File exists: \(fileManager.fileExistsAtPath(imagePath))")
            
            photoObject["isVideo"] = false
            
            //Save image to local library
            if saveMedia {
                UIImageWriteToSavedPhotosAlbum(cameraImage.image!, self, nil, nil)
            }
        }
        
        //Save photo object locally
        photoObject.pinInBackgroundWithBlock { (pinned, error) -> Void in
            
            if error != nil {
                
                print("Error pinning object: \(error)")
            }
            else {
                
                //Segue back to table
                print("Pinned: \(pinned)")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    // The photo has been saved, update user photos
                    print("New photo saved!")
                    
                    self.activityIndicator.stopAnimating()
                    self.closePhoto(self)
                    self.segueToTable()
                })
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
    
    
    @IBAction func cameraTapped(sender: UITapGestureRecognizer) {
        
        if captureSession.running && alertView.hidden {
            
            //Configure variables
            print(sender.view)
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
    
    
    @IBAction func cameraZoomed(recognizer: UIPinchGestureRecognizer) {
        
        
        let velocityDivider = CGFloat(15.0)
        
        if captureSession.running {
            
            do {
                
                try captureDevice!.lockForConfiguration()
                let zoomDistance = captureDevice!.videoZoomFactor + CGFloat(atan2f(Float(recognizer.velocity), Float(velocityDivider)))
                captureDevice!.videoZoomFactor = max(1.0, min(zoomDistance, captureDevice!.activeFormat.videoMaxZoomFactor))
                captureDevice!.unlockForConfiguration()
            }
            catch let error as NSError { print("Error locking device: \(error)") }
        }
    }
    
    
    internal func focusCamera(focusPoint: CGPoint) {
        
        
        //Focus camera on point
        do {
            
            print("Locking for shifting focus")
            try captureDevice!.lockForConfiguration()
            
            if captureDevice!.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus) {
                
                print("Auto focus supported")
                captureDevice!.focusPointOfInterest = focusPoint
                captureDevice!.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
            }
            
            if captureDevice!.isExposureModeSupported(AVCaptureExposureMode.ContinuousAutoExposure) {
                
                print("Auto exposure supported")
                captureDevice!.exposurePointOfInterest = focusPoint
                captureDevice!.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
            }
            
            if captureDevice!.isWhiteBalanceModeSupported(AVCaptureWhiteBalanceMode.ContinuousAutoWhiteBalance) {
                
                print("Auto white balance supported")
                captureDevice!.whiteBalanceMode = AVCaptureWhiteBalanceMode.ContinuousAutoWhiteBalance
            }
            
            captureDevice!.unlockForConfiguration()
            
        }
        catch let error as NSError { print("Error locking device for focus: \(error)") }
    }
    
    
    internal func drawFocus(touchPoint: CGPoint) {
        
        focusShape.removeFromSuperview()
        focusShape = FocusShape(drawPoint: touchPoint)
        cameraImage.addSubview(focusShape)
    }
    
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    internal func checkAllPermissions() -> Bool {
        
        
        let cameraPermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        
        if cameraPermission == AVAuthorizationStatus.Authorized && locationPermission == CLAuthorizationStatus.AuthorizedWhenInUse && microphonePermission == AVAuthorizationStatus.Authorized {
            
            print("All permissions are good")
            return true
        }
        
        return false
    }
    
    
    internal func requestPermissions() {
        
        
        let cameraPermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        print("Reached requestPermission")
        
        //Check camera  permission
        if cameraPermission == AVAuthorizationStatus.NotDetermined {
            
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (Bool) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initializingHandler()
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
            
            
            //Request authorization only, refer to override method "didChangeAuthorizationStatus"
            //for similar completion handling when authorization status changes
            locManager.requestWhenInUseAuthorization()
        }
        else if locationPermission == CLAuthorizationStatus.Denied || locationPermission == CLAuthorizationStatus.Restricted {
            
            showAlert("Please enable locations from your settings, you'll need it to use this app.")
        }
        //Check microphone permission
        else if microphonePermission == AVAuthorizationStatus.NotDetermined {
            
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio, completionHandler: { (Bool) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initializingHandler()
                    }
                    else { self.requestPermissions() }
                })
            })
        }
        else if microphonePermission == AVAuthorizationStatus.Denied || cameraPermission == AVAuthorizationStatus.Restricted {
            
            showAlert("Please enable microphone from your settings, you'll need it to use this app.")
        }
    }
    
    
    internal func getUserLocation() {
        
        //Gets the user's current location
        locManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locManager.startUpdatingLocation()
    }
    
    
    internal func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //Gets user location and adds it to the main location variable
        if let locValue:CLLocationCoordinate2D = manager.location?.coordinate {
            
            userLocation = PFGeoPoint(latitude: locValue.latitude, longitude: locValue.longitude)
            print("locations = \(locValue.latitude) \(locValue.longitude)")
            
            //Stop updating location and get the country code for this location
            locManager.stopUpdatingLocation()
            getPoliticalDetails(userLocation)
            
            //Save user location locally
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.userDefaults.setObject(self.userLocation.latitude, forKey: "userLatitude")
                self.userDefaults.setObject(self.userLocation.longitude, forKey: "userLongitude")
                
                print(self.userLocation.latitude)
                print(self.userLocation.longitude)
            })
        }
    }
    
    
    internal func getPoliticalDetails(locGeoPoint: PFGeoPoint) {
        
        //Get country for current row
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)
        print(location)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, locationError) -> Void in
            
            if locationError != nil {
                
                print("Reverse geocoder error: " + locationError!.description)
            }
            else if placemarks!.count > 0 {
                
                //Get and save user's country, state & city
                print("Geo location country code: \(placemarks![0].locality), \(placemarks![0].administrativeArea), \(placemarks![0].ISOcountryCode!)")
                self.userCountry = placemarks![0].ISOcountryCode!.lowercaseString
                
                
                if placemarks![0].administrativeArea != nil {
                    
                    self.userState = placemarks![0].administrativeArea!
                }
                
                if placemarks![0].locality != nil {
                    
                    self.userCity = placemarks![0].locality!
                }
                
                self.saveUserLocationDefaults()
                
                self.closeAlert()
            }
            else {
                print("Problem with the data received from geocoder")
            }
        }
    }
    
    
    internal func saveUserLocationDefaults() {
        
        //Save user country and city if nothing exists or if all three aren't null
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
    
            print("Saving user's country & city")
            self.userDefaults.setObject(self.userCountry, forKey: "userCountry")
            self.userDefaults.setObject(self.userState, forKey: "userState")
            self.userDefaults.setObject(self.userCity, forKey: "userCity")
        })
    }
    
    
    internal func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if !captureSession.running {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                print("Location authorization changed.")
                if self.checkAllPermissions() {
                    self.initializingHandler()
                }
                else { self.requestPermissions() }
            })
        }
    }
    
    
    internal func showAlert(alertText: String) {
        
        alertView.hidden = false
        alertButton.setTitle(alertText, forState: .Normal)
        alertButton.titleLabel?.textAlignment = NSTextAlignment.Center
    }
    
    
    internal func closeAlert() {
        
        alertView.hidden = true
        alertView.userInteractionEnabled = false
    }
    
    
    internal func handleCaptureSessionInterruption(notification: NSNotification) {
        
        let userInfo = (notification.userInfo! as NSDictionary)
        print(userInfo)
        let reason = userInfo.objectForKey(AVCaptureSessionInterruptionReasonKey) as! NSNumber
        
        
        if reason == AVCaptureSessionInterruptionReason.VideoDeviceNotAvailableWithMultipleForegroundApps.rawValue {
            
            print("Interruption began")
            showAlert("Another app is using your recording features.")
            captureSessionInterrupted = true
            dispatch_async(cameraQueue, { () -> Void in
                
                self.captureSession.stopRunning()
            })
        }
        else if reason == AVCaptureSessionInterruptionReason.VideoDeviceNotAvailableWithMultipleForegroundApps.rawValue {
            
            print("Interruption ended")
            closeAlert()
            dispatch_async(cameraQueue, { () -> Void in
                
                self.addCameraInputs()
                self.addCameraOutputs()
                self.captureSession.startRunning()
            })
            
        }
    }
    
    
    internal func handleAudioSessionInterruption(notification: NSNotification) {
        
        
        let userInfo = (notification.userInfo! as NSDictionary)
        print(userInfo)
        let reason = userInfo.objectForKey(AVAudioSessionInterruptionTypeKey) as! NSNumber
        
        if reason == AVAudioSessionInterruptionType.Began.rawValue {
            
            if captureSession.running {
                
                //Stop capture session if it was running
                print("Interruption began")
                showAlert("Another app is using your recording features.")
                captureSessionInterrupted = true
                dispatch_async(cameraQueue, { () -> Void in
                    
                    self.captureSession.stopRunning()
                })
            }
            else if moviePlayer.player?.currentItem != nil {
                
                //Pause movie player if it was playing
                moviePlayer.player?.pause()
            }
        }
        else if reason == AVAudioSessionInterruptionType.Ended.rawValue {
            
            
            if moviePlayer.player?.currentItem != nil {
                
                moviePlayer.player?.play()
            }
            else if captureSessionInterrupted {
                    
                    print("Interruption began")
                    closeAlert()
                    captureSessionInterrupted = false
                    dispatch_async(cameraQueue, { () -> Void in
                        
                        self.captureSession.startRunning()
                    })
            }
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
        self.tabBarController!.tabBar.hidden = false
        self.tabBarController?.selectedIndex = 1
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
            loginController.fbLoginButton.alpha = 1
            loginController.alertButton.alpha = 0
        }
    }
    
    
    internal func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        
        print("Finished recording")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}