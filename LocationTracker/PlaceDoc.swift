//
//  PlaceDoc.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/6/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class PlaceDoc: NSObject {
    var docId: String?
    var geometry: Geometry?
    var name: String?
    var timestamp: Double?
    
    init?(docId: String?, latitude: Double, longitude: Double, name: String, timestamp: NSDate) {
        self.docId = docId
        self.geometry = Geometry(latitude: latitude, longitude: longitude)
        self.name = name
        self.timestamp = (NSDate().timeIntervalSince1970 * 1000)
        //
        super.init()
    }
    
    func toDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["_id"] = self.docId
        dict["created_at"] = self.timestamp
        dict["geometry"] = self.geometry!.toDictionary()
        dict["name"] = self.name
        return dict
    }
    
    
    static func fromDictionary(dict:[String:AnyObject]) -> PlaceDoc? {
        let docId = dict["_id"] as? String
        var geometry = dict["geometry"] as? [String:AnyObject]
        var coordinates: [Double]? = geometry!["coordinates"] as? [Double]
        let latitude: Double = coordinates![1]
        let longitude: Double = coordinates![0]
        let name: String? = dict["name"] as? String
        let timestamp: Double? = dict["created_at"] as? Double
        return PlaceDoc(docId: dict["_id"] as? String, latitude: latitude, longitude: longitude, name: name!, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0))
    }
    
    
}
