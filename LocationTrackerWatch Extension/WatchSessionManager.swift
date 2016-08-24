//
//  WatchSessionManager.swift
//  LocationTracker
//
//  Created by Mark Watson on 8/24/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import WatchConnectivity

protocol WatchApplicationContextChangedDelegate {
    func contextChanged(context: WatchApplicationContext)
}

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private var contextChangedDelegates = [WatchApplicationContextChangedDelegate]()
    
    private let session: WCSession = WCSession.defaultSession()
    
    func startSession() {
        session.delegate = self
        session.activateSession()
    }
    
    func addContextChangedDelegate<T where T: WatchApplicationContextChangedDelegate, T: Equatable>(delegate: T) {
        contextChangedDelegates.append(delegate)
    }
    
    func removeContextChangedDelegate<T where T: WatchApplicationContextChangedDelegate, T: Equatable>(delegate: T) {
        for (index, indexDelegate) in contextChangedDelegates.enumerate() {
            if let indexDelegate = indexDelegate as? T where indexDelegate == delegate {
                contextChangedDelegates.removeAtIndex(index)
                break
            }
        }
    }
    
    // Receiver
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        print("HI!!!")
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            let context = WatchApplicationContext.fromDictionary(applicationContext)
            self?.contextChangedDelegates.forEach { $0.contextChanged(context)}
        }
        
    }
}