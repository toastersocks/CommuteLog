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

    private var schedule: Schedule?

    var locationManager: CLLocationManager

    private var _cachedActiveCommute: Commute?
    var activeCommute: Commute? {
        if _cachedActiveCommute == nil {
            _cachedActiveCommute = store.loadCommutes().values.sorted(by: { $0.start < $1.start }).last(where: { $0.end == nil })
        }
        return _cachedActiveCommute
    }

    init(store: CommuteStore) {
        self.store = store
        self.schedule = store.loadSchedule()
        self.locationManager = CLLocationManager()
        super.init()

        setupLocationManager()
    }

    func setupLocationManager() {
        Logger.debug("Setting up Location Manager")
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

        for region in schedule?.regions ?? [] {
            locationManager.startMonitoring(for: region)
        }
    }

    func enteredRegion(_ identifier: String, at date: Date = Date()) {
        guard let endpoint = schedule?.endpoint(identifier) else {
            Logger.warning("Received region entrance '\(identifier)' before endPoints have been set up.")
            return
        }

        guard endpoint.entryWindow.contains(date) else {
            Logger.debug("Ignoring inactive region.")
            return
        }

        endCommute(save: true)
    }

    func exitedRegion(_ identifier: String, at date: Date = Date()) {
        guard activeCommute == nil else { return }

        guard let endpoint = schedule?.endpoint(identifier), endpoint.exitWindow.contains(date) else {
            Logger.debug("Ignoring inactive region.")
            return
        }

        startCommute()
    }

    func startCommute() {
        guard let startPoint = schedule?.activeStartPoint,
            let endPoint = schedule?.activeEndPoint
            else { return }

        let commute = Commute(start: Date(), from: startPoint, to: endPoint)
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

    func fetchCommutes() -> [Commute] {
        return store.loadCommutes().values.sorted(by: { $0.start < $1.start })
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

extension CommuteManager {
    fileprivate struct Schedule {
        var home: CommuteEndPoint
        var work: CommuteEndPoint

        var regions: [CLRegion] {
            return [home.region, work.region]
        }

        var isActive: Bool { return home.isActive || work.isActive }
        var activeStartPoint: CommuteEndPoint? {
            if home.isActive { return home }
            if work.isActive { return work }
            return nil
        }
        var activeEndPoint: CommuteEndPoint? {
            guard let start = activeStartPoint else { return nil }
            return start.isHome ? work : home
        }

        func endpoint(_ identifier: String) -> CommuteEndPoint? {
            return [home, work].filter({ $0.identifier == identifier }).first
        }
    }
}

extension CommuteStore {
    fileprivate func loadSchedule() -> CommuteManager.Schedule? {
        #warning("TODO: This is using my house and work as a default, just to keep it working until I get the UI added in for modifying it in the app. Once that feature is complete these defaults should be removed.")
        let home = loadHome() ?? CommuteEndPoint(identifier: "home", entryHours: 16..<21, exitHours: 6..<10, location: Location(latitude: 45.446263, longitude: -122.587414), radius: 50, isHome: true)
        let work = loadWork() ?? CommuteEndPoint(identifier: "work", entryHours: 7..<11, exitHours: 15..<20, location: Location(latitude: 45.520645, longitude: -122.673128), radius: 50, isHome: false)
        return CommuteManager.Schedule(home: home, work: work)
    }
}
