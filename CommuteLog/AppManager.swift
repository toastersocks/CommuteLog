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
    var locationWrangler: LocationWrangler
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
        self.locationWrangler = LocationWrangler(store: UserDefaults.standard)

        super.init()
        
        locationWrangler.delegate = self
        commuteManager.delegate = self
    }

    func startUp() {
        window.rootViewController = nav
        window.makeKeyAndVisible()

        commuteViewController.commutes = commuteManager.fetchCommutes()
        commuteViewController.eventHandler = self

        if let _ = commuteManager.activeCommute {
            locationWrangler.startTracking()
        }
    }
}

extension AppManager: CommuteDelegate {
    func commuteManager(_ manager: CommuteManager, startedCommute: Commute) {
        commuteViewController.commutes = manager.fetchCommutes()
        Logger.debug("Starting location tracking for commute.")
        locationWrangler.startTracking()
    }

    func commuteManager(_ manager: CommuteManager, endedCommute: Commute) {
        commuteViewController.commutes = manager.fetchCommutes()
        Logger.debug("Stopping location tracking due to commute end.")
        locationWrangler.stopTracking(save: true)
    }
}

extension AppManager: CommutesViewControllerEventHandler {
    func commutesViewController(_ vc: CommutesViewController, didSelect commute: Commute) {
        let details = CommuteDetailsViewController(commute: commute, locationStore: locationWrangler.store)
        details.eventHandler = self
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

extension AppManager: CommuteDetailsViewControllerEventHandler {
    func endCommute(for vc: CommuteDetailsViewController) {
        commuteManager.endCommute(save: true)
        vc.commute.end = Date()
    }
}

extension AppManager: LocationWranglerDelegate {
    func wrangler(_ wrangler: LocationWrangler, didReceiveLocation location: Location) {
        guard let details = detailsViewController, details.commute.isActive, let activeCommute = commuteManager.activeCommute else { return }

        DispatchQueue.main.async {
            details.updateCommute(activeCommute)
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
