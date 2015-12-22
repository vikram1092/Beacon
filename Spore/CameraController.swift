//
//  CameraController.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/19/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import AVFoundation

class CameraController: UIViewController{
    
    @IBOutlet var cameraImage: UIImageView!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    
    var previewLayer = AVCaptureVideoPreviewLayer?()
    let captureSession = AVCaptureSession()
    var stillImageOutput: AVCaptureStillImageOutput!
    
    //If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        
        //Initialize
        closeButton.hidden = true
        
        //Run view load as normal
        super.viewDidLoad()
        
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
        
        if captureDevice != nil {
            beginSession()
        }
    }
    
    func beginSession() {
        
        
        stillImageOutput = AVCaptureStillImageOutput()
        captureSession.addOutput(self.stillImageOutput)
        
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        }
        catch {
            
            //Doesn't work right now
            print("Camera not found.")
            let alert = UIAlertController(title: "This device does not have a camera.", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
            
            presentViewController(alert, animated: true, completion: nil)
        }
        
        //Create and add the camera layer to Image View
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        //Add layer and run
        cameraImage.layer.addSublayer(self.previewLayer!)
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        
    
        //Adjusts camera to the screen after loading
        let bounds = cameraImage.bounds
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer!.bounds = bounds
        previewLayer!.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
    }
    
    
    @IBAction func takePhoto(sender: AnyObject) {
        
        print("Pressed!")
        
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { (buffer:CMSampleBuffer!, error:NSError!) -> Void in
            let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            let data_image = UIImage(data: image)
            self.captureSession.stopRunning()
            self.cameraImage.image = data_image
            
            //Change buttons on screen
            self.backButton.hidden = true
            self.captureButton.hidden = true
            self.closeButton.hidden = false
        }
    }
    
    @IBAction func closePhoto(sender: AnyObject) {
        
        //Begin camera session again & togggle buttons
        self.captureSession.startRunning()
        self.closeButton.hidden = true
        self.backButton.hidden = false
        self.captureButton.hidden = false
        
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}