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
    var detailsViewController: CommuteDetailsViewController? {
        return nav.topViewController as? CommuteDetailsViewController
    }

    override init() {
        self.commuteStore = UserDefaults.standard
        self.commuteManager = CommuteManager(
            store: commuteStore,
            home: CommuteEndPoint(identifier: "home", entryHours: 16..<21, exitHours: 6..<10, location: Location(latitude: 45.446263, longitude: -122.587414), radius: 50),
            work: CommuteEndPoint(identifier: "work", entryHours: 7..<11, exitHours: 15..<20, location: Location(latitude: 45.520645, longitude: -122.673128), radius: 50)
        )
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.commuteViewController = CommutesViewController()
        self.nav = UINavigationController(rootViewController: commuteViewController)
        self.locationManager = CLLocationManager()

        super.init()

        commuteManager.delegate = self
    }

    func setupLocationManager() {
        Logger.debug("Setting up Location Manager")
        locationManager.delegate = self

        locationManager.activityType = .otherNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 100
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false

        locationManager.requestAlwaysAuthorization()

        for endpoint in [commuteManager.home, commuteManager.work] {
            locationManager.startMonitoring(for: endpoint.region)
        }

        if let _ = commuteManager.activeCommute {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }

    func startUp() {
        window.rootViewController = nav
        window.makeKeyAndVisible()

        setupLocationManager()
        commuteViewController.commutes = commuteManager.fetchCommutes()
        commuteViewController.eventHandler = self
    }
}

extension AppManager: CommuteDelegate {
    func commuteManager(_ manager: CommuteManager, startedCommute: Commute) {
        commuteViewController.commutes = manager.fetchCommutes()
        Logger.debug("Starting location tracking for commute.")
        locationManager.startUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func commuteManager(_ manager: CommuteManager, updatedCommute: Commute) {
        commuteViewController.commutes = manager.fetchCommutes()
        locationManager.startUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func commuteManager(_ manager: CommuteManager, endedCommute: Commute) {
        commuteViewController.commutes = manager.fetchCommutes()
        Logger.debug("Stopping location tracking due to commute end.")
        locationManager.stopUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
}

extension AppManager: CommutesViewControllerEventHandler {
    func commutesViewController(_ vc: CommutesViewController, didSelect commute: Commute) {
        let details = CommuteDetailsViewController(commute: commute)
        nav.pushViewController(details, animated: true)
    }

    func commutesViewController(_ vc: CommutesViewController, didDelete commute: Commute) {
        commuteManager.delete(commute)
        
        commuteViewController.commutes = commuteManager.fetchCommutes()
    }
    
    func startCommute(for vc: CommutesViewController) {
        if commuteManager.activeCommute != nil {
            commuteManager.endCommute(save: true)
        }
        commuteManager.startCommute(from: commuteManager.home.exitWindow.contains(Date()) ? commuteManager.home : commuteManager.work)
    }

    func endCommute(for vc: CommutesViewController) {
        commuteManager.endCommute(save: true)
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
        Logger.debug("Received \(locations.count) locations")
        for location in locations {
            Logger.verbose("   \(location)")
        }
        for location in locations.filter({ $0.horizontalAccuracy < 50 }) {
            commuteManager.processLocation(Location(location: location))
        }
        
        if let detailsCommute = detailsViewController?.commute,
            let updatedCommute = commuteManager.activeCommute,
            detailsCommute.identifier == updatedCommute.identifier,
            detailsCommute.locations.count != updatedCommute.locations.count {
            detailsViewController?.updateCommute(updatedCommute)
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
