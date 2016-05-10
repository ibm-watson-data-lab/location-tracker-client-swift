//
//  MapProviderViewController.swift
//  LocationTracker
//
//  Created by Mark Watson on 4/15/16.
//  Copyright © 2016 Mark Watson. All rights reserved.
//

import UIKit

class MapProviderViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Map Provider"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppConstants.mapProviders.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "MapProviderCell"
        let cell:UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier);
        cell.textLabel?.text = AppConstants.mapProviders[indexPath.row]
        if (AppState.mapProvider == AppConstants.mapProviders[indexPath.row]) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryType.None;
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (AppState.mapProvider != AppConstants.mapProviders[indexPath.row]) {
            AppState.mapProvider = AppConstants.mapProviders[indexPath.row]
            if let mapStyleId = AppConstants.mapProviderDefaultStyleIds[AppState.mapProvider] {
                AppState.mapStyleId = mapStyleId
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
