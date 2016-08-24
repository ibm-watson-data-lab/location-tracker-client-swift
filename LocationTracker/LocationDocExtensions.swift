//
//  LocationDocExtensions.swift
//  LocationTracker
//
//  Created by Mark Watson on 8/24/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import Foundation

extension LocationDoc {
    
    convenience init?(aDoc doc:CDTDocumentRevision) {
        if let body = doc.body {
            var geometry: [String:AnyObject]? = body["geometry"] as? [String:AnyObject]
            var coordinates: [Double]? = geometry!["coordinates"] as? [Double]
            let latitude: Double = coordinates![1]
            let longitude: Double = coordinates![0]
            var properties: [String:AnyObject]? = body["properties"] as? [String:AnyObject]
            let username: String? = properties!["username"] as? String
            let sessionId: String? = properties!["session_id"] as? String
            let timestamp: Double? = properties!["timestamp"] as? Double
            let background: Bool? = properties!["background"] as? Bool
            self.init(docId: doc.docId, latitude: latitude, longitude: longitude, username: username!, sessionId: sessionId, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0), background: background)
        }
        else {
            print("Error initializing location from document: \(doc)")
            return nil
        }
    }
    
    func getDocBodyAsDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["type"] = "Feature"
        dict["created_at"] = self.properties["timestamp"]
        dict["geometry"] = self.geometry!.toDictionary()
        dict["properties"] = self.properties
        return dict
    }
}