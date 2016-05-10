//
//  ArcGISMapDelegate.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/21/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import ArcGIS

class ArcGISMapDelegate: NSObject, MapDelegate, AGSMapViewLayerDelegate {
    
    var mapView: AGSMapView
    var graphicsLayer: AGSGraphicsLayer? = nil
    var polylineGraphics: AGSGraphic? = nil
    var pendingPins: [MapPin] = []
    var pendingPathCoordinates: [CLLocationCoordinate2D]? = nil
    var pendingZoom: (CLLocationCoordinate2D, CLLocationDistance, Bool)? = nil
    
    static var mapLoaded = false
    static let graphicsLayerName = "GraphicsLayer"
    static let basemapLayerName = "BasemapLayer"
    static let mapDefaultStyleId = "Gray"
    static let mapStyleIds = ["Gray","Oceans","NatGeo","Topo","Imagery"]
    static let mapStyleUrls: [String:String] = ["Gray":"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer",
                                                "Oceans":"http://services.arcgisonline.com/ArcGIS/rest/services/Ocean_Basemap/MapServer",
                                                "NatGeo":"http://services.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer",
                                                "Topo":"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer",
                                                "Imagery":"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"]
    init(mapView: AGSMapView) {
        self.mapView = mapView
        super.init()
        for mapLayer in self.mapView.mapLayers {
            if (mapLayer.name == ArcGISMapDelegate.graphicsLayerName) {
                self.graphicsLayer = mapLayer as? AGSGraphicsLayer
                break
            }
        }
        self.mapView.layerDelegate = self;
    }
    
    // MARK: LocationMapViewDelegate Members
    
    func providerId() -> String {
        return "ArcGIS"
    }
    
    func setStyle(styleId:String) {
        if let mapStyleUrl = ArcGISMapDelegate.mapStyleUrls[styleId] {
            self.mapView.removeMapLayerWithName(ArcGISMapDelegate.basemapLayerName)
            let basemapLayer = AGSTiledMapServiceLayer(URL: NSURL(string:mapStyleUrl))
            self.mapView.insertMapLayer(basemapLayer, withName: ArcGISMapDelegate.basemapLayerName, atIndex: 0);
        }
    }
    
    func getPin(coordinate: CLLocationCoordinate2D, title: String, color: UIColor) -> MapPin {
        return ArcGISMapPin(
            coordinate: coordinate,
            title: title,
            color: color
        )
    }
    
    func addPin(pin: MapPin) {
        if (ArcGISMapDelegate.mapLoaded) {
            self.addPinLoaded(pin)
        }
        else {
            self.pendingPins.append(pin)
        }
    }
    
    func removePins(pins: [MapPin]) {
        if (ArcGISMapDelegate.mapLoaded) {
            for pin in pins {
                if let arcgisPin = pin as? ArcGISMapPin {
                    self.graphicsLayer?.removeGraphic(arcgisPin.getGraphicForLayer())
                }
            }
        }
        else {
            for pin in pins {
                var match: Int? = nil
                for (index,pendingPin) in self.pendingPins.enumerate() {
                    if (pendingPin == pin) {
                        match = index
                        break
                    }
                }
                if (match != nil) {
                    pendingPins.removeAtIndex(match!)
                }
            }
        }
    }
    
    func drawPath(coordinates: [CLLocationCoordinate2D]) {
        if (ArcGISMapDelegate.mapLoaded) {
            self.drawPathLoaded(coordinates)
        }
        else {
            self.pendingPathCoordinates = coordinates
        }
    }
    
    func erasePath() {
        if (self.polylineGraphics != nil) {
            if (ArcGISMapDelegate.mapLoaded) {
                self.graphicsLayer?.removeGraphic(self.polylineGraphics)
            }
            self.polylineGraphics = nil
        }
    }
    
    func drawRadius(coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
        
    }
    
    func eraseRadius() {
        
    }
    
    func centerAndZoom(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance, animated: Bool) {
        if (ArcGISMapDelegate.mapLoaded) {
            self.centerAndZoomLoaded(centerCoordinate, radiusMeters: radiusMeters, animated: animated)
        }
        else {
            self.pendingZoom = (centerCoordinate, radiusMeters, animated)
        }
    }
    
    func downloadMap(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
    }
    
    func deleteDownloadedMaps() {
    }
    
    // MARK: ASGMapViewLayerDelegate Members
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        ArcGISMapDelegate.mapLoaded = true
        // show user's current location
        self.mapView.locationDisplay.startDataSource()
        // add graphics layer
        self.mapView.removeMapLayerWithName(ArcGISMapDelegate.graphicsLayerName)
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(graphicsLayer, withName:ArcGISMapDelegate.graphicsLayerName)
        // if there are pending pins then add them
        if (self.pendingPins.count > 0) {
            for pendingPin in self.pendingPins {
                self.addPinLoaded(pendingPin)
            }
            self.pendingPins.removeAll()
        }
        // if path is pending
        if (self.pendingPathCoordinates != nil) {
            self.drawPathLoaded(self.pendingPathCoordinates!)
        }
        // if zoom pending
        if (self.pendingZoom != nil) {
            self.centerAndZoomLoaded(self.pendingZoom!.0, radiusMeters: self.pendingZoom!.1, animated: self.pendingZoom!.2)
            self.pendingZoom = nil
        }
    }
    
    func addPinLoaded(pin: MapPin) {
        if let arcgisPin = pin as? ArcGISMapPin {
            self.graphicsLayer?.addGraphic(arcgisPin.getGraphicForLayer())
        }
    }
    
    func drawPathLoaded(coordinates: [CLLocationCoordinate2D]) {
        // remove polyline if one exists
        if (self.polylineGraphics != nil) {
            self.graphicsLayer?.removeGraphic(self.polylineGraphics)
            self.polylineGraphics = nil
        }
        self.graphicsLayer?.addGraphic(self.getGraphicForPath(coordinates))
    }
    
    func centerAndZoomLoaded(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance, animated: Bool) {
        let centerPoint = AGSPoint(x:centerCoordinate.longitude, y:centerCoordinate.latitude, spatialReference: AGSSpatialReference.wgs84SpatialReference())
        let geometryEngine = AGSGeometryEngine.defaultGeometryEngine()
        let webmercatorPoint = geometryEngine.projectGeometry(centerPoint, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference());
        // TODO: convert radiusMeters to appropriate scale
        self.mapView.zoomToScale(radiusMeters*30, withCenterPoint: webmercatorPoint as! AGSPoint, animated: animated)
    }
    
    func getGraphicForPath(coordinates: [CLLocationCoordinate2D]) -> AGSGraphic! {
        let polylineSymbol = AGSSimpleLineSymbol(color: UIColor.blueColor())
        let polyline = AGSMutablePolyline()
        polyline.addPathToPolyline()
        let geometryEngine = AGSGeometryEngine.defaultGeometryEngine()
        for coordinate in coordinates {
            let markerPoint = AGSPoint(x:coordinate.longitude, y:coordinate.latitude, spatialReference: AGSSpatialReference.wgs84SpatialReference())
            let webmercatorPoint = geometryEngine.projectGeometry(markerPoint, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference());
            polyline.addPointToPath(webmercatorPoint as! AGSPoint)
        }
        self.polylineGraphics = AGSGraphic(geometry: polyline, symbol: polylineSymbol, attributes: nil)
        return self.polylineGraphics
    }
    
}
