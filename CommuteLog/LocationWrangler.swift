//
//  LocationWrangler.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/26/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationWranglerDelegate: class {
    func wrangler(_ wrangler: LocationWrangler, didReceiveLocation location: Location)
}
class LocationWrangler: NSObject {
    var store: LocationStore
    var accuracyFilter: Double
    var clLocationManager: CLLocationManager

    weak var delegate: LocationWranglerDelegate?
    private var delegateQueue: DispatchQueue = DispatchQueue(label: "com.aranasaurus.commuteLog.location-delegate", qos: .utility)

    init(store: LocationStore, accuracyFilter: Double = 75) {
        self.store = store
        self.accuracyFilter = accuracyFilter
        self.clLocationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }

    func setupLocationManager() {
        Logger.debug("Setting up Location Manager")

        clLocationManager.activityType = .otherNavigation
        clLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        clLocationManager.distanceFilter = 100
        clLocationManager.showsBackgroundLocationIndicator = true
        clLocationManager.pausesLocationUpdatesAutomatically = false
        clLocationManager.allowsBackgroundLocationUpdates = true

        clLocationManager.requestAlwaysAuthorization()
        clLocationManager.delegate = self
    }

    func startTracking() {
        Logger.debug("Starting Location Tracking")
        clLocationManager.startUpdatingLocation()
    }

    func stopTracking() {
        Logger.debug("Stopping Location Tracking")
        clLocationManager.stopUpdatingLocation()
    }

    func processLocation(_ location: Location) {
        guard location.accuracy <= accuracyFilter else {
            Logger.verbose("Ignoring location due to accuracyFilter \(accuracyFilter).")
            return
        }

        Logger.debug("Storing location \(location).")
        store.save(location)
        delegateQueue.async {
            self.delegate?.wrangler(self, didReceiveLocation: location)
        }
    }
}

extension LocationWrangler: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Logger.debug("Received \(locations.count) locations")
        locations.map(Location.init(location:)).forEach(processLocation(_:))
    }
}

extension Location {
    var clCoordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
