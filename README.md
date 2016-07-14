# Location Tracker

The Location Tracker app is an iOS app developed in Swift to be used in conjunction with the [Location Tracker Server](https://github.com/ibm-cds-labs/location-tracker-server-nodejs) or the [Location Tracker Envoy Server](https://github.com/ibm-cds-labs/location-tracker-server-envoy).

## How it works

The Location Tracker app tracks user locations and stores those locations in Cloudant. 

The Location Tracker app supports offline-first, Cloudant Sync, and is implemented on a database-per-user architecture. When a user registers, a specific database is created for that user and is used to track only that user's locations. In addition, the server configures continuous replication for each user-specific database into a consolidated database where all locations can be queried. See the architecture diagram below for more information:

![Architecture of Location Tracker](http://developer.ibm.com/clouddataservices/wp-content/uploads/sites/47/2016/05/locationTracker2ArchDiagram1.png)

When you run the Location Track app for the first time register as a new user:

![Location Tracker App Register](http://developer.ibm.com/clouddataservices/wp-content/uploads/sites/47/2016/05/locationTracker2AppRegister.png)

Once you register, a new database will be created specifically to track locations for that user.

![Location Tracker Cloudant User Location](http://developer.ibm.com/clouddataservices/wp-content/uploads/sites/47/2016/05/locationTracker2CloudantUserLoc.png)

The Location Tracker app tracks users as they move. Blue pins mark each location recorded by the app. A blue line is drawn over the path the user has travelled. Each time the Location Tracker app records a new location a radius-based geo query is performed in Cloudant to find nearby places. The radius is represented by a green circle. Places are displayed as green pins:

![Location Tracker App Map](http://developer.ibm.com/clouddataservices/wp-content/uploads/sites/47/2016/05/locationTracker2AppMap.png)

The Location Tracker app uses [Cloudant Sync for iOS](https://github.com/cloudant/CDTDatastore) to store locations locally and sync them to Cloudant:

 ![Location Tracker Cloudant Map](http://developer.ibm.com/clouddataservices/wp-content/uploads/sites/47/2016/05/locationTracker2CloudantUserLoc3.png)

All locations are stored in a local datastore and synced to the server. The Location Tracker app can operate completely offline (locations can only be tracked if device has clear sight to satellites). Places can only be queried while online, but are stored locally for offline usage.

## Running with Xcode

Make sure you have a [Location Tracker Server](https://github.com/ibm-cds-labs/location-tracker-server-nodejs) or [Location Tracker Envoy Server](https://github.com/ibm-cds-labs/location-tracker-server-envoy) configured and running. 

Clone the project and change into the project directory:

    $ git clone https://github.com/ibm-cds-labs/location-tracker-client-swift.git
    $ cd location-tracker-client-swift

The Location Tracker app uses [Cocoa Pods](https://cocoapods.org/) to manage dependencies. If you don't have Cocoa Pods installed you can install it using gem:

    $ sudo gem install cocoapods

Once you have Cocoa Pods install run the pod command:

    $ pod install

In Xcode open LocationTracker.xcworkspace (note: Be sure to open the workspace and not the xcode project).

Open the AppConstants.swift file in LocationTracker > LocationTracker. Change the baseUrl to point to your Location Tracker Server running on Bluemix or locally:

<pre>
static let baseUrl: String = "http://location-tracker-XXX.mybluemix.net"
</pre>

Click the play button to run the project in the iOS Simulator. Register as a new user as described above, grant the app access to track your location, and configure the debug location to "Freeway Drive":

 ![Location Tracker App Simulator](http://developer.ibm.com/clouddataservices/wp-content/uploads/sites/47/2016/05/locationTracker2AppSimulator.png)

## License

Licensed under the [Apache License, Version 2.0](LICENSE.txt).
