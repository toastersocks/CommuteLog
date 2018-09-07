//
//  AppManager.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import UIKit

class AppManager {
    var commuteManager: CommuteManager
    var window: UIWindow

    var nav: UINavigationController
    var commuteViewController: CommutesViewController

    init() {
        self.commuteManager = CommuteManager()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.commuteViewController = CommutesViewController()
        self.nav = UINavigationController(rootViewController: commuteViewController)

        commuteManager.delegate = self
    }

    func startUp() {
        window.rootViewController = nav
        window.makeKeyAndVisible()

        commuteManager.startTracking()
        commuteViewController.commutes = commuteManager.store.loadCommutes()
        commuteViewController.eventHandler = self
    }
}

extension AppManager: CommuteDelegate {
    func commuteManager(_ manager: CommuteManager, startedCommute: Commute) {
        commuteViewController.commutes = manager.store.loadCommutes()
    }

    func commuteManager(_ manager: CommuteManager, updatedCommute: Commute) {
        commuteViewController.commutes = manager.store.loadCommutes()
    }

    func commuteManager(_ manager: CommuteManager, endedCommute: Commute) {
        commuteViewController.commutes = manager.store.loadCommutes()
    }
}

extension AppManager: CommutesViewControllerEventHandler {
    func commutesViewController(_ vc: CommutesViewController, didSelect commute: Commute) {
        let details = CommuteDetailsViewController(commute: commute)
        nav.pushViewController(details, animated: true)
    }

    func commutesViewController(_ vc: CommutesViewController, didDelete commute: Commute) {
        commuteManager.store.delete(commute: commute)
        commuteViewController.commutes = commuteManager.store.loadCommutes()
    }
}
