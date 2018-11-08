//
//  CommuteManager.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation
import CoreLocation

protocol CommuteDelegate: class {
    func commuteManager(_ manager: CommuteManager, startedCommute: Commute)
    func commuteManager(_ manager: CommuteManager, endedCommute: Commute)
}

class CommuteManager: NSObject {
    private var store: CommuteStore
    weak var delegate: CommuteDelegate?

    var home: CommuteEndPoint
    var work: CommuteEndPoint

    var locationManager: CLLocationManager

    private var _cachedActiveCommute: Commute?
    var activeCommute: Commute? {
        if _cachedActiveCommute == nil {
            _cachedActiveCommute = store.loadCommutes().values.sorted(by: { $0.start < $1.start }).last(where: { $0.end == nil })
        }
        return _cachedActiveCommute
    }

    init(store: CommuteStore, home: CommuteEndPoint, work: CommuteEndPoint) {
        self.store = store
        self.home = home
        self.work = work
        self.locationManager = CLLocationManager()
        super.init()

        setupLocationManager()
    }

    func setupLocationManager() {
        Logger.debug("Setting up Location Manager")
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

        for endpoint in [home, work] {
            locationManager.startMonitoring(for: endpoint.region)
        }
    }

    func enteredRegion(_ identifier: String, at date: Date = Date()) {
        let endpoint = identifier == home.identifier ? home : work
        guard endpoint.entryWindow.contains(date) else {
            Logger.debug("Ignoring inactive region.")
            return
        }

        endCommute(save: true)
    }

    func exitedRegion(_ identifier: String, at date: Date = Date()) {
        guard activeCommute == nil else { return }

        let endpoint = identifier == home.identifier ? home : work
        guard endpoint.exitWindow.contains(date) else {
            Logger.debug("Ignoring inactive region.")
            return
        }

        startCommute(from: endpoint)
    }

    func startCommute(from endpoint: CommuteEndPoint) {
        let commute = Commute(start: Date(), from: endpoint, to: endpoint.identifier == home.identifier ? work : home)
        _cachedActiveCommute = commute
        store.save(commute)
        Logger.debug("Created new Commute and saved as active.")
        delegate?.commuteManager(self, startedCommute: commute)
    }

    func endCommute(save: Bool) {
        guard let commute = activeCommute else { return }
        _cachedActiveCommute = nil

        commute.end = Date()
        if save {
            store.save(commute)
            store.delete(commuteIdentifier: "active")
        }

        delegate?.commuteManager(self, endedCommute: commute)
    }

    @discardableResult
    func delete(_ commute: Commute) -> Bool {
        return store.delete(commute)
    }

    func fetchCommutes(for schedule: CommuteSchedule = CommuteSchedule(hours: 0..<24), ascending: Bool = false) -> [Commute] {
        return store.loadCommutes().values
            .filter({ schedule.contains($0.start) })
            .sorted(by: { ($0.start < $1.start) == ascending })
    }
}

extension CommuteManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.debug("Exited region \(region.identifier)")
        exitedRegion(region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Logger.debug("Entered region \(region.identifier)")
        enteredRegion(region.identifier)
    }
}
