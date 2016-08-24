//
//  MapViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/4/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit

class MapViewController: UIViewController, LocationMonitorDelegate, CDTHTTPInterceptor, CDTReplicatorDelegate {

    @IBOutlet weak var mapView : MKMapView?
    var mapDelegate: MapDelegate?
    var resetZoom = true
    var lastLocationDocMapDownload: LocationDoc? = nil
    var datastoreManager: CDTDatastoreManager?
    let placeDatastoreName: String = "places"
    var placeDatastore: CDTDatastore?
    var placeDocs: [PlaceDoc] = []
    var placePins: [MapPin] = []
    let locationDatastoreName: String = "locations"
    var locationDatastore: CDTDatastore?
    var locationDocs: [LocationDoc] = []
    var locationPins: [MapPin] = []
    var locationReplications = [SyncDirection: CDTReplicator]()
    var locationReplicationsPending : [SyncDirection: Bool] = [.Push:false,.Pull:false]
    var watchApplicationContext: WatchApplicationContext?
    
    // Define two sync directions: push and pull.
    // .Push will copy local data from LocationTracker to Cloudant.
    // .Pull will copy remote data from Cloudant to LocationTracker.
    enum SyncDirection {
        case Push
        case Pull
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize datastore manager
        initDatastoreManager();
        
        // initialize Cloudant Sync local place datastore
        initPlacesDatastore()
        
        // initialize Cloudant Sync local location datastore
        initLocationsDatastore()
        
        // Load all locations from the datastore.
        loadPlaceDocsFromDatastore()
        
        // Load all locations from the datastore.
        loadLocationDocsFromDatastore()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // initialize the map provider (or reset if map type changed in settings)
        initMapProvider();
        
        // Sync locations when we start up
        // This will pull the 100 most recent locations from Cloudant
        syncLocations(.Pull)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // reset the zoom and download offline maps if there are docs
        if (self.locationDocs.count > 0) {
            self.resetZoom = true
            self.resetMapZoom(self.locationDocs.last!);
        }
        
