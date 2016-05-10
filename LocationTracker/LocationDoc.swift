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
        self.properties["timestamp"] = Int(NSDate().timeIntervalSince1970 * 1000)
        self.properties["background"] = (background == nil ? false : background)
        //
        super.init()
    }
    
    required convenience init?(aDoc doc:CDTDocumentRevision) {
        if let body = doc.body {
            var geometry: [String:AnyObject]? = body["geometry"] as? [String:AnyObject]
            var coordinates: [Double]? = geometry!["coordinates"] as? [Double]
            let latitude: Double = coordinates![1]
            let longitude: Double = coordinates![0]
            var properties: [String:AnyObject]? = body["properties"] as? [String:AnyObject]
            let username: String? = properties!["username"] as? String
            let sessionId: String? = properties!["session_id"] as? String
            let timestamp: Int? = properties!["timestamp"] as? Int
            let background: Bool? = properties!["background"] as? Bool
            self.init(docId: doc.docId, latitude: latitude, longitude: longitude, username: username!, sessionId: sessionId, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0), background: background)
        }
        else {
            print("Error initializing location from document: \(doc)")
            return nil
        }
    }
    
    func toDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["type"] = "Feature"
        dict["created_at"] = self.properties["timestamp"]
        dict["geometry"] = self.geometry!.toDictionary()
        dict["properties"] = self.properties
        return dict
    }
}
