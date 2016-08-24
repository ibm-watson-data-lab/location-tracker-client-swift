//
//  InterfaceController.swift
//  LocationTrackerWatch Extension
//
//  Created by Mark Watson on 8/22/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import Foundation
import WatchKit

class InterfaceController: WKInterfaceController, WatchApplicationContextChangedDelegate {
    
    @IBOutlet var tableView: WKInterfaceTable?
    var context: WatchApplicationContext?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        self.populatePlaces()
        WatchSessionManager.sharedManager.addContextChangedDelegate(self)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func populatePlaces() {
        var places: [String] = []
        if (self.context != nil && self.context?.latestPlaces.count > 0) {
            for place: PlaceDoc in (self.context?.latestPlaces)! {
                places.append(place.name!)
            }
        }
        else {
            places = ["No POIs"]
        }
        self.tableView?.setNumberOfRows(places.count, withRowType: "PlaceTableRowController")
        for (index, value) in places.enumerate() {
            let row = self.tableView?.rowControllerAtIndex(index) as? PlaceTableRowController
            row?.placeLabel?.setText(value)
        }
    }
    
    func contextChanged(context: WatchApplicationContext) {
        self.context = context
        self.populatePlaces()
    }

}
