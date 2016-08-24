//
//  LocationDocument.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class LocationDoc: NSObject {

    var docId: String?
    var geometry: Geometry?
    var properties: [String:AnyObject] = [String:AnyObject]()
    
    init(docId: String?, latitude: Double, longitude: Double, username: String, sessionId: String?, timestamp: NSDate, background: Bool?) {
        self.docId = docId
        self.geometry = Geometry(latitude: latitude, longitude: longitude)
        self.properties = Dictionary<String,String>()
        self.properties["username"] = username
        self.properties["session_id"] = sessionId
        self.properties["timestamp"] = (NSDate().timeIntervalSince1970 * 1000)
        self.properties["background"] = (background == nil ? false : background)
        //
        super.init()
    }
    
    func toDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["_id"] = self.docId
        dict["created_at"] = self.properties["timestamp"]
        dict["geometry"] = self.geometry!.toDictionary()
        dict["properties"] = self.properties
        return dict
    }
    
    static func fromDictionary(dict:[String:AnyObject]) -> LocationDoc {
        let docId = dict["_id"] as? String
        var geometry = dict["geometry"] as? [String:AnyObject]
        var coordinates = geometry!["coordinates"] as? [Double]
        let latitude = coordinates![1]
        let longitude = coordinates![0]
        var properties = dict["properties"] as? [String:AnyObject]
        let username = properties!["username"] as! String
        let sessionId = properties!["session_id"] as? String
        let timestamp = properties!["timestamp"] as? Double
        let background = properties!["background"] as? Bool
        return LocationDoc(docId: docId, latitude: latitude, longitude: longitude, username: username, sessionId: sessionId, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0), background: background)
    }
    
    
}
