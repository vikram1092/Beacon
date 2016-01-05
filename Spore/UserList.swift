//
//  UserList.swift
//  Spore
//
//  Created by Vikram Ramkumar on 1/5/16.
//  Copyright © 2016 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse

class UserList: NSObject, NSCoding {
    
    var userList = Array<PFObject>()
    
    required init(coder aDecoder: NSCoder) {
        
        super.init()
        
        let count = aDecoder.decodeIntegerForKey("count")
        
        for var index = 0; index < count; index++ {
            
            let object = PFObject()
            
            //Get time received
            print("Decoding receivedAt")
            object["receivedAt"] = aDecoder.decodeObjectForKey("receivedAt") as! NSDate
            
            //Get country code
            print("Decoding countryCode")
            object["countryCode"] = aDecoder.decodeObjectForKey("countryCode") as! String
            
            //Get photo
            print("Decoding photo")
            let photoImage = aDecoder.decodeObjectForKey("photo") as! UIImage
            object["photo"] = PFFile(data: UIImageJPEGRepresentation(photoImage, CGFloat(1.0))!)
            
            userList.append(object)
        }
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        //Encode count of userList for decoding purposes
        aCoder.encodeInteger(userList.count, forKey: "count")
        
        for index in userList {
            
            //Encode time received at
            print("Encoding receivedAt")
            aCoder.encodeObject(index["receivedAt"], forKey: "receivedAt")
            
            //Encode country code
            print("Encoding countryCode")
            aCoder.encodeObject(index["countryCode"], forKey: "countryCode")
            
            //Encode picture received
            print("Encoding photo")
            aCoder.encodeObject(index["photo"], forKey: "photo")
        }
    }
}