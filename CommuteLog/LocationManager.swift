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
    func commuteManager(_ manager: CommuteManager, updatedCommute: Commute)
    func commuteManager(_ manager: CommuteManager, endedCommute: Commute)
}

struct CommuteSchedule {
    let hours: ClosedRange<Int>

    func contains(_ date: Date) -> Bool {
        guard !Calendar.current.isDateInWeekend(date) else { return false }
        guard let hour = Calendar.current.dateComponents([.hour], from: date).hour else { return false }
        return hours.contains(hour)
    }
}

class CommuteManager: NSObject {
    var manager: CLLocationManager
    var store: CommuteStore

    weak var delegate: CommuteDelegate?

    var morning: CommuteSchedule = CommuteSchedule(hours: 7...10)
    var isMorning: Bool { return morning.contains(Date()) }
    var evening: CommuteSchedule = CommuteSchedule(hours: 16...20)
    var isEvening: Bool { return evening.contains(Date()) }

    var activeCommute: Commute?

    init(store: CommuteStore = UserDefaults.standard, delegate: CommuteDelegate? = nil) {
        manager = CLLocationManager()
        manager.activityType = .other
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 100
        self.store = store
        self.delegate = delegate

        super.init()

        manager.delegate = self
        activeCommute = loadActiveCommute()
    }

    func startTracking() {
        manager.requestAlwaysAuthorization()

        let home = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 45.4462, longitude: -122.5869), radius: 20, identifier: "home")
        home.notifyOnEntry = true
        home.notifyOnExit = true
        manager.startMonitoring(for: home)

        let work = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 45.5205, longitude: -122.6739), radius: 50, identifier: "work")
        work.notifyOnEntry = true
        work.notifyOnExit = true
        manager.startMonitoring(for: work)

        manager.startMonitoringSignificantLocationChanges()
        manager.startMonitoringVisits()
        
        if let commute = activeCommute, commute.isActive {
            guard isMorning || isEvening else {
                commute.end = Date()
                store.save(commute: commute)
                return
            }

            manager.startUpdatingLocation()
        }
    }

    func loadActiveCommute() -> Commute? {
        return activeCommute ?? store.loadCommutes().last(where: { $0.isActive })
    }

    func startCommuting() {
        let commute: Commute
        if let activeCommute = activeCommute ?? loadActiveCommute() {
            commute = activeCommute
        } else {
            commute = Commute(start: Date())
            activeCommute = commute
        }
        store.save(commute: commute)

        manager.startUpdatingLocation()
        delegate?.commuteManager(self, startedCommute: commute)
    }

    func stopCommuting() {
        manager.stopUpdatingLocation()

        guard let commute = activeCommute ?? loadActiveCommute() else { return }

        commute.end = Date()
        if let loc = manager.location {
            commute.locations.append(Location(location: loc))
        }
        store.save(commute: commute)
        activeCommute = nil
        delegate?.commuteManager(self, endedCommute: commute)
    }
}

extension CommuteManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        switch region.identifier {
        case "home":
            if isMorning {
                startCommuting()
            }
        case "work":
            if isEvening {
                startCommuting()
            }
        default: return
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        switch region.identifier {
        case "home":
            if isEvening {
                stopCommuting()
            }
        case "work":
            if isMorning {
                stopCommuting()
            }
        default: return
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let commute: Commute
        if let activeCommute = activeCommute {
            commute = activeCommute
        } else if isMorning || isEvening {
            if let activeCommute = activeCommute {
                commute = activeCommute
            } else {
                startCommuting()
                return
            }
        } else {
            return
        }

        for location in locations {
            commute.locations.append(Location(location: location))
            for region in manager.monitoredRegions {
                guard let circle = region as? CLCircularRegion,
                    (evening.contains(Date()) && circle.identifier == "home") || (morning.contains(Date()) && circle.identifier == "work"),
                    circle.contains(location.coordinate)
                    else { continue }
                stopCommuting()
                return
            }
        }
        store.save(commute: commute)

        delegate?.commuteManager(self, updatedCommute: commute)
    }
}
