//
//  PlaceAnnotation.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/6/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit
import UIKit

class MapPin : NSObject     {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var color: UIColor?
    
    init(coordinate: CLLocationCoordinate2D, title: String, color: UIColor) {
        self.coordinate = coordinate
        self.title = title
        self.color = color
    }

}