        // subscribe to locations
        LocationMonitor.instance.addDelegate(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        // user logged out
        if (AppState.username == nil) {
            // stop monitoring locations
            LocationMonitor.instance.removeDelegate(self)
            // clear datastores
            do {
                try datastoreManager!.deleteDatastoreNamed(locationDatastoreName)
            }
            catch {
                print("Error deleting datastore: \(error)")
            }
            do {
                try datastoreManager!.deleteDatastoreNamed(placeDatastoreName)
            }
            catch {
                print("Error deleting datastore: \(error)")
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Navigation Item Button Handlers
    
    @IBAction func logoutButtonPressed() {
        UsernamePasswordStore.deleteUsernamePassword()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func settingsButtonPressed() {
        self.performSegueWithIdentifier("ShowMapSettings", sender: self)
    }
    
    // MARK: Map Provider
    
    func initMapProvider() {
        var mapProviderChanged: Bool = false
        if (self.mapDelegate == nil) {
            mapProviderChanged = true
        }
        else {
            mapProviderChanged = (AppState.mapProvider != self.mapDelegate?.providerId())
        }
        if (mapProviderChanged) {
            self.resetZoom = true;
            let previousMapDelegate = (self.mapDelegate != nil)
            if (previousMapDelegate) {
                // if switching from one map delegate to another then
                // delete downloaded maps on the previous delegate
                // and reset lastLocationDocMapDownload to trigger a download
                self.lastLocationDocMapDownload = nil
            }
            if (previousMapDelegate) {
                // if the map provider changed then remove all pins from the previous map provider
                self.removeAllPlacePins()
                self.removeAllLocationPins()
            }
            self.mapDelegate = MapKitMapDelegate(mapView: self.mapView!)
            self.mapView?.hidden = false
            if (previousMapDelegate) {
                // if the map provider changed then add all pins to the new map provider
                self.addAllLocationPins()
                self.addAllPlacePins()
            }
        }
        // set style every time
        self.mapDelegate?.setStyle(AppState.mapStyleId)
    }
    
    func resetMapZoom(lastLocationDoc: LocationDoc) {
        if (self.resetZoom) {
            self.resetZoom = false
            let coordinate: CLLocationCoordinate2D  = CLLocationCoordinate2D(latitude: lastLocationDoc.geometry!.latitude, longitude: lastLocationDoc.geometry!.longitude)
            self.mapDelegate?.centerAndZoom(coordinate, radiusMeters:AppConstants.initialMapZoomRadiusMiles*AppConstants.metersPerMile, animated:true)
        }
    }
    
    // MARK: LocationMonitorDelegate Members
    
    func locationManagerEnabled() {
    }
    
    func locationManagerDisabled() {
    }
    
    func locationUpdated(location:CLLocation, inBackground: Bool) {
        // create location document
        let locationDoc = LocationDoc(docId: nil, latitude: location.coordinate.latitude, longitude:location.coordinate.longitude, username:AppState.username!, sessionId: AppState.sessionId, timestamp: NSDate(), background: inBackground)
        // add location to map
        self.addLocation(locationDoc, drawPath: true, drawRadius: true)
        // reset map zoom
        self.resetMapZoom(locationDoc)
        // save location to datastore
        if (createLocationDoc(locationDoc)) {
            syncLocations(.Push)
        }
        // sync places based on latest location
        self.getPlaces(locationDoc)
    }
    
    // MARK: Map Locations
    
    func addLocation(locationDoc: LocationDoc, drawPath: Bool, drawRadius: Bool) {
        self.locationDocs.append(locationDoc)
        self.addLocationPin(locationDoc, title: "\(self.locationDocs.count)", drawPath: drawPath, drawRadius: drawRadius)
    }
    
    func addLocationPin(locationDoc: LocationDoc, title: String, drawPath: Bool, drawRadius: Bool) {
        if (self.mapDelegate != nil) {
            let pin = self.mapDelegate!.getPin(
                CLLocationCoordinate2DMake(locationDoc.geometry!.latitude, locationDoc.geometry!.longitude),
                title: title,
                color: UIColor.blueColor()
            )
            self.locationPins.append(pin)
            self.mapDelegate!.addPin(pin)
            if (drawPath) {
                self.drawLocationPath()
            }
            if (drawRadius) {
                self.drawLocationRadius(locationDoc)
            }
        }
    }
    
    func addAllLocationPins() {
        for (index,locationDoc) in self.locationDocs.enumerate() {
            self.addLocationPin(locationDoc, title: "\(index+1)" , drawPath: false, drawRadius: false)
        }
        self.drawLocationPath()
    }
    
    func removeAllLocations() {
        self.removeAllLocationPins();
        self.locationDocs.removeAll()
    }
    
    func removeAllLocationPins() {
        self.locationPins.removeAll()
        self.mapDelegate?.eraseRadius()
        self.mapDelegate?.erasePath()
        self.mapDelegate?.removePins(locationPins)
    }
    
    func drawLocationPath() {
        // create an array of coordinates from allPins
        var coordinates: [CLLocationCoordinate2D] = [];
        for pin: MapPin in self.locationPins {
            coordinates.append(pin.coordinate)
        }
        self.mapDelegate?.drawPath(coordinates)
    }
    
    func drawLocationRadius(locationDoc:LocationDoc) {
        self.mapDelegate?.drawRadius(CLLocationCoordinate2DMake(locationDoc.geometry!.latitude, locationDoc.geometry!.longitude), radiusMeters: AppConstants.placeRadiusMeters)
    }
    
    // MARK: Map Places
    
    func addPlace(placeDoc: PlaceDoc) {
        var placeExists = false
        for place in self.placeDocs {
            if (place.docId == placeDoc.docId) {
                placeExists = true
                break
            }
        }
        if (placeExists == false) {
            self.placeDocs.append(placeDoc)
            self.addPlacePin(placeDoc)
        }
    }
    
    func addPlacePin(placeDoc: PlaceDoc) {
        if (self.mapDelegate != nil) {
            let pin = self.mapDelegate!.getPin(
                CLLocationCoordinate2DMake(placeDoc.geometry!.latitude, placeDoc.geometry!.longitude),
                title: placeDoc.name!,
                color: UIColor.greenColor()
            )
            self.placePins.append(pin)
            self.mapDelegate!.addPin(pin)
        }
    }
    
    func addAllPlacePins() {
        for placeDoc: PlaceDoc in self.placeDocs {
            self.addPlacePin(placeDoc)
        }
    }
    
    func removeAllPlaces() {
        self.removeAllPlacePins();
        self.placeDocs.removeAll()
    }
    
    func removeAllPlacePins() {
        self.placePins.removeAll()
        self.mapDelegate?.removePins(self.placePins)
    }
    
    // MARK: Datastore Manager
    
    func initDatastoreManager() {
        let fileManager = NSFileManager.defaultManager()
        let documentsDir = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        let storeURL = documentsDir.URLByAppendingPathComponent("locationtracker")
        let path = storeURL.path
        do {
            datastoreManager = try CDTDatastoreManager(directory: path)
            
        } catch {
            fatalError("Failed to initialize datastore: \(error)")
        }
    }
    
    // MARK: Places Datastore
    
    func initPlacesDatastore() {
        do {
            placeDatastore = try datastoreManager!.datastoreNamed(placeDatastoreName)
            placeDatastore?.ensureIndexed(["created_at"], withName: "timestamps")
            //placeDatastore?.ensureIndexed(["id"], withName: "timestamps")
        }
        catch {
            fatalError("Failed to initialize place datastore: \(error)")
        }
    }
    
    // Create a place. Return true if the place was created, or false if
    // creation was unnecessary.
    func createPlaceDoc(placeDoc: PlaceDoc) -> Bool {
        if let docId = placeDoc.docId {
            do {
                try placeDatastore!.getDocumentWithId(docId)
                print("Skip \(docId) creation: already exists")
                return false
            }
            catch let error as NSError {
                if (error.userInfo["NSLocalizedFailureReason"] as? String
                    != "not_found") {
                    print("Skip \(docId) creation: already deleted by user")
                    return false
                }
            }
        }
        let rev = CDTDocumentRevision(docId: placeDoc.docId)
        rev.body = NSMutableDictionary(dictionary:placeDoc.getDocBodyAsDictionary())
        do {
            try placeDatastore!.createDocumentFromRevision(rev)
        }
        catch {
            print("Error creating place: \(error)")
        }
        return true
    }
    
    func loadPlaceDocsFromDatastore() {
        let query = ["created_at": ["$gt":0]]
        let result = placeDatastore?.find(query, skip: 0, limit: 0, fields:nil, sort: [["created_at":"asc"]])
        //let query = ["id": ["$gt":0]]
        //let result = placeDatastore?.find(query, skip: 0, limit: 100, fields:nil, sort: [["id":"asc"]])
        guard result != nil else {
            print("Failed to query for places")
            return
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.removeAllPlaces()
            result!.enumerateObjectsUsingBlock({ (doc, idx, stop) -> Void in
                if let placeDoc = PlaceDoc(aDoc: doc) {
                    self.addPlace(placeDoc)
                }
            })
        })
    }
    
    func getPlaces(lastLocation: LocationDoc) {
        let url = NSURL(string: "\(AppConstants.baseUrl)/api/places?lat=\(lastLocation.geometry!.latitude)&lon=\(lastLocation.geometry!.longitude)&radius=\(AppConstants.placeRadiusMeters)&relation=contains&nearest=true&include_docs=true")
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url!)
        request.addValue("application/json", forHTTPHeaderField:"Content-Type")
        request.addValue("application/json", forHTTPHeaderField:"Accepts")
        request.HTTPMethod = "GET"
        //
        let task = session.dataTaskWithRequest(request) {
            (let data, let response, let error) in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let _:NSData = data, let _:NSURLResponse = response where error == nil else {
                    // fail silently
                    return
                }
                var dict: NSDictionary!
                do {
                    dict = try NSJSONSerialization.JSONObjectWithData(data!, options:[]) as? NSDictionary
                }
                catch {
                    print(error)
                }
                if (dict != nil) {
                    var latestPlaces: [PlaceDoc] = []
                    if let rows = dict["rows"] as? [[String:AnyObject]] {
                        for row in rows {
                            if let placeDoc = PlaceDoc.fromRow(row) {
                                latestPlaces.append(placeDoc)
                                self.addPlace(placeDoc)
                                self.createPlaceDoc(placeDoc)
                            }
                        }
                    }
                    self.watchApplicationContext = WatchApplicationContext(lastLocation: lastLocation, latestPlaces: latestPlaces)
                    do {
                        try WatchSessionManager.sharedManager.updateWatch(self.watchApplicationContext!)
                    }
                    catch {
                        // TODO:
                    }
                }
            }
        }
        //
        task.resume()
    }
    
    // MARK: Locations Datastore
    
    func initLocationsDatastore() {
        do {
            locationDatastore = try datastoreManager!.datastoreNamed(locationDatastoreName)
            locationDatastore?.ensureIndexed(["created_at"], withName: "timestamps")
        }
        catch {
            fatalError("Failed to initialize location datastore: \(error)")
        }
    }
    
    // Create a location. Return true if the location was created, or false if
    // creation was unnecessary.
    func createLocationDoc(locationDoc: LocationDoc) -> Bool {
        if let docId = locationDoc.docId {
            do {
                try locationDatastore!.getDocumentWithId(docId)
                print("Skip \(docId) creation: already exists")
                return false
            }
            catch let error as NSError {
                if (error.userInfo["NSLocalizedFailureReason"] as? String
                    != "not_found") {
                    print("Skip \(docId) creation: already deleted by user")
                    return false
                }
            }
        }
        let rev = CDTDocumentRevision(docId: locationDoc.docId)
        rev.body = NSMutableDictionary(dictionary:locationDoc.getDocBodyAsDictionary())
        do {
            try locationDatastore!.createDocumentFromRevision(rev)
        }
        catch {
            print("Error creating location: \(error)")
        }
        return true
    }
    
    func loadLocationDocsFromDatastore() {
        let query = ["created_at": ["$gt":0]]
        let result = locationDatastore?.find(query, skip: 0, limit: UInt(AppConstants.locationDisplayCount), fields:nil, sort: [["created_at":"desc"]])
        guard result != nil else {
            print("Failed to query for locations")
            return
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.removeAllLocations()
            // we are loading the documents from most recent to least recent
            // we want our array to be in the oppsite order
            // so we can draw our path and when we add new locations we increment the label
            // here we enumerate the documents and add them to a local array in reverse order
            // then we loop through that local array and add them one by one to the map
            var docs: [CDTDocumentRevision] = []
            result!.enumerateObjectsUsingBlock({ (doc, idx, stop) -> Void in
                docs.insert(doc, atIndex: 0)
            })
            for doc in docs {
                if let locationDoc = LocationDoc(aDoc: doc) {
                    self.addLocation(locationDoc, drawPath: false, drawRadius: false)
                }
            }
            self.drawLocationPath()
        })
    }
    
