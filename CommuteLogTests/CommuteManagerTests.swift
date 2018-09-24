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
    var home = CommuteEndPoint(identifier: "home", entryHours: 6..<10, exitHours: 16..<20, location: Location(latitude: 0, longitude: 0), radius: 10)
    var work = CommuteEndPoint(identifier: "work", entryHours: 7..<11, exitHours: 15..<19, location: Location(latitude: 100, longitude: 100), radius: 10)
    var manager: CommuteManager!

    override func setUp() {
        super.setUp()

        store = MockCommuteStore()
        manager = CommuteManager(store: store, home: home, work: work)
    }

    func testCommuteManager_processLocation_updatesStoredActiveCommute() {
        let active = Commute(start: Date(), from: home, to: work)
        store.save(active)

        XCTAssert(active.locations.isEmpty)
        XCTAssert(active.isActive)

        manager.processLocation(Location(latitude: 0, longitude: 0, timestamp: Date()))

        XCTAssertFalse(active.locations.isEmpty)
        XCTAssertFalse(store.commute(identifier: "active")?.locations.isEmpty ?? true)
    }

}

private class MockCommuteStore: CommuteStore {
    var commutes: [String: Commute]

    init(commutes: [String: Commute] = [:]) {
        self.commutes = commutes
    }

    func save(_ commutes: [String: Commute]) {
        self.commutes = commutes
    }

    func loadCommutes() -> [String: Commute] {
        return commutes
    }
}
