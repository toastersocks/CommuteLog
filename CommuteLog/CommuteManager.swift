//
//  CommuteManager.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

protocol CommuteDelegate: class {
    func commuteManager(_ manager: CommuteManager, startedCommute: Commute)
    func commuteManager(_ manager: CommuteManager, updatedCommute: Commute)
    func commuteManager(_ manager: CommuteManager, endedCommute: Commute)
}

class CommuteManager {
    private var store: CommuteStore
    weak var delegate: CommuteDelegate?

    var home: CommuteEndPoint
    var work: CommuteEndPoint

    private var _cachedActiveCommute: Commute?
    var activeCommute: Commute? {
        if _cachedActiveCommute == nil {
            _cachedActiveCommute = store.commute(identifier: "active")
        }
        return _cachedActiveCommute
    }

    init(store: CommuteStore, home: CommuteEndPoint, work: CommuteEndPoint) {
        self.store = store
        self.home = home
        self.work = work
    }

    func processLocation(_ location: Location) {
        if activeCommute == nil {
            Logger.debug("Got location update without an activeCommute.")
            if home.exitWindow.isActive || work.entryWindow.isActive {
                startCommute(from: home)
            } else if home.entryWindow.isActive || work.exitWindow.isActive {
                startCommute(from: work)
            }
        }
        guard let commute = activeCommute else {
            Logger.warning("Got location \(location) without activeCommute outside of commute hours.")
            return
        }
        
        Logger.debug("Adding location \(location) to activeCommute.")
        commute.locations.append(location)
        store.save(commute)
        delegate?.commuteManager(self, updatedCommute: commute)
    }

    func enteredRegion(_ identifier: String) {
        let endpoint = identifier == home.identifier ? home : work
        guard endpoint.entryWindow.isActive else {
            Logger.debug("Ignoring inactive region.")
            return
        }

        endCommute(save: true)
    }

    func exitedRegion(_ identifier: String) {
        let endpoint = identifier == home.identifier ? home : work
        guard endpoint.exitWindow.isActive else {
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
        guard let commute = store.commute(identifier: "active") else { return }
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
