//
//  LocationMonitor.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/16/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit

class LocationMonitor: NSObject, CLLocationManagerDelegate {

    static let instance = LocationMonitor()
    
    var delegates : [LocationMonitorDelegate] = []
    var locationManagerEnabled = false
    var locationManagerDisabledOnError = false
    var locationManagerEnabledFiredSinceDelegate = false
    var locationManager: CLLocationManager?
    var lastLocation: CLLocation?
    var lastLocationTime: Double?
    
    func startIfGrantedByUser() {
        self.initLocationManager(true)
    }
    
    func initLocationManager(silently: Bool) {
        let locationServicesAuthorized = (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse
            || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways);
        let locationServicesEnabled = CLLocationManager.locationServicesEnabled();
        if (silently && (locationServicesEnabled == false || locationServicesAuthorized == false)) {
            return;
        }
        if (locationManager == nil || locationServicesEnabled == false) {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self;
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager?.distanceFilter = AppConstants.minMetersBetweenLocations
            self.locationManager?.pausesLocationUpdatesAutomatically = false
            if (locationServicesAuthorized) {
                if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse) {
                    self.locationManager?.requestWhenInUseAuthorization()
                }
                else {
                    self.locationManager?.requestAlwaysAuthorization()
                }
            }
            else {
                self.locationManager?.requestAlwaysAuthorization()
            }
            // start
            self.startMonitoringLocations()
        }
        //
        let locationManagerEnabled = (self.locationManager != nil)
            && locationServicesEnabled
            && locationServicesAuthorized
            && (self.locationManagerDisabledOnError == false);
        //
        if (locationManagerEnabled != self.locationManagerEnabled) {
            self.locationManagerEnabled = locationManagerEnabled
            if (self.locationManagerEnabled) {
                self.notifyLocationManagerEnabled()
            }
            else {
                self.notifyLocationManagerDisabled()
            }
        }
    }
    
    func addDelegate(delegate:LocationMonitorDelegate) -> (locationManagerEnabled:Bool, lastLocation:CLLocation?) {
        return self.addDelegate(delegate, silently:false);
    }

    func addDelegate(delegate:LocationMonitorDelegate, silently: Bool) -> (locationManagerEnabled:Bool, lastLocation:CLLocation?) {
        // if delegate alread added then return
        for d in self.delegates {
            if ((d as? NSObject) == (delegate as? NSObject)) {
                return (locationManagerEnabled:self.locationManagerEnabled, lastLocation:self.lastLocation);
            }
        }
        self.delegates.append(delegate)
        self.initLocationManager(silently)
        self.locationManagerEnabledFiredSinceDelegate = false;
        if (self.locationManager != nil) {
            self.startMonitoringLocations()
        }
        return (locationManagerEnabled:self.locationManagerEnabled, lastLocation:self.lastLocation);
    }
    
    func removeDelegate(delegate:LocationMonitorDelegate) {
        var match: Int? = nil
        for (index,d) in self.delegates.enumerate() {
            if ((d as? NSObject) == (delegate as? NSObject)) {
                match = index
                break
            }
        }
        if (match != nil) {
            self.delegates.removeAtIndex(match!)
        }
        if (delegates.count == 0 && self.locationManager != nil) {
            // no more delegates subscribed to location
            self.stopMonitoringLocations()
        }
    }

    func removeAllDelegates() {
        self.delegates.removeAll()
        self.stopMonitoringLocations()
    }

    func notifyUpdatedLocation(location:CLLocation, inBackground: Bool) {
        for delegate:LocationMonitorDelegate in self.delegates {
            delegate.locationUpdated(location, inBackground:inBackground)
        }
    }

    func notifyLocationManagerEnabled() {
        for delegate:LocationMonitorDelegate in self.delegates {
            delegate.locationManagerEnabled()
        }
    }
    
    func notifyLocationManagerDisabled() {
        for delegate:LocationMonitorDelegate in self.delegates {
            delegate.locationManagerDisabled()
        }
    }

    func startMonitoringLocations() {
        if (self.locationManager != nil) {
            // reset last location
            self.lastLocation = nil
            self.lastLocationTime = nil
            if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
                // if running in the background then monitor significant location changes only
                // Apple only allows certain types of applications to monitor all locations
                // while running the background (i.e. GPS, Fitness, etc.)
                self.locationManager?.startMonitoringSignificantLocationChanges()
            }
            else {
                self.locationManager?.startUpdatingLocation()
            }
        }
    }
    
    func stopMonitoringLocations() {
        self.locationManager?.stopUpdatingLocation()
    }

    // MARK: CLLocationManagerDelegate members
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if ((self.locationManagerEnabled || self.locationManagerEnabledFiredSinceDelegate == false) && self.lastLocation == nil) {
            self.locationManagerEnabledFiredSinceDelegate = true;
            self.locationManagerEnabled = false;
            self.locationManagerDisabledOnError = true;
            self.notifyLocationManagerDisabled();
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (self.locationManagerEnabled == false || self.locationManagerEnabledFiredSinceDelegate == false) {
            // if we received a location and delegates haven't been notified that
            // the location manager is enabled then we notify them now
            self.locationManagerEnabledFiredSinceDelegate = true
            self.locationManagerEnabled = true
            self.locationManagerDisabledOnError = false
            self.notifyLocationManagerEnabled()
        }
        let newLocation : CLLocation? = locations.last;
        if (newLocation != nil) {
            if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background || UIApplication.sharedApplication().applicationState == UIApplicationState.Inactive) {
                // if we are in the background then just take the first location sent to us
                // this means the significant update service either sent us a message
                // while we were paused (UIApplicationStateInactive)
                // or the app was shutdown (UIApplicationStateBackground)
                if (newLocation?.horizontalAccuracy >= 0 && newLocation?.horizontalAccuracy <= AppConstants.minMetersLocationAccuracyBackground) {
                    self.processLocation(newLocation!, inBackground: true)
                }
            }
            else {
                // app is in the foreground
                if (newLocation?.horizontalAccuracy >= 0 && newLocation?.horizontalAccuracy <= AppConstants.minMetersLocationAccuracy) {
                    // process location if within desired accuracy
                    self.processLocation(newLocation!, inBackground: false)
                }
            }
        }
    }

    func processLocation(location:CLLocation, inBackground:Bool) {
        var process = false
        if (lastLocation == nil) {
            process = true
        }
        else {
            let secondsPassed = (NSDate().timeIntervalSince1970 - lastLocationTime!)
            let distance = location.distanceFromLocation(lastLocation!)
            let minDistance = (inBackground ? AppConstants.minMetersBetweenLocationsBackground : AppConstants.minMetersBetweenLocations)
            if (distance >= minDistance && secondsPassed > AppConstants.minSecondsBetweenLocations) {
                process = true
            }
        }
        if (process) {
            self.lastLocation = location;
            self.lastLocationTime = NSDate().timeIntervalSince1970
            self.notifyUpdatedLocation(self.lastLocation!, inBackground: inBackground);
        }
    }
    
    // MARK: Application State Changes
    
    func applicationPaused() {
        // switch to monitoring significant locations when moved to the background
        if (self.locationManager != nil) {
            self.locationManager?.stopUpdatingLocation();
            self.locationManager?.startMonitoringSignificantLocationChanges()
        }
    }

    func applicationResumed() {
        if (self.locationManager != nil) {
            self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest;
            self.locationManager?.stopMonitoringSignificantLocationChanges();
            self.startMonitoringLocations()
        }
        else if (self.delegates.count > 0) {
            self.initLocationManager(true)
        }
    }

}
