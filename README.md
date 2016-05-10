# Location Tracker

The Location Tracker app is an iOS app developed in Swift to be used in conjunction with the [Location Tracker Server](https://github.com/ibm-cds-labs/location-tracker-server-nodejs).

## How it works

The Location Tracker app supports offline-first, Cloudant Sync, and is implemented on a database-per-user architecture. When a user registers, a specific database is created for that user and is used to track only that user's locations. In addition, the server configures continuous replication for each user-specific database into a consolidated database where all locations can be queried (location_tracker_all). See the architecture diagram below for more information.

### Architecture Diagram

TBD

## Running with Xcode

Get the project and change into the project directory:

    $ git clone https://github.com/ibm-cds-labs/location-tracker-client-swift.git
    $ cd location-tracker-client-swift

Install the project's dependencies:

    $ pod install


Run the project through [Foreman](https://github.com/ddollar/foreman):

    $ npm start

## Configuring IBM Bluemix

Complete these steps first if you have not already:

1. [Install the Cloud Foundry command line interface.](https://www.ng.bluemix.net/docs/#starters/install_cli.html)
2. Follow the instructions at the above link to connect to Bluemix.
3. Follow the instructions at the above link to log in to Bluemix.

Create a Cloudant service within Bluemix if one has not already been created:

    $ cf create-service cloudantNoSQLDB Shared cloudant-location-tracker-db

## Deploying

To deploy to Bluemix, simply:

    $ cf push

**Note:** You may notice that Bluemix assigns a URL to your app containing a random word. This is defined in the `manifest.yml` file. The `host` key in this file contains the value `cloudant-location-tracker-${random-word}`. The random word is there to ensure that multiple people deploying the Location Tracker application to Bluemix do not run into naming collisions. However, this will cause a new route to be created for your application each time you deploy to Bluemix. To prevent this from happening, replace `${random-word}` with a hard coded (but unique) value.

## Privacy Notice

The Location Tracker sample web application includes code to track deployments to [IBM Bluemix](https://www.bluemix.net/) and other Cloud Foundry platforms. The following information is sent to a [Deployment Tracker](https://github.com/cloudant-labs/deployment-tracker) service on each deployment:

* Application Name (`application_name`)
* Space ID (`space_id`)
* Application Version (`application_version`)
* Application URIs (`application_uris`)

This data is collected from the `VCAP_APPLICATION` environment variable in IBM Bluemix and other Cloud Foundry platforms. This data is used by IBM to track metrics around deployments of sample applications to IBM Bluemix to measure the usefulness of our examples, so that we can continuously improve the content we offer to you. Only deployments of sample applications that include code to ping the Deployment Tracker service will be tracked.

### Disabling Deployment Tracking

Deployment tracking can be disabled by removing `./admin.js track && ` from the `install` script line of the `scripts` section within `package.json`.

## License

Licensed under the [Apache License, Version 2.0](LICENSE.txt).
