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
    
    var list = Array<PFObject>()
    
    override init() {
        
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        
        super.init()
        
        let count = aDecoder.decodeIntegerForKey("count")
        
        for var index = 0; index < count; index++ {
            
            let object = PFObject(className: "photo")
            
            //Get time received
            print("Decoding receivedAt")
            print("Decoding countryCode" + String(aDecoder.decodeObjectForKey("receivedAt" + String(index))))
            object["receivedAt"] = aDecoder.decodeObjectForKey("receivedAt" + String(index)) as! NSDate
            
            //Get country code
            print("Decoding countryCode" + String(aDecoder.decodeObjectForKey("countryCode" + String(index))))
            object["countryCode"] = aDecoder.decodeObjectForKey("countryCode" + String(index)) as! String
            
            list.append(object)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                //Get photo
                print("Decoding photo" + String(index))
                let photoImage = aDecoder.decodeObjectForKey("photo" + String(index)) as! UIImage
                self.list[index]["photo"] = PFFile(data: UIImageJPEGRepresentation(photoImage, CGFloat(1.0))!)
            })
        }
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        //Encode count of userList for decoding purposes
        aCoder.encodeInteger(list.count as Int, forKey: "count")
        
        for index in list {
            
            //Encode time received at
            print("Encoding receivedAt" + String(list.indexOf(index)!))
            aCoder.encodeObject(index["receivedAt"] as! NSDate, forKey: "receivedAt" + String(list.indexOf(index)!))
            
            //Encode country code
            print("Encoding countryCode")
            aCoder.encodeObject(index["countryCode"] as! String, forKey: "countryCode" + String(list.indexOf(index)!))
            
            //Encode picture received
            print("Encoding photo")
            let photoFile = index["photo"] as! PFFile
            var photoData = NSData()
            
            do{
                photoData = try photoFile.getData()
            }
            catch _ { print("Error converting photo data")}
            
            aCoder.encodeObject(UIImage(data: photoData), forKey: "photo" + String(list.indexOf(index)!))
        }
    }
    
    func append(object: PFObject) {
        
        list.append(object)
    }
    
    func removeAtIndex(index: Int) {
        
        list.removeAtIndex(index)
    }
}