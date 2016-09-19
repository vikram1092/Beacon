//
//  FBAnnotationClusterView.swift
//  FBAnnotationClusteringSwift
//
//  Created by Robert Chen on 4/2/15.
//  Copyright (c) 2015 Robert Chen. All rights reserved.
//

import Foundation
import MapKit

open class ReceivedAnnotationClusterView : MKAnnotationView {
    
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
        
        backgroundColor = UIColor.clear
        setupLabel()
        setTheCount(count)
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupLabel(){
        countLabel = UILabel(frame: bounds)
        
        if let countLabel = countLabel {
            countLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            countLabel.textAlignment = .center
            countLabel.backgroundColor = UIColor.clear
            countLabel.textColor = UIColor.white
            countLabel.adjustsFontSizeToFitWidth = true
            countLabel.minimumScaleFactor = 2
            countLabel.numberOfLines = 1
            countLabel.font = UIFont.boldSystemFont(ofSize: fontSize)
            countLabel.baselineAdjustment = .alignCenters
            addSubview(countLabel)
        }
        
    }
    
    func setTheCount(_ localCount:Int){
        count = localCount;
        
        countLabel?.text = "\(localCount)"
        setNeedsLayout()
    }
    
    override open func layoutSubviews() {
        
        // Images are faster than using drawRect:
        
        let imageAsset = UIImage(named: imageName, in: (!loadExternalImage) ? Bundle(for: ReceivedAnnotationClusterView.self) : nil, compatibleWith: nil)
        
        //UIImage(named: imageName)!
        
        countLabel?.frame = self.bounds
        image = imageAsset
        centerOffset = CGPoint.zero
        
        // adds a white border around the green circle
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = self.bounds.size.width / 2
        
    }
    
}

open class ReceivedAnnotationClusterViewOptions : NSObject {
    var smallClusterImage : String
    var mediumClusterImage : String
    var largeClusterImage : String
    
   
    public init (smallClusterImage : String, mediumClusterImage : String, largeClusterImage : String) {
        self.smallClusterImage = smallClusterImage;
        self.mediumClusterImage = mediumClusterImage;
        self.largeClusterImage = largeClusterImage;
    }
    
}
