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
    
    convenience init?(aDict dict:[String:AnyObject]) {
        if let body = dict["doc"] as? [String:AnyObject] {
            var geometry: [String:AnyObject]? = body["geometry"] as? [String:AnyObject]
            var coordinates: [Double]? = geometry!["coordinates"] as? [Double]
            let latitude: Double = coordinates![1]
            let longitude: Double = coordinates![0]
            let name: String? = body["name"] as? String
            let timestamp: Double? = body["created_at"] as? Double
            self.init(docId: body["_id"] as? String, latitude: latitude, longitude: longitude, name: name!, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0))
        }
        else {
            print("Error initializing place from dictionary: \(dict)")
            return nil
        }
    }
    
    convenience init?(aDoc doc:CDTDocumentRevision) {
        if let body = doc.body {
            var geometry: [String:AnyObject]? = body["geometry"] as? [String:AnyObject]
            var coordinates: [Double]? = geometry!["coordinates"] as? [Double]
            let latitude: Double = coordinates![1]
            let longitude: Double = coordinates![0]
            let name: String? = body["name"] as? String
            let timestamp: Double? = body["created_at"] as? Double
            self.init(docId: doc.docId, latitude: latitude, longitude: longitude, name: name!, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0))
        }
        else {
            print("Error initializing place from document: \(doc)")
            return nil
        }
    }
    
    func toDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["type"] = "Feature"
        dict["created_at"] = self.timestamp
        dict["geometry"] = self.geometry!.toDictionary()
        dict["name"] = self.name
        return dict
    }
}
