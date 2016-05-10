//
//  Geometry.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class Geometry: NSObject {
    
    var latitude: Double
    var longitude: Double
    
    init?(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        super.init()
    }
    
    func toDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["type"] = "Point"
        dict["coordinates"] = [self.longitude,self.latitude]
        return dict
    }
}
