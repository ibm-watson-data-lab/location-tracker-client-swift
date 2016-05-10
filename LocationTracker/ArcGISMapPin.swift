//
//  ArcGISMapPin.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/21/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import ArcGIS

class ArcGISMapPin: MapPin {
    
    var graphic : AGSGraphic? = nil
    
    func getGraphicForLayer() -> AGSGraphic! {
        if (self.graphic == nil) {
            // Create the AGSSimpleMarker Symbol and set some properties
            let makerSymbol = AGSSimpleMarkerSymbol()
            makerSymbol.color = self.color;
            makerSymbol.style = AGSSimpleMarkerSymbolStyle.Circle;
            // Create an AGSPoint (which inherits from AGSGeometry) that defines where the Graphic will be drawn
            let markerPoint = AGSPoint(x:self.coordinate.longitude, y:self.coordinate.latitude, spatialReference: AGSSpatialReference.wgs84SpatialReference())
            let geometryEngine = AGSGeometryEngine.defaultGeometryEngine()
            let webmercatorPoint = geometryEngine.projectGeometry(markerPoint, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference());
            self.graphic = AGSGraphic(geometry: webmercatorPoint, symbol: makerSymbol, attributes: nil)
        }
        return self.graphic
    }
    
}
