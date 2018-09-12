//
//  CommuteManagerTests.swift
//  CommuteLogTests
//
//  Created by Ryan Arana on 9/11/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import XCTest

@testable import CommuteLog

class CommuteManagerTests: XCTestCase {
    var store: CommuteStore!
    var home = CommuteEndPoint(identifier: "home", entryHours: 6...10, exitHours: 16...20, location: Location(latitude: 0, longitude: 0), radius: 10)
    var work = CommuteEndPoint(identifier: "work", entryHours: 7...11, exitHours: 15...19, location: Location(latitude: 100, longitude: 100), radius: 10)

    override func setUp() {
        super.setUp()

        store = MockCommuteStore()
    }

    func testCommuteManager_processLocation_updatesStoredActiveCommute() {
        let manager = CommuteManager(store: store, endPoints: [home, work])

        let active = Commute(start: Date())
        store.saveActiveCommute(active)

        XCTAssert(active.locations.isEmpty)

        manager.processLocation(Location(latitude: 0, longitude: 0, timestamp: Date()))

        XCTAssertFalse(active.locations.isEmpty)
        XCTAssertFalse(store.loadActiveCommute()?.locations.isEmpty ?? true)
    }

}

private class MockCommuteStore: CommuteStore {
    var commutes: [Commute]
    var activeCommute: Commute?

    init(commutes: [Commute] = [], activeCommute: Commute? = nil) {
        self.commutes = commutes
        self.activeCommute = activeCommute
    }

    func save(commutes: [Commute]) {
        self.commutes = commutes
    }
    func loadCommutes() -> [Commute] {
        return commutes
    }

    func saveActiveCommute(_ commute: Commute) {
        activeCommute = commute
    }
    func loadActiveCommute() -> Commute? {
        return activeCommute
    }
    func removeActiveCommute() -> Commute? {
        let commute = activeCommute
        activeCommute = nil
        return commute
    }
}
