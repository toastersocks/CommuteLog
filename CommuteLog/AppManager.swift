//
//  AppManager.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import UIKit

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
        self.commuteManager = CommuteManager(store: commuteStore)
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
        commuteManager.startCommute()
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
