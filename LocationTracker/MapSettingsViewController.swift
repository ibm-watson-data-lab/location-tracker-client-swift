//
//  MapboxSettingsViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/15/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class MapSettingsViewController: UITableViewController {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = 2; // Provider, Style
        // Add custom properties for providers here
//        if (AppState.mapProvider == "XXXX") {
//            rows += 1; // YYYY
//        }
        return rows
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "MapSettingsCell"
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellIdentifier);
        if (indexPath.row == 0) {
            cell.textLabel?.text = "Map Provider"
            cell.detailTextLabel?.text = AppState.mapProvider
        }
        else {
            cell.textLabel?.text = "Map Style"
            cell.detailTextLabel?.text = AppState.mapStyleId
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == 0) {
            if (Reachability.isConnectedToNetwork() == false) {
                self.showOfflineMessage();
            }
            else {
                self.performSegueWithIdentifier("ShowMapProviders", sender: self)
            }
        }
        else if (indexPath.row == 1) {
            if (Reachability.isConnectedToNetwork() == false) {
                self.showOfflineMessage();
            }
            else {
                self.performSegueWithIdentifier("ShowMapStyles", sender: self)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "ShowMapStyles") {
            let mapStyleViewController = (segue.destinationViewController as? MapStyleViewController)
            if (mapStyleViewController != nil) {
                if (AppState.mapProvider == "MapKit") {
                    mapStyleViewController?.mapStyleIds = MapKitMapDelegate.mapStyleIds
                }
                else if (AppState.mapProvider == "Mapbox") {
                    mapStyleViewController?.mapStyleIds = MapboxMapDelegate.mapStyleIds
                }
                else if (AppState.mapProvider == "ArcGIS") {
                    mapStyleViewController?.mapStyleIds = ArcGISMapDelegate.mapStyleIds
                }
            }
        }
    }
    
    func showOfflineMessage() {
        let alert = UIAlertController(title:"Offline", message:"This setting cannot be changed while your device is offline.", preferredStyle:UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title:"OK", style:UIAlertActionStyle.Default, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