    // Return an NSURL to the database, with authentication.
    func locationCloudantURL() -> NSURL {
        let credentials = "\(AppState.locationDbApiKey!):\(AppState.locationDbApiPassword!)"
        var hostProtocol = AppState.locationDbHostProtocol;
        if (hostProtocol == nil) {
            hostProtocol = "https"
        }
        let url = "\(hostProtocol!)://\(credentials)@\(AppState.locationDbHost!)/\(AppState.locationDbName!)"
        return NSURL(string: url)!
    }
    
    // Push or pull local data to or from the central cloud.
    func syncLocations(direction: SyncDirection) {
        dispatch_async(dispatch_get_main_queue(), {
            let existingReplication = self.locationReplications[direction]
            guard existingReplication == nil else {
                print("Ignore \(direction) replication; already running")
                self.locationReplicationsPending[direction] = true
                return
            }
            
            let factory = CDTReplicatorFactory(datastoreManager: self.datastoreManager)
            
            let job = (direction == .Push)
                ? CDTPushReplication(source: self.locationDatastore!, target: self.locationCloudantURL())
                : CDTPullReplication(source: self.locationCloudantURL(), target: self.locationDatastore!)
            job.addInterceptor(self)
            
            do {
                // Ready: Create the replication job.
                self.locationReplications[direction] = try factory.oneWay(job)
                
                // Set: Assign myself as the replication delegate.
                self.locationReplications[direction]!.delegate = self
                
                // Go!
                try self.locationReplications[direction]!.start()
            }
            catch {
                print("Error initializing \(direction) sync: \(error)")
                return
            }
            
            print("Started \(direction) sync for locations")
        })
    }
    
