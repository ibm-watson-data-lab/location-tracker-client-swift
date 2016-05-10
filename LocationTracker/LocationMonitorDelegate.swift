//
//  LocationMonitorDelegate.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/16/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit

protocol LocationMonitorDelegate {
    func locationUpdated(location:CLLocation, inBackground: Bool)
    func locationManagerEnabled()
    func locationManagerDisabled()
}
