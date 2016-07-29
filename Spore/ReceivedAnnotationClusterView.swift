//
//  FBAnnotationClusterView.swift
//  FBAnnotationClusteringSwift
//
//  Created by Robert Chen on 4/2/15.
//  Copyright (c) 2015 Robert Chen. All rights reserved.
//

import Foundation
import MapKit

public class ReceivedAnnotationClusterView : MKAnnotationView {
    
    var count = 0
    
    var fontSize:CGFloat = 12
    
    var imageName = "receivedClusterSmall"
    var loadExternalImage : Bool = false
    
    var borderWidth:CGFloat = 2
    
    var countLabel:UILabel? = nil
    
    //var option : FBAnnotationClusterViewOptions? = nil
    
    public init(annotation: MKAnnotation?, reuseIdentifier: String?, options: ReceivedAnnotationClusterViewOptions?){
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let cluster:ReceivedAnnotationCluster = annotation as! ReceivedAnnotationCluster
        count = cluster.annotations.count
        
        // change the size of the cluster image based on number of stories
        switch count {
        case 0...9:
            fontSize = 12
            if (options != nil) {
                loadExternalImage=true;
                imageName = (options?.smallClusterImage)!
            }
            else {
                imageName = "receivedClusterSmall"
            }
            borderWidth = 2
            
        case 10...99:
            fontSize = 13
            if (options != nil) {
                loadExternalImage=true;
                imageName = (options?.mediumClusterImage)!
            }
            else {
                imageName = "receivedClusterMedium"
            }
            borderWidth = 2
            
        default:
            fontSize = 14
            if (options != nil) {
                loadExternalImage=true;
                imageName = (options?.largeClusterImage)!
            }
            else {
                imageName = "receivedClusterLarge"
            }
            borderWidth = 2
            
        }
        
        backgroundColor = UIColor.clearColor()
        setupLabel()
        setTheCount(count)
    }
    
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupLabel(){
        countLabel = UILabel(frame: bounds)
        
        if let countLabel = countLabel {
            countLabel.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            countLabel.textAlignment = .Center
            countLabel.backgroundColor = UIColor.clearColor()
            countLabel.textColor = UIColor.whiteColor()
            countLabel.adjustsFontSizeToFitWidth = true
            countLabel.minimumScaleFactor = 2
            countLabel.numberOfLines = 1
            countLabel.font = UIFont.boldSystemFontOfSize(fontSize)
            countLabel.baselineAdjustment = .AlignCenters
            addSubview(countLabel)
        }
        
    }
    
    func setTheCount(localCount:Int){
        count = localCount;
        
        countLabel?.text = "\(localCount)"
        setNeedsLayout()
    }
    
    override public func layoutSubviews() {
        
        // Images are faster than using drawRect:
        
        let imageAsset = UIImage(named: imageName, inBundle: (!loadExternalImage) ? NSBundle(forClass: ReceivedAnnotationClusterView.self) : nil, compatibleWithTraitCollection: nil)
        
        //UIImage(named: imageName)!
        
        countLabel?.frame = self.bounds
        image = imageAsset
        centerOffset = CGPointZero
        
        // adds a white border around the green circle
        layer.borderColor = UIColor.whiteColor().CGColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = self.bounds.size.width / 2
        
    }
    
}

public class ReceivedAnnotationClusterViewOptions : NSObject {
    var smallClusterImage : String
    var mediumClusterImage : String
    var largeClusterImage : String
    
   
    public init (smallClusterImage : String, mediumClusterImage : String, largeClusterImage : String) {
        self.smallClusterImage = smallClusterImage;
        self.mediumClusterImage = mediumClusterImage;
        self.largeClusterImage = largeClusterImage;
    }
    
}