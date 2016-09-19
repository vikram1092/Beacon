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
    var previewLayer = AVCaptureVideoPreviewLayer()
    var moviePlayer = AVPlayerLayer()
    var focusShape = FocusShape()
    var videoTimer = Timer()
    let cameraQueue = DispatchQueue(label: "", attributes: [])
    let recorderSettings = [AVSampleRateKey : NSNumber(value: Float(44100.0) as Float),
        AVFormatIDKey : NSNumber(value: Int32(kAudioFormatAppleLossless) as Int32),
        AVNumberOfChannelsKey : NSNumber(value: 1 as Int32),
        AVEncoderAudioQualityKey : NSNumber(value: Int32(AVAudioQuality.medium.rawValue) as Int32),
        AVEncoderBitRateKey : NSNumber(value: Int32(320000) as Int32)]
    var flashMode = false
    var frontFlash = UIView()
    var currentBrightness = CGFloat(0)
    
    //File saving variables
    var locManager = CLLocationManager()
    let fileManager = FileManager.default
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let videoPath = NSTemporaryDirectory() + "userVideo.mp4"
    let initialVideoPath = NSTemporaryDirectory() + "initialVideo.mov"
    let initialAudioPath = NSTemporaryDirectory() + "initialAudio.m4a"
    let videoFileExtension = ".mp4"
    let imageFileExtension = ".jpg"
    let compressionGroup = DispatchGroup()
    
    //User variables
    var userLocation = PFGeoPoint(latitude: 0, longitude: 0)
    var userCountry = ""
    var userState = ""
    var userCity = ""
    var userID = ""
    var firstTime = true
    var saveMedia = true
    var beaconSending = false
    let userDefaults = UserDefaults.standard
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
        
        
        DispatchQueue.global(qos: .utility).async { () -> Void in
            
            //Register for interruption notifications
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleCaptureSessionInterruption(_:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.continueVideo), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.doBackgroundTasks), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            
        }
        
        
        //Set gradients
        setGradients()
        
        //Adjust button views
        cameraSwitchButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 20)
        flashButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 10)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 10)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 10, right: 10)
        cameraImage.addSubview(snapTimer)
        captureButton.addSubview(captureShape)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        print("viewWillAppear")
        //Run as normal
        super.viewWillAppear(true)
        
        //Initialize buttons
        closeButton.isHidden = true
        flashButton.isHidden = false
        captureButton.isHidden = false
        cameraSwitchButton.isHidden = false
        backButton.isHidden = false
        
        //Hide alert layers
        closeAlert()
        
        //Hide tab bar
        self.tabBarController!.tabBar.isHidden = true
    }
    
    
    override func viewDidLayoutSubviews() {
        
        //Adjusts camera to the screen after updating view
        print("viewDidLayoutSubviews")

        let bounds = cameraImage.bounds
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewLayer.bounds = bounds
        self.previewLayer.position=CGPoint(x: bounds.midX, y: bounds.midY)
        
        
        //Set parameters for capture shape
        captureShape.frame = captureButton.bounds
        captureShape.initializeViews()
        
        
        //Set parameters for activity indicator
        activityIndicator.initializeView()
        self.activityIndicator.changeColor(UIColor.white.cgColor)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("viewDidAppear")
        //Appear as normal
        super.viewDidAppear(true)
        
        //Call the handler for dealing with possible scenarios
        initializingHandler()
        
        //Get user defaults
        getUserDefaults()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        
        //Hide preview layer
        previewLayer.isHidden = true
        
        //Turn off flash
        turnFlashOff()
        
    }
    
    
    internal func initializingHandler() {
        
        
        print("initializingHandler")
        if userDefaults.object(forKey: "userID") == nil {
            
            //Go back to login screen if no user is logged on
            segueToLogin()
        }
        else if firstTime && captureDevice == nil {
            
            print("Start camera")
            //Set up and start camera session
            cameraQueue.async(execute: { () -> Void in
                
                //Dispatch to high priority queue and monitor from camera queue
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    
                    
                    self.initializeSession()
                    self.initializeView()
                })
            })
            
            //Check if user is banned
            DispatchQueue.global(qos: .utility).async(execute: { () -> Void in
                
                self.userIsBanned()
            })
        }
        else if !firstTime && !captureSession.isRunning && captureDevice != nil {
            
            print("Rerun camera")
            //Start camera session that's already set up in serial queue
            cameraQueue.async(execute: { () -> Void in
                
                //Dispatch to high priority queue and monitor from camera queue
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    
                    self.captureSession.startRunning()
                    self.previewLayer.isHidden = false
                    self.initializeLocationManager()
                })
            })
        }
        else if !firstTime && captureSession.isRunning && captureDevice != nil {
            
            previewLayer.isHidden = false
        }
    }
    
    
    internal func initializeView() {
        
        print("initialViewSetup")
        //Clear video temp files
        clearVideoTempFiles()
        
        //Turn off front flash view
        frontFlash.removeFromSuperview()
    }
    
    
    internal func initializeSession() {
    
        
        print("initialSessionSetup")
        //Check permissions
        if checkAllPermissions() {
            
            //Set up camera session & microphone
            captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let devices = AVCaptureDevice.devices()
            
            // Loop through all the capture devices on this phone
            for device in devices! {
                // Make sure this particular device supports video
                if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                    // Finally check the position and confirm we've got the back camera
                    if((device as AnyObject).position == AVCaptureDevicePosition.back) {
                        
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
            DispatchQueue.main.async(execute: { () -> Void in
                
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
        DispatchQueue.main.async { () -> Void in
            
            print("add camera image")
            if self.firstTime {
                
                print("adding sublayer")
                self.cameraImage.layer.addSublayer(self.previewLayer)
                self.viewDidLayoutSubviews()
                
                self.cameraQueue.async(execute: { () -> Void in
                    
                    self.captureSession.startRunning()
                    
                    DispatchQueue.main.async(execute: { 
                        
                        //Show preview layer now
                        self.previewLayer.isHidden = false
                        
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
        DispatchQueue.main.async { () -> Void in
            
            self.locManager = CLLocationManager.init()
            self.locManager.delegate = self
            
            //Get user location every time view appears
            DispatchQueue.global(qos: .utility).async { () -> Void in
                
                self.getUserLocation()
            }
        }
        
    }
    
    
    internal func initializeCaptureDevice() {
        
        do {
            
            try captureDevice!.lockForConfiguration()
        }
        catch let error as NSError { print("Error locking device: \(error)") }
        
        
        if captureDevice!.isFocusModeSupported(AVCaptureFocusMode.continuousAutoFocus) {
            
            print("Continuous auto focus supported")
            captureDevice!.focusMode = AVCaptureFocusMode.continuousAutoFocus
        }
        
        if captureDevice!.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure){
            
            print("Continuous auto exposure supported")
            captureDevice!.exposureMode = AVCaptureExposureMode.continuousAutoExposure
        }
        if captureDevice!.isLowLightBoostSupported {
            
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
        if userDefaults.object(forKey: "userID") != nil {
            
            userID = userDefaults.object(forKey: "userID") as! String
            print(userID)
        }
        
        if userDefaults.object(forKey: "saveMedia") != nil {
            
            saveMedia = userDefaults.bool(forKey: "saveMedia")
            print(saveMedia)
        }
    }
    
    
    
    
    @IBAction func flashButtonPressed(_ sender: AnyObject) {
        
        
        //Toggle torch mode if user wants flash
        if !flashMode {
            
            //Turn on torch mode
            turnFlashOn()
        }
        else {
            
            //Turn off torch mode
            turnFlashOff()
        }
    }
    
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        
        //Segue back
        segueToTable(false)
    }
    
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        
        
        //Perform only if camera is running and not recording
        if captureSession.isRunning && !movieFileOutput.isRecording {
            
            
            //Dispatch to camera dedicated serial queue
            cameraQueue.async(execute: { () -> Void in
                
                //Dispatch to high priority queue
                DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
                    
                    self.captureSession.stopRunning()
                    
                    //Reconfigure all parameters & stop current session
                    let devices = AVCaptureDevice.devices()
                    let position = self.captureDevice!.position
                    
                    //Remove camera input from session
                    let inputs = self.captureSession.inputs
                    self.captureSession.beginConfiguration()
                    self.captureSession.removeInput(inputs?[0] as! AVCaptureInput)
                    
                    for input in inputs! {
                        
                        let deviceInput = input as! AVCaptureDeviceInput
                        if deviceInput.device.hasMediaType(AVMediaTypeVideo) {
                            
                            self.captureSession.removeInput(deviceInput)
                        }
                    }
                    
                    // Loop through all the capture devices on this phone
                    for device in devices! {
                        // Make sure this particular device supports video
                        if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                            // Finally check the position and confirm we've got the OTHER camera
                            if((device as AnyObject).position == AVCaptureDevicePosition.back && position == AVCaptureDevicePosition.front) {
                                
                                self.captureDevice = device as? AVCaptureDevice
                                
                                //Enable flash
                                DispatchQueue.main.async(execute: { () -> Void in
                                    
                                    
                                    if self.flashIsOn() {
                                        
                                        self.turnFlashOn()
                                    }
                                    else {
                                        
                                        self.turnFlashOff()
                                    }
                                })
                                
                                //Configure device modes
                                self.initializeCaptureDevice()
                                
                                
                                break
                            }
                            else if((device as AnyObject).position == AVCaptureDevicePosition.front && position == AVCaptureDevicePosition.back) {
                                
                                self.captureDevice = device as? AVCaptureDevice
                                
                                //Disable flash
                                DispatchQueue.main.async(execute: { () -> Void in
                                    
                                    if self.flashIsOn() {
                                        
                                        self.turnFlashOn()
                                    }
                                    else {
                                        
                                        self.turnFlashOff()
                                    }
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
    
    
    @IBAction func takePhoto(_ sender: UITapGestureRecognizer) {
        
        
        //Capture image
        if !stillImageOutput.isCapturingStillImage && captureSession.isRunning {
            
            
            //Hide take beacon tutorial view
            removeTutorialTakeBeaconView()
            
            //Flash front device if it's turned on, then take picture
            if flashIsOn() && captureDevice!.position == AVCaptureDevicePosition.front {
            
                frontFlash.alpha = 1
                currentBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 1
                
                //Dispatch photo sending function with delay to make flash work
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    
                    //Call capture function
                    self.captureStillImage()
                })
            }
            else {
                
                //Call capture function
                captureStillImage()
            }
        }
        else if captureShape.sendView.alpha == 1 && !stillImageOutput.isCapturingStillImage && !movieFileOutput.isRecording && !beaconSending {
            
            
            //Hide send beacon tutorial view
            removeTutorialSendBeaconView()
            
            //Send beacon if send button has been activated and a beacon is not currently sending
            sendBeacon()
        }
        print("Pressed!")
    }
    
    
    internal func captureStillImage() {
        
        
        //Take a photo asyncronously and prepare button for sending without flash
        stillImageOutput.captureStillImageAsynchronously(from: self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo)) { (buffer, error) in
            
            if error != nil {
                
                print("Error capturing photo: \(error)")
            }
            else {
                
                //Capture image if no errors in connection occurred
                let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let data_image = UIImage(data: image!)
                self.cameraImage.image = data_image
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //Change elements on screen
                    self.flashButton.isHidden = true
                    self.cameraSwitchButton.isHidden = true
                    self.backButton.isHidden = true
                    self.closeButton.isHidden = false
                    
                    
                    //Turn off front flash if it's turned on
                    if self.flashIsOn() && self.captureDevice!.position == AVCaptureDevicePosition.front {
                        
                        UIScreen.main.brightness = self.currentBrightness
                        self.frontFlash.alpha = 0
                    }
                    
                    //Show send beacon tutorial view and transition to send mode
                    self.showTutorialSendBeaconView()
                    self.captureShape.transitionToSendMode()
                })
            }
        }
    }
    
    
    @IBAction func takeVideo(_ sender: UILongPressGestureRecognizer) {
        
        
        //If capture session is running, take the video
        if captureSession.isRunning {
            
            
            switch sender.state {
                
            case .began:
                
                //Hide tutorial view
                removeTutorialTakeBeaconView()
                
                //Change elements on screen
                self.flashButton.isHidden = true
                self.cameraSwitchButton.isHidden = true
                self.backButton.isHidden = true
                
                //Set path for video
                let videoUrl = URL(fileURLWithPath: initialVideoPath)
                let audioUrl = URL(fileURLWithPath: initialAudioPath)
                
                
                //Flash front device if it's turned on
                if flashIsOn() && captureDevice!.position == AVCaptureDevicePosition.front {
                    
                    frontFlash.alpha = 0.9
                    currentBrightness = UIScreen.main.brightness
                    UIScreen.main.brightness = 1
                }
                
                
                //Set up audio recorder
                do {
                    audioRecorder = try AVAudioRecorder(url: audioUrl, settings: recorderSettings)
                    audioRecorder.delegate = self
                }
                catch let error as NSError { print("Error recoding audio: \(error)")}
                
                //Start recording video and audio
                print("Beginning video recording")
                movieFileOutput.stopRecording()
                audioRecorder.stop()
                movieFileOutput.startRecording(toOutputFileURL: videoUrl, recordingDelegate: VideoDelegate())
                audioRecorder.record()
                
                //Start timer
                videoTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(stopTakingVideo), userInfo: nil, repeats: false)
                
                //Start recording animation
                captureShape.startRecording()
                
                
            case .ended:
                
                
                //Stop video if user stops and timer hasn't fired already
                print("Ended video recording")
                if videoTimer.isValid {
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
        
        
        //Change elements on screen
        self.flashButton.isHidden = true
        self.cameraSwitchButton.isHidden = true
        self.backButton.isHidden = true
        self.closeButton.isHidden = false
        
        
        //Turn off front flash if it's turned on
        if self.flashIsOn() && self.captureDevice!.position == AVCaptureDevicePosition.front {
            
            UIScreen.main.brightness = self.currentBrightness
            self.frontFlash.alpha = 0
        }
        
        //Show send beacon tutorial view and transition to send mode
        self.showTutorialSendBeaconView()
        captureShape.transitionToSendMode()
        
        
        //Merge audio and video files into one file, then play for user
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            
            self.mergeAudio(URL(fileURLWithPath: self.initialAudioPath), moviePathUrl: URL(fileURLWithPath: self.initialVideoPath), savePathUrl: URL(fileURLWithPath: self.videoPath))
        }
    }
    
    
    internal func mergeAudio(_ audioURL: URL, moviePathUrl: URL, savePathUrl: URL) {
        
        
        //Merge available audio and video files into one final video file
        let composition = AVMutableComposition()
        let trackVideo:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        let trackAudio:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        let option = NSDictionary(object: true, forKey: "AVURLAssetPreferPreciseDurationAndTimingKey" as NSCopying)
        let sourceAsset = AVURLAsset(url: moviePathUrl, options: option as? [String : AnyObject])
        let audioAsset = AVURLAsset(url: audioURL, options: option as? [String : AnyObject])
        
        
        //Default composition turns the video into landscape orientation. This returns the video into portrait orientation
        trackVideo.preferredTransform = CGAffineTransform(rotationAngle: 90.0 * CGFloat(M_PI) / 180.0)
        
        let tracks = sourceAsset.tracks(withMediaType: AVMediaTypeVideo)
        let audios = audioAsset.tracks(withMediaType: AVMediaTypeAudio)
        
        if tracks.count > 0 && audios.count > 0 {
            
            //If audio exists, combine audio and video
            print("Audio & video")
            let assetTrack:AVAssetTrack = tracks[0] as AVAssetTrack
            let assetTrackAudio:AVAssetTrack = audios[0] as AVAssetTrack
            let audioDuration:CMTime = assetTrackAudio.timeRange.duration
            
            do {
                
                try trackVideo.insertTimeRange(CMTimeRangeMake(kCMTimeZero,audioDuration), of: assetTrack, at: kCMTimeZero)
                try trackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero,audioDuration), of: assetTrackAudio, at: kCMTimeZero)
                
                let assetExport: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)!
                assetExport.outputFileType = AVFileTypeQuickTimeMovie
                assetExport.outputURL = savePathUrl
                assetExport.shouldOptimizeForNetworkUse = true
                
                //Export to file and play it for the user
                assetExport.exportAsynchronously(completionHandler: {
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        //Start movie player
                        self.initializeMoviePlayer()
                    })
                })
            }
            catch let error as NSError { print("Error inserting time range: \(error)") }
            
        }
        else if fileManager.fileExists(atPath: initialVideoPath) {
            
            
            //If video exists but audio doesn't, copy file to final location
            do {
                
                try fileManager.copyItem(atPath: initialVideoPath, toPath: videoPath)
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    //Start movie player
                    self.initializeMoviePlayer()
                })
            }
            catch let error as NSError { print("Error copying file: \(error)") }
        }
    }
    
    
    internal func initializeMoviePlayer() {
        
        
        //Check close button to avoid a simultaneous button press glitch
        if !closeButton.isHidden {
            
            //Initialize movie layer
            print("initializeMoviePlayer")
            let player = AVPlayer(url: URL(fileURLWithPath: videoPath))
            moviePlayer = AVPlayerLayer(player: player)
            
            //Set frame and video gravity
            moviePlayer.frame = self.view.bounds
            moviePlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            //Change audio session if user is in a call
            if CTCallCenter().currentCalls != nil {
                
                changeAudioSession(AVAudioSessionCategoryAmbient)
            }
            
            //Set loop function
            NotificationCenter.default.addObserver(self,
                selector: #selector(restartVideoFromBeginning),
                name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: moviePlayer.player!.currentItem)
            
            //Add layer to view and bring timer to front
            cameraImage.layer.addSublayer(moviePlayer)
            cameraImage.bringSubview(toFront: snapTimer)
            
            //Play video
            moviePlayer.player!.play()
            
            //Start timer
            snapTimer.startTimer(player.currentItem!.asset.duration)
        }
    }

    
    internal func flashIsOn() -> Bool {
        
        return flashMode
    }
    
    
    internal func turnFlashOff() {
        
        //Turn off flash if its on
        flashMode = false
        flashButton.setImage(UIImage(named: "FlashButtonOff"), for: UIControlState())
        
        if captureDevice != nil {
            
            if captureDevice!.hasTorch {
                
                //Lock device for configuration
                do {
                    try captureDevice!.lockForConfiguration()
                } catch let error as NSError {print("Error getting lock for device \(error)")}
                
                if captureDevice!.torchMode == AVCaptureTorchMode.on {
                    
                    //Turn off torch mode and unlock device
                    captureDevice!.torchMode = AVCaptureTorchMode.off
                    captureDevice!.unlockForConfiguration()
                }
            }
            else if captureDevice!.position == AVCaptureDevicePosition.front && frontFlash.superview != nil {
                
                //Remove front flash and restore brightness
                UIScreen.main.brightness = currentBrightness
                frontFlash.removeFromSuperview()
                
            }
        }
    }
    
    
    internal func turnFlashOn() {
        
        //Turn on flash if its off
        flashMode = true
        flashButton.setImage(UIImage(named: "FlashButtonOn"), for: UIControlState())
        
        if captureDevice != nil {
            
            if captureDevice!.hasTorch {
                
                //Lock device for configuration
                do {
                    try captureDevice!.lockForConfiguration()
                } catch let error as NSError {print("Error getting lock for device \(error)")}
                
                if captureDevice!.torchMode == AVCaptureTorchMode.off {
                    
                    //Turn on torch mode and unlock device
                    captureDevice!.torchMode = AVCaptureTorchMode.on
                    captureDevice!.unlockForConfiguration()
                }
            }
            else if captureDevice!.position == AVCaptureDevicePosition.front {
                
                //Initialize front flash, add it when photo or video is taken
                frontFlash = UIView(frame: self.view.bounds)
                frontFlash.backgroundColor = UIColor.white
                frontFlash.isUserInteractionEnabled = false
                frontFlash.alpha = 0
                self.view.addSubview(frontFlash)
                
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
            moviePlayer.player!.seek(to: seekTime)
            
            //Bring timer to front
            cameraImage.bringSubview(toFront: snapTimer)
            
            //Play movie
            moviePlayer.player!.play()
            
            //Reset timer
            snapTimer.startTimer(moviePlayer.player!.currentItem!.asset.duration)
        }
    }
    
    
    @IBAction func closePhoto(_ sender: AnyObject) {
        
        
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
        self.closeButton.isHidden = true
        self.flashButton.isHidden = false
        self.cameraSwitchButton.isHidden = false
        self.backButton.isHidden = false
        self.cameraImage.image = nil
        
        //Turn on flash if it's already set to on
        if flashIsOn() {
            
            turnFlashOn()
        }
        
        //Remove send beacon tutorial
        self.removeTutorialSendBeaconView()
    }
    
    
    
    
    internal func clearVideoTempFiles() {
        
        do {
            
            if fileManager.fileExists(atPath: videoPath) {
                try fileManager.removeItem(atPath: videoPath)
            }
            
            if fileManager.fileExists(atPath: initialVideoPath) {
                try fileManager.removeItem(atPath: initialVideoPath)
            }
            
            if fileManager.fileExists(atPath: initialAudioPath) {
                try fileManager.removeItem(atPath: initialAudioPath)
            }
        }
        catch let error as NSError {
            
            print("Error deleting video: \(error)")
        }
    }
    
    
    internal func updateUserPhotos() {
    
        let userToReceivePhotos = userDefaults.integer(forKey: "userToReceivePhotos") + 1
        userDefaults.set(userToReceivePhotos, forKey: "userToReceivePhotos")
        print("Saved userToReceivePhotos")
    }
    
    
    internal func sendBeacon() {
    
  
        //Kick off activity indicator & hide button
        activityIndicator.startAnimating()
        beaconSending = true
        
        if userCountry == "" {
            
            getUserLocation()
            
            cameraQueue.async(execute: { () -> Void in
                
                self.saveBeaconToList()
            })
        }
        else {
            
            cameraQueue.async(execute: { () -> Void in
                
                self.saveBeaconToList()
            })
        }
    }
    
    
    internal func saveBeaconToList() {
        
        
        let photoObject = PFObject(className:"photo")
        
        //Set date and sender
        let date = Date()
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
        if fileManager.fileExists(atPath: videoPath) {
            

            //Save video to local library
            if saveMedia {
                saveVideoLocally()
            }
            
            //Declare compressed video path and save it
            var compressedVideoPathSuffix = "/compressedVideo_" + String(arc4random_uniform(100000)) + videoFileExtension
            
            while fileManager.fileExists(atPath: documentsDirectory + compressedVideoPathSuffix) {
                compressedVideoPathSuffix = "/compressedVideo_" + String(arc4random_uniform(100000)) + videoFileExtension
            }
            
            photoObject["filePath"] = compressedVideoPathSuffix
            let compressedVideoPath = documentsDirectory + compressedVideoPathSuffix
            
            
            compressionGroup.enter()
            
            //Compress video just taken by user as PFFile
            self.compressVideoFile(URL(fileURLWithPath: self.videoPath), outputURL: URL(fileURLWithPath: compressedVideoPath), handler: { (session) -> Void in
                
                print("Reached completion of compression")
                if session.status == AVAssetExportSessionStatus.completed
                { }
                else if session.error != nil
                {
                    print("Error compressing video: \(session.error)")
                }
                
                self.compressionGroup.leave()
            })
            
            //Wait until dispatch group is finished, then proceed
            let _ = compressionGroup.wait(timeout: DispatchTime.distantFuture)
            
            
            if fileManager.fileExists(atPath: compressedVideoPath) {
                
                photoObject["isVideo"] = true
                
                do {
                    
                    var fileSize : UInt64
                    let attr:NSDictionary? = try FileManager.default.attributesOfItem(atPath: compressedVideoPath) as NSDictionary?
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
            
            while fileManager.fileExists(atPath: documentsDirectory + imagePathSuffix) {
                imagePathSuffix = "/image_" + String(arc4random_uniform(100000)) + imageFileExtension
            }
            
            photoObject["filePath"] = imagePathSuffix
            let imagePath = documentsDirectory + imagePathSuffix
            let imageData = UIImageJPEGRepresentation(self.cameraImage.image!, CGFloat(0.6))
            try? imageData!.write(to: URL(fileURLWithPath: imagePath), options: [.atomic])
            
            photoObject["isVideo"] = false
            
            //Save image to local library
            if saveMedia {
                UIImageWriteToSavedPhotosAlbum(cameraImage.image!, self, nil, nil)
            }
        }
        
        //Save photo object locally
        photoObject.pinInBackground { (pinned, error) -> Void in
            
            if error != nil {
                
                print("Error pinning object: \(error)")
            }
            else {
                
                //Segue back to table
                DispatchQueue.main.async(execute: { () -> Void in
                    
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
        DispatchQueue.global(qos: .utility).async(execute: { () -> Void in
            
            PHPhotoLibrary.shared().performChanges({
                
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: self.videoPath))
                
                }, completionHandler: { success, error in
                    if !success { print("Failed to create video: \(error!)") }
            })
        })
    }
    
    
    internal func compressVideoFile(_ inputURL: URL, outputURL: URL, handler:@escaping (_ session: AVAssetExportSession)-> Void)
    {
        
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset960x540)
        
        exportSession!.outputURL = outputURL
        exportSession!.outputFileType = AVFileTypeMPEG4
        exportSession!.shouldOptimizeForNetworkUse = true
        
        exportSession!.exportAsynchronously { () -> Void in
            
            handler(exportSession!)
        }
    }
    
    
    
    
    @IBAction func cameraTapped(_ sender: UITapGestureRecognizer) {
        
        if captureSession.isRunning && alertView.isHidden {
            
            //Configure variables
            let touchPoint = sender.location(in: sender.view)
            let focusPointx = touchPoint.x/sender.view!.bounds.width
            let focusPointy = touchPoint.y/sender.view!.bounds.height
            let focusPoint = CGPoint(x: focusPointx, y: focusPointy)
            
            //Draw focus shape
            print("Focusing")
            drawFocus(touchPoint)
            
            //Focus camera
            DispatchQueue.global(qos: .utility).async(execute: { () -> Void in
                
                self.focusCamera(focusPoint)
            })
        }
    }
    
    
    @IBAction func cameraZoomed(_ recognizer: UIPinchGestureRecognizer) {
        
        
        let velocityDivider = CGFloat(15.0)
        
        if captureSession.isRunning {
            
            do {
                
                try captureDevice!.lockForConfiguration()
                let zoomDistance = captureDevice!.videoZoomFactor + CGFloat(atan2f(Float(recognizer.velocity), Float(velocityDivider)))
                captureDevice!.videoZoomFactor = max(1.0, min(zoomDistance, captureDevice!.activeFormat.videoMaxZoomFactor))
                captureDevice!.unlockForConfiguration()
            }
            catch let error as NSError { print("Error locking device: \(error)") }
        }
    }
    
    
    internal func focusCamera(_ focusPoint: CGPoint) {
        
        
        //Focus camera on point
        do {
            
            print("Locking for shifting focus")
            try captureDevice!.lockForConfiguration()
            
            if captureDevice!.isFocusModeSupported(AVCaptureFocusMode.continuousAutoFocus) {
                
                print("Auto focus supported")
                captureDevice!.focusPointOfInterest = focusPoint
                captureDevice!.focusMode = AVCaptureFocusMode.continuousAutoFocus
            }
            
            if captureDevice!.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) {
                
                print("Auto exposure supported")
                captureDevice!.exposurePointOfInterest = focusPoint
                captureDevice!.exposureMode = AVCaptureExposureMode.continuousAutoExposure
            }
            
            if captureDevice!.isWhiteBalanceModeSupported(AVCaptureWhiteBalanceMode.continuousAutoWhiteBalance) {
                
                print("Auto white balance supported")
                captureDevice!.whiteBalanceMode = AVCaptureWhiteBalanceMode.continuousAutoWhiteBalance
            }
            
            captureDevice!.unlockForConfiguration()
            
        }
        catch let error as NSError { print("Error locking device for focus: \(error)") }
    }
    
    
    internal func drawFocus(_ touchPoint: CGPoint) {
        
        focusShape.removeFromSuperview()
        focusShape = FocusShape(drawPoint: touchPoint)
        cameraImage.addSubview(focusShape)
    }
    
    
    
    
    internal func replyMode(_ object: PFObject, user: String, replyImage: UIImage) {
        
        
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
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        
        //Initialize image
        imageView.image = replyImage
        imageView.tintColor = UIColor.white
        
        //Initialize blur view
        blurView.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
        blurView.tag = 1
        
        //Initialize close button
        let center = CGPoint(x: cancelReplyButton.bounds.width/2, y: viewHeight/2)
        let closeLayer1 = CAShapeLayer()
        let closeLayer2 = CAShapeLayer()
        let path1 = UIBezierPath()
        let path2 = UIBezierPath()
        let path3 = UIBezierPath()
        let length  = CGFloat(5)
        
        path1.move(to: CGPoint(x: center.x - length, y: center.y - length))
        path1.addLine(to: CGPoint(x: center.x + length, y: center.y + length))
        
        path2.move(to: CGPoint(x: center.x + length, y: center.y - length))
        path2.addLine(to: CGPoint(x: center.x - length, y: center.y + length))
        
        path3.move(to: CGPoint(x: 0, y: 7))
        path3.addLine(to: CGPoint(x: 0, y: viewHeight - 7))
        
        closeLayer1.path = path1.cgPath
        closeLayer1.fillColor = UIColor.clear.cgColor
        closeLayer1.strokeColor = UIColor.white.cgColor
        closeLayer1.lineCap = kCALineCapRound
        
        closeLayer2.path = path2.cgPath
        closeLayer2.fillColor = UIColor.clear.cgColor
        closeLayer2.strokeColor = UIColor.white.cgColor
        closeLayer2.lineCap = kCALineCapRound
        
        cancelReplyButton.layer.addSublayer(closeLayer1)
        cancelReplyButton.layer.addSublayer(closeLayer2)
        cancelReplyButton.tag = 2
        cancelReplyButton.isUserInteractionEnabled = true
        
        cancelReplyButton.alpha = 0
        cancelReplyButton.addTarget(self, action: #selector(cancelReplyPressed), for: UIControlEvents.touchUpInside)
        
        showCancelButton.tag = 3
        showCancelButton.addTarget(self, action: #selector(replyViewInitialPressed), for: UIControlEvents.touchUpInside)
        
        
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
        
        UIView.animate(withDuration: 0.4, animations: {
            
            self.replyView.frame = CGRect(x: self.view.center.x - viewWidth/2, y: 10, width: viewWidth, height: viewHeight)
            label.alpha = 1
            imageView.alpha = 1
        }) 
        
        
        //Save object and username for sending beacon
        replyToObject = object
        replyToUser = user
        
    }
    
    
    @IBAction func replyViewInitialPressed(_ sender: AnyObject) {
        
        
        print("replyViewInitialPressed")
        
        if captureSession.isRunning {
            
            //Get cancel buttons
            let originalWidth = replyView.bounds.width
            let cancelReplyButton = replyView.viewWithTag(2)!
            let showCancelButton = replyView.viewWithTag(3)!
            
            //Remove show cancel button and bring cancel button to front
            showCancelButton.removeFromSuperview()
            replyView.bringSubview(toFront: cancelReplyButton)
            
            
            UIView.animate(withDuration: 0.4, animations: {
                
                
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
                
                
            }, completion: { (Bool) in
                
                //Dispatch block after a certain time. Interruption safe!
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    UIView.animate(withDuration: 0.4, animations: {
                        
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
                            self.replyView.bringSubview(toFront: showCancelButton)
                            
                    })
                })
            }) 
        }
    }
    
    
    @IBAction func cancelReplyPressed() {
        
        //Stop replying
        print("cancelReplyPressed")
        stopReplying(true)
    }
    
    
    internal func stopReplying(_ clearDetails: Bool) {
        
        
        //Remove view and clear details if you want to
        if tabBarController?.selectedIndex == 0 {
            
            UIView.animate(withDuration: 0.4, animations: {
                
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
        
        
        let cameraPermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
        
        if cameraPermission == AVAuthorizationStatus.authorized && locationPermission == CLAuthorizationStatus.authorizedWhenInUse && microphonePermission != AVAuthorizationStatus.notDetermined {
            
            print("All permissions are good")
            return true
        }
        
        return false
    }
    
    
    internal func requestPermissions() {
        
        
        //Initialize permissions and check each one
        let cameraPermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        let locationPermission = CLLocationManager.authorizationStatus()
        let microphonePermission = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
        print("requestPermission")
        
        
        //Check camera permission
        if cameraPermission == AVAuthorizationStatus.notDetermined {
            
            
            //Request access for camera
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (Bool) -> Void in
                
                //Check all permissions after user response
                DispatchQueue.main.async(execute: { () -> Void in
                    
                    if self.checkAllPermissions() {
                        self.initializingHandler()
                    }
                    else { self.requestPermissions() }
                })
            })
        }
        else if cameraPermission == AVAuthorizationStatus.denied || cameraPermission == AVAuthorizationStatus.restricted {
            
            showAlert("Please enable the camera from your settings, you'll need it to use this app.")
        }
        //Check location permission
        else if locationPermission == CLAuthorizationStatus.notDetermined {
            
            //Change delegate to self and request authorization.
            //Refer to override method "didChangeAuthorizationStatus"
            //for similar completion handling when authorization status changes.
            locManager.delegate = self
            locManager.requestWhenInUseAuthorization()
        }
        else if locationPermission == CLAuthorizationStatus.denied || locationPermission == CLAuthorizationStatus.restricted {
            
            showAlert("Please enable locations from your settings, you'll need it to use this app.")
        }
        //Check microphone permission
        else if microphonePermission == AVAuthorizationStatus.notDetermined {
            
            
            //Request access for microphone
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (Bool) -> Void in
                
                DispatchQueue.main.async(execute: { () -> Void in
                    
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
    
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let locValue:CLLocationCoordinate2D = manager.location?.coordinate {
            
            //Gets user location and adds it to the main location variable
            userLocation = PFGeoPoint(latitude: locValue.latitude, longitude: locValue.longitude)
            
            //Stop updating location and get the country code for this location
            locManager.stopUpdatingLocation()
            getPoliticalDetails(userLocation)
            
            //Save user location locally
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.userDefaults.set(self.userLocation.latitude, forKey: "userLatitude")
                self.userDefaults.set(self.userLocation.longitude, forKey: "userLongitude")
            })
        }
    }
    
    
    internal func getPoliticalDetails(_ locGeoPoint: PFGeoPoint) {
        
        
        //Get country for current row
        let location = CLLocation(latitude: locGeoPoint.latitude, longitude: locGeoPoint.longitude)

        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, locationError) -> Void in
            
            if locationError != nil {
                
                print("Reverse geocoder error: \(locationError)")
            }
            else if placemarks!.count > 0 {
                
                //Get and save user's country, state & city
                print("Geo location country code: \(placemarks![0].locality), \(placemarks![0].administrativeArea), \(placemarks![0].isoCountryCode!)")
                self.userCountry = placemarks![0].isoCountryCode!.lowercased()
                
                
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
        DispatchQueue.main.async(execute: { () -> Void in
    
            print("Saving user's country & city")
            self.userDefaults.set(self.userCountry, forKey: "userCountry")
            self.userDefaults.set(self.userState, forKey: "userState")
            self.userDefaults.set(self.userCity, forKey: "userCity")
        })
    }
    
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if !captureSession.isRunning {
            
            print("didChangeAuthorizationStatus: is not running")
            DispatchQueue.main.async(execute: { () -> Void in
                
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
    
    
    
    
    internal func showAlert(_ alertText: String) {
        
        alertView.isHidden = false
        alertButton.setTitle(alertText, for: UIControlState())
        alertButton.titleLabel?.textAlignment = NSTextAlignment.center
    }
    
    
    internal func closeAlert() {
        
        alertView.isHidden = true
    }
    
    
    internal func handleCaptureSessionInterruption(_ notification: Notification) {
        
        
        let userInfo = ((notification as NSNotification).userInfo! as NSDictionary)
        print(userInfo)
        let reason = userInfo.object(forKey: AVCaptureSessionInterruptionReasonKey) as! Int
        
        if reason == AVCaptureSessionInterruptionReason.videoDeviceNotAvailableWithMultipleForegroundApps.rawValue {
            
            print("Interruption began")
            showAlert("Another app is using your camera features.")
            cameraQueue.async(execute: { () -> Void in
                
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
        turnFlashOff()
    }
    
    
    internal func changeAudioSession(_ category: String) {
        
        //If audio session isn't already the new category, change it
        if AVAudioSession.sharedInstance().category != category {
            
            do {
                
                print("Changing session")
                try AVAudioSession.sharedInstance().setCategory(category, with: [AVAudioSessionCategoryOptions.mixWithOthers, AVAudioSessionCategoryOptions.defaultToSpeaker])
                AVAudioSession.sharedInstance()
                try AVAudioSession.sharedInstance().setActive(true)
            }
            catch let error as NSError { print("Error setting audio session category \(error)") }
        }
    }
    
    
    @IBAction func detectPan(_ recognizer: UIPanGestureRecognizer) {
        
        
        //Check if view is the Country Background class
        let panningView = recognizer.view!
        let translation = recognizer.translation(in: recognizer.view!.superview)
        
        
        switch recognizer.state {
            
            
        case .began:
            
            
            //Disable touches in all other views
            cameraImage.isUserInteractionEnabled = false
            flashButton.isUserInteractionEnabled = false
            cameraSwitchButton.isUserInteractionEnabled = false
            
            
        case .ended:
            
            
            //Enable touches in all other views
            cameraImage.isUserInteractionEnabled = true
            flashButton.isUserInteractionEnabled = true
            cameraSwitchButton.isUserInteractionEnabled = true
            
            //Move country back and bring back elements
            print("Pan ended")
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
                
                //Move object first
                panningView.center.x = self.view.center.x
                panningView.transform = CGAffineTransform(rotationAngle: 0)
                
                }, completion: nil)
            
            
        case .cancelled:
            
            
            //Enable touches in all other views
            cameraImage.isUserInteractionEnabled = true
            flashButton.isUserInteractionEnabled = true
            cameraSwitchButton.isUserInteractionEnabled = true
            
            //Move country back and bring back elements
            print("Moving country back")
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: UIViewAnimationOptions.curveLinear, animations: { () -> Void in
                
                //Move object first
                panningView.center.x = self.view.center.x
                panningView.transform = CGAffineTransform(rotationAngle: 0)
                
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
        let color1 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15).cgColor
        let color2 = UIColor.clear.cgColor
        
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
        if userDefaults.object(forKey: "tutorialTakeBeacon") == nil {
            
            let heading = "Take A Beacon!"
            let text = "Capture something cool!\nPress for photo, hold for video"
            
            DispatchQueue.main.async(execute: { 
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(200)
                let verticalPoint = self.captureButton.frame.minY
                self.tutorialTakeBeaconView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2, y: verticalPoint - height - 50, width: width, height: height))
                self.tutorialTakeBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialTakeBeaconView)
                self.view.bringSubview(toFront: self.tutorialTakeBeaconView)
            })
        }
    }
    
    
    internal func removeTutorialTakeBeaconView() {
        
        //Remove take beacon tutorial view if it's active
        if userDefaults.object(forKey: "tutorialTakeBeacon") == nil {
            
            tutorialTakeBeaconView.removeView("tutorialTakeBeacon")
        }
    }
    
    
    internal func showTutorialSendBeaconView() {
        
        
        //Show label if the user default is nil
        print("showTutorialSendBeaconView")
        if userDefaults.object(forKey: "tutorialSendBeacon") == nil {
            
            let heading = "Send The Beacon!"
            let text = "You'll get one back from somewhere in the world!"
            
            DispatchQueue.main.async(execute: {
                
                
                //Set bounds and create tutorial view
                let height = CGFloat(100)
                let width = CGFloat(190)
                let verticalPoint = self.captureButton.frame.minY
                self.tutorialSendBeaconView = TutorialView(frame: CGRect(x: self.view.bounds.width/2 - width/2, y: verticalPoint - height - 50, width: width, height: height))
                self.tutorialSendBeaconView.showText(heading, text: text)
                
                //Add the take beacon view
                self.view.addSubview(self.tutorialSendBeaconView)
                self.view.bringSubview(toFront: self.tutorialSendBeaconView)
                
            })
        }
    }
    
    
    internal func removeTutorialSendBeaconView() {
        
        //Remove send beacon tutorial view if it's active
        if userDefaults.object(forKey: "tutorialSendBeacon") == nil {
            
            tutorialSendBeaconView.removeView("tutorialSendBeacon")
        }
    }
    
    
    
    
    internal func userIsBanned() {
        
        //Show alert if user is banned
        let query = PFQuery(className: "users")
        query.whereKey("userID", equalTo: userID)
        query.getFirstObjectInBackground { (userObject, error) -> Void in
            
            if error != nil {
                
                print("Error getting user banned status: \(error!)")
            }
            else {
                
                let bannedStatus = userObject!.object(forKey: "banned") as! BooleanLiteralType
                
                if bannedStatus {
                    
                    //Alert user about ban, set user as banned & segue to login
                    print("User is banned.")
                    let alert = UIAlertController(title: "You've been banned", message: "Allow us to investigate this issue & check back soon.", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            
                            self.segueToLogin()
                        })
                    }))
                    
                    self.userDefaults.set(true, forKey: "banned")
                    
                    self.present(alert, animated: true, completion: nil)
                }
                else {
                    
                    print("User is not banned!")
                }
            }
        }
    }
    
    
    internal func segueToTable(_ segueToTop: Bool) {
        
        
        //Remove replying capability
        stopReplying(true)
        
        //Move within tab controller
        self.tabBarController!.tabBar.isHidden = false
        self.tabBarController?.selectedIndex = 1
        
        if segueToTop && tabBarController!.selectedViewController!.isViewLoaded {
            
            let main = tabBarController!.selectedViewController as! MainController
            let userList = main.childViewControllers[0] as! UserListController
            userList.tableView.setContentOffset(CGPoint.zero, animated: true)
        }
    }
    
    
    internal func segueToLogin() {
        
        
        //Remove replying capability
        stopReplying(true)
        
        //Segue to login screen
        print("Segue-ing")
        performSegue(withIdentifier: "CameraToLoginSegue", sender: self)
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "CameraToLoginSegue" && segue.destination.isViewLoaded {
            
            let loginController = segue.destination as! LoginController
            
            //Set buttons on appearance
            loginController.alertButton.alpha = 0
        }
    }
    
    
    internal func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        print("Finished recording")
    }
    
    
    override var prefersStatusBarHidden : Bool {
        
        print("Status bar hiding method - Camera Controller")
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
