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
    var store: CommuteStore
    weak var delegate: CommuteDelegate?

    var endpoints: [CommuteEndPoint]

    private var _cachedActiveCommute: Commute?
    var activeCommute: Commute? {
        if _cachedActiveCommute == nil {
            _cachedActiveCommute = store.loadActiveCommute()
        }
        return _cachedActiveCommute
    }

    init(store: CommuteStore, endPoints: [CommuteEndPoint]) {
        self.store = store
        self.endpoints = endPoints
    }

    func processLocation(_ location: Location) {
        guard let commute = activeCommute else {
            print("Got location \(location) without activeCommute")
            return
        }
        commute.locations.append(location)
        store.saveActiveCommute(commute)
        delegate?.commuteManager(self, updatedCommute: commute)
    }

    func enteredRegion(_ identifier: String) {
        guard let endpoint = endpoints.first(where: { $0.identifier == identifier }) else { return }
        guard endpoint.entryWindow.isActive else { return }

        let commute = Commute(start: Date())
        _cachedActiveCommute = commute
        store.saveActiveCommute(commute)
        delegate?.commuteManager(self, startedCommute: commute)
    }

    func exitedRegion(_ identifier: String) {
        guard let endpoint = endpoints.first(where: { $0.identifier == identifier }) else { return }
        guard endpoint.exitWindow.isActive else { return }

        guard let commute = store.removeActiveCommute() else { return }
        _cachedActiveCommute = nil
        delegate?.commuteManager(self, endedCommute: commute)
    }
}
