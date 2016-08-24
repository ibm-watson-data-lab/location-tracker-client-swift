//
//  WatchApplicationContext.swift
//  LocationTracker
//
//  Created by Mark Watson on 8/24/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import Foundation

class WatchApplicationContext: NSObject {
    
    var lastLocation: LocationDoc?
    var latestPlaces: [PlaceDoc] = []
    
    override init() {
        super.init()
    }
    
    init(lastLocation: LocationDoc, latestPlaces: [PlaceDoc]) {
        self.lastLocation = lastLocation
        self.latestPlaces = latestPlaces
        super.init()
    }
    
    func toDictionary() -> [String:AnyObject] {
        var latestPlaceDicts : [[String:AnyObject]] = []
        for latestPlace in latestPlaces {
            latestPlaceDicts.append(latestPlace.toDictionary())
        }
        return ["lastLocation":self.lastLocation!.toDictionary(), "latestPlaces": latestPlaceDicts]
    }
    
    static func fromDictionary(dict: [String:AnyObject]) -> WatchApplicationContext {
        let context = WatchApplicationContext()
        context.lastLocation = LocationDoc.fromDictionary(dict["lastLocation"] as! [String:AnyObject])
        context.latestPlaces = []
        for latestPlaceDict: [String:AnyObject] in dict["latestPlaces"] as! [[String:AnyObject]] {
            context.latestPlaces.append(PlaceDoc.fromDictionary(latestPlaceDict)!)
        }
        return context
    }
}
