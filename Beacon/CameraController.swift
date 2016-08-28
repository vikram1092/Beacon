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
import CoreTelephony
import Photos

class CameraController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, AVAudioRecorderDelegate {
    
    
    //UI elements
    @IBOutlet var topGradient: UIView!
    @IBOutlet var bottomGradient: UIView!
    @IBOutlet var cameraImage: UIImageView!
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var cameraSwitchButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var activityIndicator: BeaconingIndicator!
    @IBOutlet var snapTimer: SnapTimer!
    @IBOutlet var captureShape: CaptureShape!
    @IBOutlet var alertView: UIView!
    @IBOutlet var alertButton: UIButton!
    
    //Camera and media elements
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
    let recorderSettings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
        AVFormatIDKey : NSNumber(int: Int32(kAudioFormatAppleLossless)),
        AVNumberOfChannelsKey : NSNumber(int: 1),
        AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue)),
        AVEncoderBitRateKey : NSNumber(int: Int32(320000))]
    
    //File saving variables
    var locManager = CLLocationManager()
    let fileManager = NSFileManager.defaultManager()
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
    let videoPath = NSTemporaryDirectory() + "userVideo.mp4"
    let initialVideoPath = NSTemporaryDirectory() + "initialVideo.mov"
    let initialAudioPath = NSTemporaryDirectory() + "initialAudio.m4a"
    let videoFileExtension = ".mp4"
    let imageFileExtension = ".jpg"
    let compressionGroup = dispatch_group_create()
    
    //User variables
    var userLocation = PFGeoPoint(latitude: 0, longitude: 0)
    var userCountry = ""
    var userState = ""
    var userCity = ""
    var userID = ""
    var firstTime = true
    var saveMedia = true
    var beaconSending = false
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var replyToObject = PFObject(className: "photo")
    var replyToUser = ""
    var replyView = UIView()
    
    //Tutorial variables
    var tutorialTakeBeaconView = TutorialView()
    var tutorialSendBeaconView = TutorialView()
    
    //If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    var microphone : AVCaptureDevice?
    
    
    
    override func viewDidLoad() {
        
        
        //Run view load as normal
        super.viewDidLoad()
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
            //Register for interruption notifications
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.handleCaptureSessionInterruption(_:)), name: AVCaptureSessionWasInterruptedNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.continueVideo), name: UIApplicationWillEnterForegroundNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.doBackgroundTasks), name: UIApplicationDidEnterBackgroundNotification, object: nil)
            
        }
        
        
        //Set gradients
        setGradients()
        
        //Set color for activity indicator
        self.activityIndicator.changeColor(UIColor.whiteColor().CGColor)
        
        //Adjust button views
        cameraSwitchButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 20)
        flashButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 10)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 10)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 10)
        cameraImage.addSubview(snapTimer)
        captureButton.addSubview(captureShape)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        
        print("viewWillAppear")
        //Run as normal
        super.viewWillAppear(true)
        
        //Initialize buttons
        closeButton.hidden = true
        flashButton.hidden = false
        captureButton.hidden = false
        cameraSwitchButton.hidden = false
        backButton.hidden = false
        
        //Hide alert layers
        closeAlert()
        
        //Hide tab bar
        self.tabBarController!.tabBar.hidden = true
    }
    
    
    override func viewDidLayoutSubviews() {
        
        //Adjusts camera to the screen after updating view
        print("viewDidLayoutSubviews")
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
        
        //Call the handler for dealing with possible scenarios
        initializingHandler()
        
        //Get user defaults
        getUserDefaults()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        //Hide preview layer
        previewLayer?.hidden = true
        
        //Turn off flash
        turnTorchOff()
        
    }
    
    
    internal func initializingHandler() {
        
        
        print("initializingHandler")
        if userDefaults.objectForKey("userID") == nil {
            
            //Go back to login screen if no user is logged on
            segueToLogin()
        }
        else if firstTime && captureDevice == nil {
            
            print("Start camera")
            //Set up and start camera session
            dispatch_async(cameraQueue, { () -> Void in
                
                //Dispatch to high priority queue and monitor from camera queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    
                    
                    self.initializeSession()
                    self.initializeView()
                })
            })
            
            //Check if user is banned
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                self.userIsBanned()
            })
        }
        else if !firstTime && !captureSession.running && captureDevice != nil {
            
            print("Rerun camera")
            //Start camera session that's already set up in serial queue
            dispatch_async(cameraQueue, { () -> Void in
                
                //Dispatch to high priority queue and monitor from camera queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    
                    self.captureSession.startRunning()
                    self.previewLayer?.hidden = false
                    self.initializeLocationManager()
                })
            })
        }
        else if !firstTime && captureSession.running && captureDevice != nil {
            
            previewLayer?.hidden = false
        }
    }
    
    
    internal func initializeView() {
        
        print("initialViewSetup")
        //Clear video temp files
        clearVideoTempFiles()
        
    }
    
    
    internal func initializeSession() {
    
        
        print("initialSessionSetup")
        //Check permissions
        if checkAllPermissions() {
            
            //Set up camera session & microphone
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
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
        
        //Configure capture session
        captureSession.automaticallyConfiguresApplicationAudioSession = false
        captureSession.commitConfiguration()
        
        //Create the camera preview layer to add to the camera image
        print("add session to layer")
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        
        //Add preview layer and perform view fixes again
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            print("add camera image")
            if self.firstTime {
                
                print("adding sublayer")
                self.cameraImage.layer.addSublayer(self.previewLayer!)
                self.viewDidLayoutSubviews()
                
                dispatch_async(self.cameraQueue, { () -> Void in
                    
                    self.captureSession.startRunning()
                    
                    dispatch_async(dispatch_get_main_queue(), { 
                        
                        //Show preview layer now
                        self.previewLayer!.hidden = false
                        
                        //Show take beacon tutorial view
                        self.showTutorialTakeBeaconView()
                    })
                    
                    self.initializeLocationManager()
                })
            }
            
            //Set first time flag off
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
        if captureDevice!.lowLightBoostSupported {
            
            print("Low light boost supported")
            captureDevice!.automaticallyEnablesLowLightBoostWhenAvailable = true
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
            if try captureSession.canAddInput(AVCaptureDeviceInput(device: captureDevice)) {
                
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
            }
        }
        catch {
            
            showAlert("Camera not found.\nPlease check your settings.")
        }
        
    }
    
    
    internal func getUserDefaults() {
        
        //Get user details
        if userDefaults.objectForKey("userID") != nil {
            
            userID = userDefaults.objectForKey("userID") as! String
            print(userID)
        }
        
        if userDefaults.objectForKey("saveMedia") != nil {
            
            saveMedia = userDefaults.boolForKey("saveMedia")
            print(saveMedia)
        }
    }
    
    
    
    
    @IBAction func flashButtonPressed(sender: AnyObject) {
        
        //Turn on torch if flash is on
        toggleTorchMode()
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        
        //Segue back
        segueToTable(false)
    }
    
    
    @IBAction func switchCamera(sender: AnyObject) {
        
        
        //Perform only if camera is running and not recording
        if captureSession.running && !movieFileOutput.recording {
            
            
            //Dispatch to camera dedicated serial queue
            dispatch_async(cameraQueue, { () -> Void in
                
                //Dispatch to high priority queue
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    
                    self.captureSession.stopRunning()
                    
                    //Reconfigure all parameters & stop current session
                    let devices = AVCaptureDevice.devices()
                    let position = self.captureDevice!.position
                    
                    //Remove camera input from session
                    let inputs = self.captureSession.inputs
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
                                    
                                    self.turnTorchOff()
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
            
            
            //Hide take beacon tutorial view
            removeTutorialTakeBeaconView()
            
            //Take a photo asyncronously and prepare button for sending
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { (buffer:CMSampleBuffer!, error:NSError!) -> Void in
                
                if error != nil {
                    
                    print("Error capturing photo: \(error)")
                }
                else {
                    
                    //Capture image if no errors in connection occurred
                    let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    let data_image = UIImage(data: image)
                    self.cameraImage.image = data_image
                    self.captureSession.stopRunning()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        //Change elements on screen
                        self.turnTorchOff()
                        self.flashButton.hidden = true
                        self.cameraSwitchButton.hidden = true
                        self.backButton.hidden = true
                        self.closeButton.hidden = false
                        
                        //Show send beacon tutorial view and transition to send mode
                        self.showTutorialSendBeaconView()
                        self.captureShape.transitionToSendMode()
                    })
                }
            }
        }
        else if captureShape.sendView.alpha == 1 && !stillImageOutput.capturingStillImage && !movieFileOutput.recording && !beaconSending {
            
            
            //Hide send beacon tutorial view
            removeTutorialSendBeaconView()
            
            //Send beacon if send button has been activated and a beacon is not currently sending
            sendBeacon()
        }
        print("Pressed!")
    }
    
    
    @IBAction func takeVideo(sender: UILongPressGestureRecognizer) {
        
        
        //If capture session is running, take the video
        if captureSession.running {
            
            
            switch sender.state {
                
            case .Began:
                
                //Hide tutorial view
                removeTutorialTakeBeaconView()
                
                //Change elements on screen
                self.flashButton.hidden = true
                self.cameraSwitchButton.hidden = true
                self.backButton.hidden = true
                
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
                videoTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(stopTakingVideo), userInfo: nil, repeats: false)
                
                //Start recording animation
                captureShape.startRecording()
                
                
            case .Ended:
                
                
                //Stop video if user stops and timer hasn't fired already
                print("Ended video recording")
                if videoTimer.valid {
                    stopTakingVideo()
                }
                
                
            default: ()
            }
        }
    }
    
    
    internal func stopTakingVideo() {
        
        //Stop everything
        print("Ending video recording")
        videoTimer.invalidate()
        movieFileOutput.stopRecording()
        audioRecorder.stop()
        captureSession.stopRunning()
        turnTorchOff()
        
        //Change elements on screen
        self.flashButton.hidden = true
        self.cameraSwitchButton.hidden = true
        self.backButton.hidden = true
        self.closeButton.hidden = false
        
        //Show send beacon tutorial view and transition to send mode
        self.showTutorialSendBeaconView()
        captureShape.transitionToSendMode()
        
        
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
        
        
        //Check close button to avoid a simultaneous button press glitch
        if !closeButton.hidden {
            
            //Initialize movie layer
            print("initializeMoviePlayer")
            let player = AVPlayer(URL: NSURL(fileURLWithPath: videoPath))
            moviePlayer = AVPlayerLayer(player: player)
            
            //Set frame and video gravity
            moviePlayer.frame = self.view.bounds
            moviePlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            //Change audio session if user is in a call
            if CTCallCenter().currentCalls != nil {
                
                changeAudioSession(AVAudioSessionCategoryAmbient)
            }
            
            //Set loop function
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: #selector(restartVideoFromBeginning),
                name: AVPlayerItemDidPlayToEndTimeNotification,
                object: moviePlayer.player!.currentItem)
            
            //Add layer to view and bring timer to front
            cameraImage.layer.addSublayer(moviePlayer)
            cameraImage.bringSubviewToFront(snapTimer)
            
            //Play video
            moviePlayer.player!.play()
            
            //Start timer
            snapTimer.startTimer(player.currentItem!.asset.duration)
        }
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
    
    
    internal func turnTorchOff() {
        
        //Turn off flash if its on
        flashButton.setImage(UIImage(named: "FlashButtonOff"), forState: UIControlState.Normal)
        if captureDevice != nil {
            
            if captureDevice!.hasTorch {
                
                //Lock device for configuration
                do {
                    try captureDevice!.lockForConfiguration()
                } catch let error as NSError {print("Error getting lock for device \(error)")}
                
                if captureDevice!.torchMode == AVCaptureTorchMode.On {
                    
                    //Turn off torch mode and unlock device
                    captureDevice!.torchMode = AVCaptureTorchMode.Off
                    captureDevice!.unlockForConfiguration()
                }
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
            
            print("restarting")
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
        
        
        //Change audio session if user is in a call
        changeAudioSession(AVAudioSessionCategoryPlayAndRecord)
        
        //Begin camera session again, stop video, & toggle buttons
        moviePlayer.player = nil
        moviePlayer.removeFromSuperlayer()
        snapTimer.alpha = 0
        captureShape.resetShape()
        captureSession.startRunning()
        clearVideoTempFiles()
        
        //Update screen elements
        self.closeButton.hidden = true
        self.flashButton.hidden = false
        self.cameraSwitchButton.hidden = false
        self.backButton.hidden = false
        self.cameraImage.image = nil
        
        //Remove send beacon tutorial
        self.removeTutorialSendBeaconView()
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
        userDefaults.setInteger(userToReceivePhotos, forKey: "userToReceivePhotos")
        print("Saved userToReceivePhotos")
    }
    
    
    internal func sendBeacon() {
    
  
        //Kick off activity indicator & hide button
        activityIndicator.startAnimating()
        beaconSending = true
        
        if userCountry == "" {
            
            getUserLocation()
            
            dispatch_async(cameraQueue, { () -> Void in
                
                self.saveBeaconToList()
            })
        }
        else {
            
            dispatch_async(cameraQueue, { () -> Void in
                
                self.saveBeaconToList()
            })
        }
    }
    
    
    internal func saveBeaconToList() {
        
        
        let photoObject = PFObject(className:"photo")
        
        //Set date and sender
        let date = NSDate()
        photoObject["sentAt"] = date
        photoObject["sentBy"] = userID
        
        //Set local parameters
        photoObject["localTag"] = userID
        photoObject["localCreationTag"] = date
        
        //Set user's geolocation
        photoObject["sentFrom"] = self.userLocation
        
        //Set user's geography details
        photoObject["countryCode"] = userCountry
        
        if userState != "" {
            
            photoObject["sentState"] = userState
        }
        if userCity != "" {
            
            photoObject["sentCity"] = userCity
        }
        photoObject["spam"] = false
        
        
        //Set reply user if it's not blank. Also update object locally as replied to
        if replyToUser != "" {
            
            print("Adding reply details")
            photoObject["replyTo"] = replyToUser
            
            replyToObject["replied"] = true
            replyToObject.pinInBackground()
        }
        
        
        //Compress video and send if it exists
        if fileManager.fileExistsAtPath(videoPath) {
            

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
                { }
                else if session.error != nil
                {
                    print("Error compressing video: \(session.error)")
                }
                
                dispatch_group_leave(self.compressionGroup)
            })
            
            //Wait until dispatch group is finished, then proceed
            dispatch_group_wait(compressionGroup, DISPATCH_TIME_FOREVER)
            
            
            if fileManager.fileExistsAtPath(compressedVideoPath) {
                
                photoObject["isVideo"] = true
                
                do {
                    
                    var fileSize : UInt64
                    let attr:NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(compressedVideoPath)
                    if let _attr = attr {
                        fileSize = _attr.fileSize();
                        print("compressed video size: \(fileSize/(1024))")
                    }
                    
                }
                catch { print("Error")}
                
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
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    // The photo has been saved, update user photos
                    print("New photo saved!")
                    
                    self.activityIndicator.stopAnimating()
                    self.closePhoto(self)
                    self.segueToTable(true)
                    
                    self.beaconSending = false
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
        let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset960x540)
        
        exportSession!.outputURL = outputURL
        exportSession!.outputFileType = AVFileTypeMPEG4
        exportSession!.shouldOptimizeForNetworkUse = true
        
        exportSession!.exportAsynchronouslyWithCompletionHandler { () -> Void in
            
            handler(session: exportSession!)
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
    
    
    
    
    internal func replyMode(object: PFObject, user: String, replyImage: UIImage) {
        
        
        //Necessary variables
        let viewWidth = CGFloat(120)
        let viewHeight = CGFloat(50)
        let padding = CGFloat(10)
        let imageSize = CGFloat(30)
        let closeViewWidth = CGFloat(0)
        
        
        //Initialize views
        replyView = UIView(frame: CGRect(x: self.view.center.x - viewWidth/2, y: 10, width: viewWidth, height: viewHeight))
        let blurView = UIVisualEffectView(frame: replyView.bounds)
        let label = UILabel(frame: CGRect(x: padding, y: 0, width: viewWidth - imageSize - closeViewWidth - (padding * 2), height: viewHeight))
        let imageView = UIImageView(frame: CGRect(x: label.bounds.width + padding, y: padding, width: imageSize, height: imageSize))
        let showCancelButton = UIButton(frame: replyView.bounds)
        let cancelReplyButton = UIButton(frame: CGRect(x: 0, y: 0, width: viewHeight, height: viewHeight))
        
            
        //Initialize label
        label.text = "Reply to"
        label.textColor = UIColor.whiteColor()
        label.textAlignment = NSTextAlignment.Center
        
        //Initialize image
        imageView.image = replyImage
        imageView.tintColor = UIColor.whiteColor()
        
        //Initialize blur view
        blurView.effect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        blurView.tag = 1
        
        //Initialize close button
        let center = CGPoint(x: cancelReplyButton.bounds.width/2, y: viewHeight/2)
        let closeLayer1 = CAShapeLayer()
        let closeLayer2 = CAShapeLayer()
        let path1 = UIBezierPath()
        let path2 = UIBezierPath()
        let path3 = UIBezierPath()
        let length  = CGFloat(5)
        
        path1.moveToPoint(CGPoint(x: center.x - length, y: center.y - length))
        path1.addLineToPoint(CGPoint(x: center.x + length, y: center.y + length))
        
        path2.moveToPoint(CGPoint(x: center.x + length, y: center.y - length))
        path2.addLineToPoint(CGPoint(x: center.x - length, y: center.y + length))
        
        path3.moveToPoint(CGPoint(x: 0, y: 7))
        path3.addLineToPoint(CGPoint(x: 0, y: viewHeight - 7))
        
        closeLayer1.path = path1.CGPath
        closeLayer1.fillColor = UIColor.clearColor().CGColor
        closeLayer1.strokeColor = UIColor.whiteColor().CGColor
        closeLayer1.lineCap = kCALineCapRound
        
        closeLayer2.path = path2.CGPath
        closeLayer2.fillColor = UIColor.clearColor().CGColor
        closeLayer2.strokeColor = UIColor.whiteColor().CGColor
        closeLayer2.lineCap = kCALineCapRound
        
        cancelReplyButton.layer.addSublayer(closeLayer1)
        cancelReplyButton.layer.addSublayer(closeLayer2)
        cancelReplyButton.tag = 2
        cancelReplyButton.userInteractionEnabled = true
        
        cancelReplyButton.alpha = 0
        cancelReplyButton.addTarget(self, action: #selector(cancelReplyPressed), forControlEvents: UIControlEvents.TouchUpInside)
        
        showCancelButton.tag = 3
        showCancelButton.addTarget(self, action: #selector(replyViewInitialPressed), forControlEvents: UIControlEvents.TouchUpInside)
        
        
        //Add views to view
        replyView.addSubview(blurView)
        replyView.addSubview(label)
        replyView.addSubview(imageView)
        replyView.addSubview(cancelReplyButton)
        replyView.addSubview(showCancelButton)
        
        
        //Modify reply view
        replyView.layer.cornerRadius = viewHeight/2
        replyView.clipsToBounds = true
        
        
        //Add and animate entrance into view
        let introWidth = CGFloat(50)
        replyView.frame = CGRect(x: self.view.center.x - introWidth/2, y: 10, width: introWidth, height: 50)
        label.alpha = 0
        imageView.alpha = 0
        
        self.view.insertSubview(replyView, belowSubview: alertView)
        
        UIView.animateWithDuration(0.4) {
            
            self.replyView.frame = CGRect(x: self.view.center.x - viewWidth/2, y: 10, width: viewWidth, height: viewHeight)
            label.alpha = 1
            imageView.alpha = 1
        }
        
        
        //Save object and username for sending beacon
        replyToObject = object
        replyToUser = user
        
    }
    
    
    @IBAction func replyViewInitialPressed(sender: AnyObject) {
        
        
        print("replyViewInitialPressed")
        
        if captureSession.running {
            
            //Get cancel buttons
            let originalWidth = replyView.bounds.width
            let cancelReplyButton = replyView.viewWithTag(2)!
            let showCancelButton = replyView.viewWithTag(3)!
            
            //Remove show cancel button and bring cancel button to front
            showCancelButton.removeFromSuperview()
            replyView.bringSubviewToFront(cancelReplyButton)
            
            
            UIView.animateWithDuration(0.4, animations: {
                
                
                //Hide all views except cancel button
                for view in self.replyView.subviews {
                    
                    if view.tag != 1 && view.tag != 2 {
                        
                        view.alpha = 0
                    }
                }
                
                //Shrink reply view
                self.replyView.frame = CGRect(x: self.view.center.x - self.replyView.bounds.height/2, y: 10, width: self.replyView.bounds.height, height: self.replyView.bounds.height)
                
                cancelReplyButton.frame = self.replyView.bounds
                cancelReplyButton.alpha = 1
                
                
            }) { (Bool) in
                
                //Dispatch block after a certain time. Interruption safe!
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    UIView.animateWithDuration(0.4, animations: {
                        
                        //Show all views and hide cancel button
                        for view in self.replyView.subviews {
                            
                            if view.tag != 1 && view.tag != 2 {
                                
                                view.alpha = 1
                            }
                        }
                        
                        //Expand reply view and adjust calcel reply button
                        self.replyView.frame = CGRect(x: self.view.center.x - originalWidth/2, y: 10, width: originalWidth, height: self.replyView.bounds.height)
                        
                        
                        cancelReplyButton.frame = self.replyView.bounds
                        cancelReplyButton.alpha = 0
                        
                        }, completion: { (Bool) in
                            
                            //Put back show cancel button
                            self.replyView.addSubview(showCancelButton)
                            self.replyView.bringSubviewToFront(showCancelButton)
                            
                    })
                })
            }
        }
    }
    
    
    @IBAction func cancelReplyPressed() {
        
        //Stop replying
        print("cancelReplyPressed")
        stopReplying(true)
    }
    
    
    internal func stopReplying(clearDetails: Bool) {
        
        
        //Remove view and clear details if you want to
        if tabBarController?.selectedIndex == 0 {
            
            UIView.animateWithDuration(0.4, animations: {
                
                self.replyView.alpha = 0
                
                }, completion: { (Bool) in
                    
                    self.replyView.removeFromSuperview()
            })
        }
        else {
            
            replyView.removeFromSuperview()
        }
        
        if clearDetails {
            replyToObject = PFObject(className: "photo")
            replyToUser = ""
        }
    }
    
    
    
    
    internal func checkAllPermissions() -> Bool {
        
        
        let cameraPermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        
        if cameraPermission == AVAuthorizationStatus.Authorized && locationPermission == CLAuthorizationStatus.AuthorizedWhenInUse && microphonePermission != AVAuthorizationStatus.NotDetermined {
            
            print("All permissions are good")
            return true
        }
        
        return false
    }
    
    
    internal func requestPermissions() {
        
        
        //Initialize permissions and check each one
        let cameraPermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio)
        print("requestPermission")
        
        
        //Check camera permission
        if cameraPermission == AVAuthorizationStatus.NotDetermined {
            
            
            //Request access for camera
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (Bool) -> Void in
                
                //Check all permissions after user response
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initializingHandler()
                    }
                    else { self.requestPermissions() }
                })
            })
        }
        else if cameraPermission == AVAuthorizationStatus.Denied || cameraPermission == AVAuthorizationStatus.Restricted {
            
            showAlert("Please enable the camera from your settings, you'll need it to use this app.")
        }
        //Check location permission
        else if locationPermission == CLAuthorizationStatus.NotDetermined {
            
            //Change delegate to self and request authorization.
            //Refer to override method "didChangeAuthorizationStatus"
            //for similar completion handling when authorization status changes.
            locManager.delegate = self
            locManager.requestWhenInUseAuthorization()
        }
        else if locationPermission == CLAuthorizationStatus.Denied || locationPermission == CLAuthorizationStatus.Restricted {
            
            showAlert("Please enable locations from your settings, you'll need it to use this app.")
        }
        //Check microphone permission
        else if microphonePermission == AVAuthorizationStatus.NotDetermined {
            
            
            //Request access for microphone
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeAudio, completionHandler: { (Bool) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initializingHandler()
                    }
                    else { self.requestPermissions() }
                })
            })
        }
    }
    
    
    internal func getUserLocation() {
        
        //Gets the user's current location
        locManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locManager.startUpdatingLocation()
    }
    
    
    internal func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let locValue:CLLocationCoordinate2D = manager.location?.coordinate {
            
            //Gets user location and adds it to the main location variable
            userLocation = PFGeoPoint(latitude: locValue.latitude, longitude: locValue.longitude)
            
            //Stop updating location and get the country code for this location
            locManager.stopUpdatingLocation()
            getPoliticalDetails(userLocation)
            
            //Save user location locally
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.userDefaults.setObject(self.userLocation.latitude, forKey: "userLatitude")
                self.userDefaults.setObject(self.userLocation.longitude, forKey: "userLongitude")
            })
        }
    }
    
    
    internal func getPoliticalDetails(locGeoPoint: PFGeoPoint) {
        
        
        //Get country for current row
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)

        
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
                
                //Save location information
                self.saveUserLocationDefaults()
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
            
            print("didChangeAuthorizationStatus: is not running")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                print("Location authorization changed.")
                if self.checkAllPermissions() {
                    self.initializingHandler()
                }
                else { self.requestPermissions() }
            })
        }
        else {
            
            print("didChangeAuthorizationStatus: is running")
        }
    }
    
    
    
    
    internal func showAlert(alertText: String) {
        
        alertView.alpha = 1
        alertButton.setTitle(alertText, forState: .Normal)
        alertButton.titleLabel?.textAlignment = NSTextAlignment.Center
    }
    
    
    internal func closeAlert() {
        
        alertView.alpha = 0
        alertView.userInteractionEnabled = false
    }
    
    
    internal func handleCaptureSessionInterruption(notification: NSNotification) {
        
        
        let userInfo = (notification.userInfo! as NSDictionary)
        print(userInfo)
        let reason = userInfo.objectForKey(AVCaptureSessionInterruptionReasonKey) as! NSNumber
        
        if reason == AVCaptureSessionInterruptionReason.VideoDeviceNotAvailableWithMultipleForegroundApps.rawValue {
            
            print("Interruption began")
            showAlert("Another app is using your camera features.")
            dispatch_async(cameraQueue, { () -> Void in
                
                self.captureSession.stopRunning()
            })
        }
    }
    
    
    internal func continueVideo() {
        
        //If movie player was playing, resume
        if moviePlayer.player != nil && tabBarController?.selectedIndex == 0 {
            
            print("Continuing video")
            if CTCallCenter().currentCalls == nil {
                
                changeAudioSession(AVAudioSessionCategoryPlayAndRecord)
            }
            moviePlayer.player!.play()
        }
    }
    
    
    internal func doBackgroundTasks() {
        
        //If movie player is playing, pause
        if moviePlayer.player != nil && tabBarController?.selectedIndex == 0  {
            
            print("Pause video")
            moviePlayer.player!.pause()
        }
        
        //Turn torch off
        turnTorchOff()
    }
    
    
    internal func changeAudioSession(category: String) {
        
        //If audio session isn't already the new category, change it
        if AVAudioSession.sharedInstance().category != category {
            
            do {
                
                print("Changing session")
                try AVAudioSession.sharedInstance().setCategory(category, withOptions: [AVAudioSessionCategoryOptions.MixWithOthers, AVAudioSessionCategoryOptions.DefaultToSpeaker])
                AVAudioSession.sharedInstance()
                try AVAudioSession.sharedInstance().setActive(true)
            }
            catch let error as NSError { print("Error setting audio session category \(error)") }
        }
    }
    
    
    @IBAction func detectPan(recognizer: UIPanGestureRecognizer) {
        
        
        //Check if view is the Country Background class
        let panningView = recognizer.view!
        let translation = recognizer.translationInView(recognizer.view!.superview)
        
        
        switch recognizer.state {
            
            
        case .Began:
            
            
            //Disable touches in all other views
            cameraImage.userInteractionEnabled = false
            flashButton.userInteractionEnabled = false
            cameraSwitchButton.userInteractionEnabled = false
            
            
        case .Ended:
            
            
            //Enable touches in all other views
            cameraImage.userInteractionEnabled = true
            flashButton.userInteractionEnabled = true
            cameraSwitchButton.userInteractionEnabled = true
            
            //Move country back and bring back elements
            print("Pan ended")
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                
                //Move object first
                panningView.center.x = self.view.center.x
                panningView.transform = CGAffineTransformMakeRotation(0)
                
                }, completion: nil)
            
            
        case .Cancelled:
            
            
            //Enable touches in all other views
            cameraImage.userInteractionEnabled = true
            flashButton.userInteractionEnabled = true
            cameraSwitchButton.userInteractionEnabled = true
            
            //Move country back and bring back elements
            print("Moving country back")
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                
                //Move object first
                panningView.center.x = self.view.center.x
                panningView.transform = CGAffineTransformMakeRotation(0)
                
                }, completion: nil)
            
            
        default:
            
            
            //Move view according to pan. If view passes a certain threshold, show beacons button
            let threshold = CGFloat(50)
            let distance = max(min(translation.x/3, threshold), -threshold)
            panningView.center.x = self.view.center.x + distance
            
        }
    }
    
    
    internal func setGradients() {
        
        
        //Set gradient views
        let topGradientLayer = CAGradientLayer()
        let bottomGradientLayer = CAGradientLayer()
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15).CGColor
        let color2 = UIColor.clearColor().CGColor
        
        topGradientLayer.frame = topGradient.bounds
        bottomGradientLayer.frame = bottomGradient.bounds
        
        topGradientLayer.colors = [color1, color2]
        bottomGradientLayer.colors = [color2, color1]
        
        topGradient.layer.addSublayer(topGradientLayer)
        bottomGradient.layer.addSublayer(bottomGradientLayer)
    }
    
    
    
    
    internal func showTutorialTakeBeaconView() {
        
        
        //Show label if the user default is nil
        print("showTutorialTakeBeaconView")
        if userDefaults.objectForKey("tutorialTakeBeacon") == nil {
            
            let heading = "Take A Beacon!"
            let text = "Capture something cool!\nPress for photo, hold for video"
            
            dispatch_async(dispatch_get_main_queue(), { 
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(200)
                let verticalPoint = self.captureButton.frame.minY
                self.tutorialTakeBeaconView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2, y: verticalPoint - height - 50, width: width, height: height))
                self.tutorialTakeBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialTakeBeaconView)
                self.view.bringSubviewToFront(self.tutorialTakeBeaconView)
            })
        }
    }
    
    
    internal func removeTutorialTakeBeaconView() {
        
        //Remove take beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialTakeBeacon") == nil {
            
            tutorialTakeBeaconView.removeView("tutorialTakeBeacon")
        }
    }
    
    
    internal func showTutorialSendBeaconView() {
        
        
        //Show label if the user default is nil
        print("showTutorialSendBeaconView")
        if userDefaults.objectForKey("tutorialSendBeacon") == nil {
            
            let heading = "Send The Beacon!"
            let text = "You'll get one back from somewhere in the world!"
            
            dispatch_async(dispatch_get_main_queue(), {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(190)
                let verticalPoint = self.captureButton.frame.minY
                self.tutorialSendBeaconView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2, y: verticalPoint - height - 50, width: width, height: height))
                self.tutorialSendBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialSendBeaconView)
                self.view.bringSubviewToFront(self.tutorialSendBeaconView)
                
            })
        }
    }
    
    
    internal func removeTutorialSendBeaconView() {
        
        //Remove send beacon tutorial view if it's active
        if userDefaults.objectForKey("tutorialSendBeacon") == nil {
            
            tutorialSendBeaconView.removeView("tutorialSendBeacon")
        }
    }
    
    
    
    
    internal func userIsBanned() {
        
        //Show alert if user is banned
        let query = PFQuery(className: "users")
        query.whereKey("userID", equalTo: userID)
        query.getFirstObjectInBackgroundWithBlock { (userObject, error) -> Void in
            
            if error != nil {
                
                print("Error getting user banned status: " + error!.description)
            }
            else {
                
                let bannedStatus = userObject!.objectForKey("banned") as! BooleanLiteralType
                
                if bannedStatus {
                    
                    //Alert user about ban, set user as banned & segue to login
                    print("User is banned.")
                    let alert = UIAlertController(title: "You've been banned", message: "Allow us to investigate this issue & check back soon.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            self.segueToLogin()
                        })
                    }))
                    
                    self.userDefaults.setBool(true, forKey: "banned")
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    
                    print("User is not banned!")
                }
            }
        }
    }
    
    
    internal func segueToTable(segueToTop: Bool) {
        
        
        //Remove replying capability
        stopReplying(true)
        
        //Move within tab controller
        self.tabBarController!.tabBar.hidden = false
        self.tabBarController?.selectedIndex = 1
        
        if segueToTop && tabBarController!.selectedViewController!.isViewLoaded() {
            
            let main = tabBarController!.selectedViewController as! MainController
            let userList = main.childViewControllers[0] as! UserListController
            userList.tableView.setContentOffset(CGPointZero, animated: true)
        }
    }
    
    
    internal func segueToLogin() {
        
        
        //Remove replying capability
        stopReplying(true)
        
        //Segue to login screen
        print("Segue-ing")
        performSegueWithIdentifier("CameraToLoginSegue", sender: self)
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "CameraToLoginSegue" && segue.destinationViewController.isViewLoaded() {
            
            let loginController = segue.destinationViewController as! LoginController
            
            //Set buttons on appearance
            loginController.alertButton.alpha = 0
        }
    }
    
    
    internal func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        
        print("Finished recording")
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        
        print("Status bar hiding method - Camera Controller")
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}