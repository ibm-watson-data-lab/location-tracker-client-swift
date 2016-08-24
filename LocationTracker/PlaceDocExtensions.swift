//
//  PlaceDocExtensions.swift
//  LocationTracker
//
//  Created by Mark Watson on 8/24/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import Foundation

extension PlaceDoc {

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
    
    func getDocBodyAsDictionary() -> [String:AnyObject] {
        var dict:[String:AnyObject] = [String:AnyObject]();
        dict["type"] = "Feature"
        dict["created_at"] = self.timestamp
        dict["geometry"] = self.geometry!.toDictionary()
        dict["name"] = self.name
        return dict
    }
    
    static func fromRow(row:[String:AnyObject]) -> PlaceDoc? {
        if let body = row["doc"] as? [String:AnyObject] {
            var geometry: [String:AnyObject]? = body["geometry"] as? [String:AnyObject]
            var coordinates: [Double]? = geometry!["coordinates"] as? [Double]
            let latitude: Double = coordinates![1]
            let longitude: Double = coordinates![0]
            let name: String? = body["name"] as? String
            let timestamp: Double? = body["created_at"] as? Double
            return PlaceDoc(docId: body["_id"] as? String, latitude: latitude, longitude: longitude, name: name!, timestamp: NSDate(timeIntervalSince1970: Double(timestamp!)/1000.0))
        }
        else {
            print("Error initializing place from dictionary: \(row)")
            return nil
        }
    }
}
