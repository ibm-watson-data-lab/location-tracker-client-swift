//
//  MapboxMapDelegate.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/12/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import Mapbox
import MapKit

class MapboxMapDelegate: NSObject, MapDelegate, MGLMapViewDelegate {
    
    var mapView: MGLMapView
    var polyline: MGLPolyline? = nil
    var circle: MGLPolygon? = nil
    var offlinePack: MGLOfflinePack? = nil
    var offlinePackDownloading: Bool = false
    var offlinePackSuspended: Bool = false
    var pendingDownloadCenterCoordinate: CLLocationCoordinate2D? = nil
    var pendingDownloadRadiusMeters: CLLocationDistance? = nil
    
    static let mapDefaultStyleId = "Streets"
    static let mapStyleIds = ["Streets","Light","Dark","Emerald","Basic","Bright","Satellite","Satellite Hybrid"]
    static let mapStyleUrls: [String:String] = ["Default":"mapbox://styles/mapbox/streets-v8",
                                                "Light":"mapbox://styles/mapbox/light-v8",
                                                "Dark":"mapbox://styles/mapbox/dark-v8",
                                                "Emerald":"mapbox://styles/mapbox/emerald-v8",
                                                "Basic":"mapbox://styles/mapbox/basic-v8",
                                                "Bright":"mapbox://styles/mapbox/bright-v8",
                                                "Satellite":"mapbox://styles/mapbox/satellite-v8",
                                                "Satellite Hybrid":"mapbox://styles/mapbox/satellite-hybrid-v8"]
    init(mapView: MGLMapView) {
        self.mapView = mapView
        self.mapView.showsUserLocation = true
        super.init()
        self.mapView.delegate = self;
        // subscribe to offline pack notifications
        MGLOfflineStorage.sharedOfflineStorage().reloadPacks()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(offlinePackProgressDidChange), name: MGLOfflinePackProgressChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(offlinePackDidReceiveError), name: MGLOfflinePackErrorNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: MGLOfflinePackMaximumMapboxTilesReachedNotification, object: nil)
    }
    
    deinit {
        // remove offline pack observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: LocationMapViewDelegate Members
    
    func providerId() -> String {
        return "Mapbox"
    }
    
    func setStyle(styleId: String) {
        if let mapStyleUrl = MapboxMapDelegate.mapStyleUrls[styleId] {
            self.mapView.styleURL = NSURL(string:mapStyleUrl)
        }
    }
    
    func getPin(coordinate: CLLocationCoordinate2D, title: String, color: UIColor) -> MapPin {
        return MapboxMapPin(
            coordinate: coordinate,
            title: title,
            color: color
        )
    }
    
    func addPin(pin: MapPin) {
        self.mapView.addAnnotation(pin as! MapboxMapPin)
    }
    
    func removePins(pins: [MapPin]) {
        self.mapView.removeAnnotations(pins as! [MapboxMapPin])
    }
    
    func drawPath(coordinates: [CLLocationCoordinate2D]) {
        // remove polyline if one exists
        if (self.polyline != nil) {
            self.mapView.removeOverlay(self.polyline!)
        }
        // create and add new polyline
        var mutableCoordinates = coordinates;
        self.polyline = MGLPolyline(coordinates: &mutableCoordinates, count: UInt(coordinates.count))
        self.mapView.addOverlay(self.polyline!)
    }
    
    func erasePath() {
        // remove polyline if one exists
        if (self.polyline != nil) {
            self.mapView.removeOverlay(self.polyline!)
            self.polyline = nil
        }
    }
    
    func drawRadius(coordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
        // remove circle if one exists
        if (self.circle != nil) {
            self.mapView.removeOverlay(self.circle!)
        }
        // create and add new circle
        self.circle = self.polygonCircleForCoordinate(coordinate, radiusMeters: radiusMeters)
        self.mapView.addOverlay(self.circle!)
    }
    
    func eraseRadius() {
        if (self.circle != nil) {
            self.mapView.removeOverlay(self.circle!)
            self.circle = nil
        }
    }
    
    func centerAndZoom(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance, animated: Bool) {
        let region = MKCoordinateRegionMakeWithDistance(centerCoordinate, radiusMeters, radiusMeters)
        let ne = CLLocationCoordinate2D(latitude:centerCoordinate.latitude+region.span.latitudeDelta, longitude:centerCoordinate.longitude+region.span.longitudeDelta)
        let sw = CLLocationCoordinate2D(latitude:centerCoordinate.latitude-region.span.latitudeDelta, longitude:centerCoordinate.longitude-region.span.longitudeDelta);
        self.mapView.setVisibleCoordinateBounds(MGLCoordinateBounds(sw:sw,ne:ne), animated: true);
    }
    
    func downloadMap(centerCoordinate: CLLocationCoordinate2D, radiusMeters: CLLocationDistance) {
        // suspend download of current pack
        // remove all downloaded packs
        // and start over
        if (self.offlinePackDownloading) {
            // suspend the current download
            if (self.offlinePack != nil && self.offlinePackSuspended == false) {
                print("Suspending current pack download.")
                self.offlinePack?.suspend();
                self.offlinePackSuspended = true
            }
            print("Queuing next pack download.")
            pendingDownloadCenterCoordinate = centerCoordinate
            pendingDownloadRadiusMeters = radiusMeters
            return
        }
        else {
            pendingDownloadCenterCoordinate = nil
            pendingDownloadRadiusMeters = nil
        }
        // remove any previously downloaded packs
        self.removeOfflinePacks() {
            print("Starting pack download")
             // get bounds for offline region to be downloaded
            let region = MKCoordinateRegionMakeWithDistance(centerCoordinate, radiusMeters, radiusMeters)
            let ne = CLLocationCoordinate2D(latitude:centerCoordinate.latitude+region.span.latitudeDelta, longitude:centerCoordinate.longitude+region.span.longitudeDelta)
            let sw = CLLocationCoordinate2D(latitude:centerCoordinate.latitude-region.span.latitudeDelta, longitude:centerCoordinate.longitude-region.span.longitudeDelta);
            
            // offline region to be downloaded
            let zoomStart = ceil(self.mapView.zoomLevel)
            let zoomEnd = ceil(self.mapView.zoomLevel)
            let offlineRegion = MGLTilePyramidOfflineRegion(styleURL: self.mapView.styleURL, bounds: MGLCoordinateBounds(sw:sw,ne:ne), fromZoomLevel: zoomStart, toZoomLevel: zoomEnd)
            
            // Store some data for identification purposes alongside the downloaded resources.
            let userInfo = ["name": "Map Offline Pack"]
            let context = NSKeyedArchiver.archivedDataWithRootObject(userInfo)
            
            // Create and register an offline pack with the shared offline storage object.
            MGLOfflineStorage.sharedOfflineStorage().addPackForRegion(offlineRegion, withContext: context) { (pack, error) in
                guard error == nil else {
                    // The pack couldn’t be created for some reason.
                    print("Error: \(error?.localizedFailureReason)")
                    return
                }
                
                // store a refernece to pack (fixes a bug in Mapbox and let's us cancel)
                self.offlinePackDownloading = true
                self.offlinePack = pack
                self.offlinePack!.resume()
            }
        }
    }
    
    func deleteDownloadedMaps() {
        self.removeOfflinePacks {
            // done
        }
    }
    
    // MARK: MGLMapViewDelegate Members
    
    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if (annotation === self.polyline) {
            return 1
        }
        else {
            return 0.15
        }
    }
    
    func mapView(mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 2.0
    }
    
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if (annotation === self.polyline) {
            return UIColor.blueColor()
        }
        else {
            return UIColor.greenColor()
        }
    }
    
    func mapView(mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        if (annotation === self.polyline) {
            return UIColor.blueColor()
        }
        else {
            return UIColor.greenColor()
        }
    }
    
    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let pin = annotation as? MapPin {
            if (pin.color == UIColor.greenColor()) {
                let reuseIdentifier = "PinAnnotationGreen"
                var annotationImage = self.mapView.dequeueReusableAnnotationImageWithIdentifier(reuseIdentifier);
                if (annotationImage == nil) {
                    annotationImage = MGLAnnotationImage(image: UIImage(named: "MapboxPinGreen")!, reuseIdentifier: reuseIdentifier)
                }
                return annotationImage
            }
            else {
                let reuseIdentifier = "PinAnnotationBlue"
                var annotationImage = self.mapView.dequeueReusableAnnotationImageWithIdentifier(reuseIdentifier);
                if (annotationImage == nil) {
                    annotationImage = MGLAnnotationImage(image: UIImage(named: "MapboxPinBlue")!, reuseIdentifier: reuseIdentifier)
                }
                return annotationImage
            }
        }
        else {
            return nil
        }
    }
    
    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // MARK: Download Map Notifications
    
    func downloadPendingOfflinePack() {
        if (pendingDownloadCenterCoordinate != nil && pendingDownloadRadiusMeters != nil) {
            self.downloadMap(pendingDownloadCenterCoordinate!, radiusMeters: pendingDownloadRadiusMeters!)
        }
    }
    
    func removeOfflinePacks(completion: () -> Void) {
        if (MGLOfflineStorage.sharedOfflineStorage().packs != nil) {
            let packCount = MGLOfflineStorage.sharedOfflineStorage().packs!.count
            if (packCount > 0) {
                print("Removing offline pack.")
                let pack:MGLOfflinePack  = MGLOfflineStorage.sharedOfflineStorage().packs![0]
                if (pack == self.offlinePack) {
                    // pack is download - suspend, but don't delete (will crash the app)
                    pack.suspend()
                    completion()
                }
                else {
                    MGLOfflineStorage.sharedOfflineStorage().removePack(pack) { (error) in
                        self.removeOfflinePacks(completion)
                    }
                }
            }
            else {
                print("No offline packs to remove.")
                completion()
            }
        }
    }
    
    func offlinePackProgressDidChange(notification: NSNotification) {
        // Get the offline pack this notification is regarding,
        // and the associated user info for the pack; in this case, `name = My Offline Pack`
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String: String] {
            let progress = pack.progress
            // or notification.userInfo![MGLOfflinePackProgressUserInfoKey]!.MGLOfflinePackProgressValue
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            // Calculate current progress percentage.
            //let progressPercentage = Float(completedResources) / Float(expectedResources)
            
            // If this pack has finished, print its size and resource count.
            if completedResources == expectedResources {
                let byteCount = NSByteCountFormatter.stringFromByteCount(Int64(pack.progress.countOfBytesCompleted), countStyle: NSByteCountFormatterCountStyle.Memory)
                print("Offline pack “\(userInfo["name"])” completed: \(byteCount), \(completedResources) resources")
                self.offlinePackDownloading = false
                self.offlinePackSuspended = false
                self.offlinePack = nil
                self.downloadPendingOfflinePack()
                
            } else {
                // Otherwise, print download/verification progress.
                //print("Offline pack “\(userInfo["name"])” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
            }
        }
    }
    
    func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String: String],
            error = notification.userInfo?[MGLOfflinePackErrorUserInfoKey] as? NSError {
            print("Offline pack “\(userInfo["name"])” received error: \(error.localizedFailureReason)")
        }
        self.offlinePackDownloading = false
        self.offlinePackSuspended = false
        self.offlinePack = nil
        self.downloadPendingOfflinePack()
    }
    
    func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String: String],
            maximumCount = notification.userInfo?[MGLOfflinePackMaximumCountUserInfoKey]?.unsignedLongLongValue {
            print("Offline pack “\(userInfo["name"])” reached limit of \(maximumCount) tiles.")
        }
        self.offlinePackDownloading = false
        self.offlinePackSuspended = false
        self.offlinePack = nil
        self.downloadPendingOfflinePack()
    }
    
    // MARK: Helper Members
    
    func polygonCircleForCoordinate(coordinate:CLLocationCoordinate2D, radiusMeters: CLLocationDistance) -> MGLPolygon{
        let degreesBetweenPoints: Double = 8 //45 sides
        let numberOfPoints: Int = Int(floor(360 / degreesBetweenPoints));
        let distRadians: Double = radiusMeters / 6371000.0
        let centerLatRadians = coordinate.latitude * M_PI / 180;
        let centerLonRadians = coordinate.longitude * M_PI / 180;
        var coordinates: [CLLocationCoordinate2D] = []; //array to hold all the points
        for i in 0 ..< numberOfPoints {
            let degrees: Double = Double(i) * degreesBetweenPoints
            let degreeRadians = degrees * M_PI / 180
            let pointLatRadians = asin( sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians = centerLonRadians + atan2( sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians) )
            let pointLat = pointLatRadians * 180 / M_PI
            let pointLon = pointLonRadians * 180 / M_PI
            let point = CLLocationCoordinate2DMake(pointLat, pointLon);
            coordinates.append(point);
        }
        var mutableCoordinates = coordinates;
        let polygon = MGLPolygon(coordinates: &mutableCoordinates, count: UInt(coordinates.count))
        return polygon;
    }
    
}
