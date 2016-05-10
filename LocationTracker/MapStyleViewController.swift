//
//  MapKitStyleViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/15/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import MapKit
import UIKit

class MapStyleViewController: UITableViewController {
    
    var mapStyleIds: [String]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Map Style"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (mapStyleIds == nil) {
            return 0;
        }
        else {
            return mapStyleIds!.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "MapStyleCell"
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier);
        cell.textLabel?.text = mapStyleIds?[indexPath.row]
        if (AppState.mapStyleId == mapStyleIds?[indexPath.row]) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryType.None;
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        AppState.mapStyleId = mapStyleIds![indexPath.row]
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
