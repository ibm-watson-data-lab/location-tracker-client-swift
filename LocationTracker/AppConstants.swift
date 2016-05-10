//
//  AppConstants.swift
//  LocationTracker
//
//  Created by Mark Watson on 5/3/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

class AppConstants: NSObject {

    // MARK: Server Information
    
    //static let baseUrl: String = "http://location-tracker-XXX.mybluemix.net"
    static let baseUrl: String = "http://192.168.1.70:6008"
    
    // MARK: App Settings
    
    static let locationDisplayCount = 100
    static let minMetersLocationAccuracy : Double = 25
    static let minMetersLocationAccuracyBackground : Double = 100
    static let minMetersBeteenLocations : Double = 15
    static let minMetersBeteenLocationsBackground : Double = 100
    static let minSecondsBeteenLocations : Double = 15
    static let initialMapZoomRadiusMiles : Double = 5
    static let offlineMapRadiusMiles: Double = 5
    static let placeRadiusMeters: Double = (2.5 * AppConstants.metersPerMile)
    
    static let metersPerMile = 1609.34
    
    // MARK: Map Providers
    
    static let mapProviders = ["MapKit","Mapbox","ArcGIS"]
    static let mapProviderDefaultStyleIds: [String:String] = ["MapKit":MapKitMapDelegate.mapDefaultStyleId,
                                                              "Mapbox":MapboxMapDelegate.mapDefaultStyleId,
                                                              "ArcGIS":ArcGISMapDelegate.mapDefaultStyleId]
    
}
