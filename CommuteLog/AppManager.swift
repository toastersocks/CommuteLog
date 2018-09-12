//
//  AppManager.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import UIKit
import CoreLocation

class AppManager: NSObject {
    var commuteStore: CommuteStore
    var commuteManager: CommuteManager
    var locationManager: CLLocationManager
    var window: UIWindow

    var nav: UINavigationController
    var commuteViewController: CommutesViewController

    override init() {
        self.commuteStore = UserDefaults.standard
        self.commuteManager = CommuteManager(
            store: commuteStore,
            endPoints: [
                CommuteEndPoint(identifier: "home", entryHours: 16...21, exitHours: 6...10, location: Location(latitude: 45.446263, longitude: -122.587414), radius: 50),
                CommuteEndPoint(identifier: "work", entryHours: 7...11, exitHours: 15...20, location: Location(latitude: 45.520645, longitude: -122.673128), radius: 50)
            ]
        )
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.commuteViewController = CommutesViewController()
        self.nav = UINavigationController(rootViewController: commuteViewController)
        self.locationManager = CLLocationManager()

        super.init()

        commuteManager.delegate = self
    }

    func setupLocationManager() {
        locationManager.delegate = self

        locationManager.activityType = .other
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 75

        locationManager.requestAlwaysAuthorization()

        for endpoint in commuteManager.endpoints {
            locationManager.startMonitoring(for: endpoint.region)
        }
    }

    func startUp() {
        window.rootViewController = nav
        window.makeKeyAndVisible()

        setupLocationManager()
        commuteViewController.commutes = commuteManager.store.loadCommutes()
        commuteViewController.eventHandler = self
    }
}

extension AppManager: CommuteDelegate {
    func commuteManager(_ manager: CommuteManager, startedCommute: Commute) {
        var commutes = manager.store.loadCommutes()
        if let active = manager.activeCommute {
            commutes.append(active)
        }
        commuteViewController.commutes = commutes
        Logger.debug("Starting location tracking for commute: \(startedCommute)")
        locationManager.startUpdatingLocation()
    }

    func commuteManager(_ manager: CommuteManager, updatedCommute: Commute) {
        var commutes = manager.store.loadCommutes()
        if let active = manager.activeCommute {
            commutes.append(active)
        }
        commuteViewController.commutes = commutes
        locationManager.startUpdatingLocation()
    }

    func commuteManager(_ manager: CommuteManager, endedCommute: Commute) {
        commuteViewController.commutes = manager.store.loadCommutes()
        locationManager.stopUpdatingLocation()
    }
}

extension AppManager: CommutesViewControllerEventHandler {
    func commutesViewController(_ vc: CommutesViewController, didSelect commute: Commute) {
        let details = CommuteDetailsViewController(commute: commute)
        nav.pushViewController(details, animated: true)
    }

    func commutesViewController(_ vc: CommutesViewController, didDelete commute: Commute) {
        if commute.isActive {
            commuteManager.store.removeActiveCommute()
        } else {
            commuteManager.store.delete(commute: commute)
        }
        
        commuteViewController.commutes = commuteManager.store.loadCommutes()
    }
}

extension AppManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.debug("Exited region \(region.identifier)")
        commuteManager.exitedRegion(region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Logger.debug("Entered region \(region.identifier)")
        commuteManager.enteredRegion(region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Logger.debug("Updated \(locations.count) locations")
        for location in locations {
            Logger.verbose("   \(location)")
        }
        for location in locations {
            commuteManager.processLocation(Location(location: location))
        }
    }
}

extension CommuteEndPoint {
    var region: CLCircularRegion {
        let region = CLCircularRegion(center: location.clCoordinate, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}

extension Location {
    var clCoordinate: CLLocationCoordinate2D { return CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
