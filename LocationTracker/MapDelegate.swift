//
//  LocationMapViewDelegate.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/12/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit

protocol MapDelegate {
    func providerId() -> String
    func setStyle(styleId: String)
    func getPin(coordinate: CLLocationCoordinate2D, title: String, color: UIColor) -> MapPin
    func addPin(pin: MapPin)
    func removePins(pins: [MapPin])
    func drawPath(coordinates: [CLLocationCoordinate2D])
    func erasePath()
    func drawRadius(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance)
    func eraseRadius()
    func centerAndZoom(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance, animated: Bool)
    func downloadMap(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance)
    func deleteDownloadedMaps()
}
