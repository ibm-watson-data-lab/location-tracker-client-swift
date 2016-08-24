//
//  WatchSessionManager.swift
//  LocationTracker
//
//  Created by Mark Watson on 8/24/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedManager = WatchSessionManager()

    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil
    
    private var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        if let session = session where session.paired && session.watchAppInstalled {
            return session
        }
        return nil
    }
    
    func startSession() {
        session?.delegate = self
        session?.activateSession()
    }
    
    func updateWatch(context: WatchApplicationContext) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(context.toDictionary())
            }
            catch let error {
                throw error
            }
        }
    }
}
