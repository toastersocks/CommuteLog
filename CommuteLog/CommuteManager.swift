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

        startCommute(at: date)
    }

    func startCommute(force: Bool = false, at date: Date = Date()) {
        let startPoint: CommuteEndPoint
        let endPoint: CommuteEndPoint
        if let start = schedule?.activeStartPoint(during: date), let end = schedule?.activeEndPoint(during: date) {
            startPoint = start
            endPoint = end
        } else {
            guard force, let schedule = self.schedule else { return }

            #warning("TODO: This picks the most likely starting point based on the time of day. It _should_ be picking based on location, but that's harder.")
            let hour = Calendar.current.component(.hour, from: date)
            if schedule.home.exitWindow.hours.contains(hour) {
                startPoint = schedule.home
                endPoint = schedule.work
            } else if schedule.work.exitWindow.hours.contains(hour) {
                startPoint = schedule.work
                endPoint = schedule.home
            } else if hour < schedule.home.exitWindow.startHour  {
                startPoint = schedule.home
                endPoint = schedule.work
            } else if hour > schedule.work.exitWindow.endHour {
                startPoint = schedule.work
                endPoint = schedule.home
            } else {
                let homeTimeDiff = abs(schedule.home.exitWindow.distance(from: hour))
                let workTimeDiff = abs(schedule.work.exitWindow.distance(from: hour))
                startPoint = homeTimeDiff <= workTimeDiff ? schedule.home : schedule.work
                endPoint = homeTimeDiff <= workTimeDiff ? schedule.work : schedule.home
            }
        }

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

        func isActive(during date: Date = Date()) -> Bool { return home.isActive (during: date) || work.isActive(during: date) }
        func activeStartPoint(during date: Date = Date()) -> CommuteEndPoint? {
            if home.isActive(during: date) { return home }
            if work.isActive(during: date) { return work }
            return nil
        }
        func activeEndPoint(during date: Date = Date()) -> CommuteEndPoint? {
            guard let start = activeStartPoint(during: date) else { return nil }
            return start.isHome ? work : home
        }

        func endpoint(_ identifier: String) -> CommuteEndPoint? {
            return [home, work].filter({ $0.identifier == identifier }).first
        }
    }
}

extension CommuteStore {
    fileprivate func loadSchedule() -> CommuteManager.Schedule? {
        return CommuteManager.Schedule(home: loadHome(), work: loadWork())
    }
}
