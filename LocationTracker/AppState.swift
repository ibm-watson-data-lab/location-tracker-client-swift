//
//  AppState.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/5/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit
import UIKit

struct AppState {
    
    // MARK: Authentication Info
    
    static var username: String? = nil
    static var password: String? = nil
    static var sessionId: String? = nil
    
    // MARK: Cloudant Connection Info
    
    static var locationDbHost: String? = nil
    static var locationDbName: String? = nil
    static var locationDbApiKey: String? = nil
    static var locationDbApiPassword: String? = nil
    
    static var placeDbName: String? = nil
    static var placeDbApiKey: String? = nil
    static var placeDbApiPassword: String? = nil
    
    // MARK: Map Type
    
    static var mapProvider: String = "MapKit"
    static var mapStyleId: String = "Standard"
}
