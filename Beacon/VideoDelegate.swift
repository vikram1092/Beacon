//
//  VideoDelegate.swift
//  Spore
//
//  Created by Vikram Ramkumar on 2/15/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoDelegate : NSObject, AVCaptureFileOutputRecordingDelegate
{
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("capture output : finish recording to \(outputFileURL)")
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("capture output: started recording to \(fileURL)")
    }
    
}