    // MARK: Cloudant Sync
    
    // Intercept HTTP requests and set the User-Agent header.
    func interceptRequestInContext(context: CDTHTTPInterceptorContext)
        -> CDTHTTPInterceptorContext {
            let info = NSBundle.mainBundle().infoDictionary!
            let appVer = info["CFBundleShortVersionString"]
            let osVer = NSProcessInfo().operatingSystemVersionString
            let ua = "Location Tracker/\(appVer) (iOS \(osVer)"
            context.request.setValue(ua, forHTTPHeaderField: "User-Agent")
            return context
    }
    
    func replicatorDidChangeState(replicator: CDTReplicator!) {
        // The new state is in replicator.state.
    }
    
    func replicatorDidChangeProgress(replicator: CDTReplicator!) {
        // See replicator.changesProcessed and replicator.changesTotal for progress data.
    }
    
    func replicatorDidComplete(replicator: CDTReplicator!) {
        // if location replicator and pull OR place replicator and pull
        if (replicator == locationReplications[.Pull]) {
            if (replicator.changesProcessed > 0) {
                // Reload the locations, and refresh the UI.
                loadLocationDocsFromDatastore()
            }
        }
        clearReplicator(replicator)
    }
    
    func replicatorDidError(replicator: CDTReplicator!, info:NSError!) {
        print("Replicator error \(replicator) \(info)")
        clearReplicator(replicator)
    }
    
    func clearReplicator(replicator: CDTReplicator!) {
        dispatch_async(dispatch_get_main_queue(), {
            if (replicator == self.locationReplications[.Push] || replicator == self.locationReplications[.Pull]) {
                // Determine the replication direction, given the replicator argument.
                let direction = (replicator == self.locationReplications[.Push])
                    ? SyncDirection.Push
                    : SyncDirection.Pull
                print("Clear location replication: \(direction)")
                self.locationReplications[direction] = nil
                if (self.locationReplicationsPending[direction] == true) {
                    self.locationReplicationsPending[direction] = false
                    self.syncLocations(direction)
                }
            }
        })
    }

}

