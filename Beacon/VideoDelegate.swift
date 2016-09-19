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
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("capture output : finish recording to \(outputFileURL)")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("capture output: started recording to \(fileURL)")
    }
    
}
