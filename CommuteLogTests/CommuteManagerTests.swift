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
    private var store: MockCommuteStore!
    var home = CommuteEndPoint(identifier: "home", entryHours: 6..<10, exitHours: 16..<20, location: Location(latitude: 0, longitude: 0), radius: 10)
    var work = CommuteEndPoint(identifier: "work", entryHours: 7..<11, exitHours: 15..<19, location: Location(latitude: 100, longitude: 100), radius: 10)
    var manager: CommuteManager!

    override func setUp() {
        super.setUp()

        store = MockCommuteStore()
        manager = CommuteManager(store: store, home: home, work: work)
    }

    func testEnteredRegion_endsHomeCommute() {
        var entryDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        entryDate = Calendar.current.date(bySetting: .hour, value: manager.home.entryWindow.startHour + 1, of: entryDate)!

        manager.startCommute(from: manager.work)
        XCTAssertNotNil(manager.activeCommute)
        manager.enteredRegion("home", at: entryDate)
        XCTAssertNil(manager.activeCommute)
    }

    func testEnteredRegion_endsWorkCommute() {
        var entryDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        entryDate = Calendar.current.date(bySetting: .hour, value: manager.work.entryWindow.startHour + 1, of: entryDate)!

        manager.startCommute(from: manager.home)
        XCTAssertNotNil(manager.activeCommute)
        manager.enteredRegion("work", at: entryDate)
        XCTAssertNil(manager.activeCommute)
    }

    func testEnteredRegion_ignoresInactiveRegion() {
        var entryDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        entryDate = Calendar.current.date(bySetting: .hour, value: manager.home.entryWindow.startHour - 1, of: entryDate)!

        manager.startCommute(from: manager.work)
        XCTAssertNotNil(manager.activeCommute)
        manager.enteredRegion("home", at: entryDate)
        XCTAssertNotNil(manager.activeCommute)
    }

    func testExitedRegion_startsHomeCommute() {
        var exitDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        exitDate = Calendar.current.date(bySetting: .hour, value: manager.home.exitWindow.startHour + 1, of: exitDate)!

        XCTAssertNil(manager.activeCommute)
        manager.exitedRegion("home", at: exitDate)
        XCTAssertNotNil(manager.activeCommute)
    }

    func testExitedRegion_startsWorkCommute() {
        var exitDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        exitDate = Calendar.current.date(bySetting: .hour, value: manager.work.exitWindow.startHour + 1, of: exitDate)!

        XCTAssertNil(manager.activeCommute)
        manager.exitedRegion("work", at: exitDate)
        XCTAssertNotNil(manager.activeCommute)
    }

    func testExitedRegion_ignoresInactiveRegion() {
        var exitDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        exitDate = Calendar.current.date(bySetting: .hour, value: manager.work.exitWindow.startHour - 1, of: exitDate)!

        XCTAssertNil(manager.activeCommute)
        manager.exitedRegion("work", at: exitDate)
        XCTAssertNil(manager.activeCommute)
    }

    func testExitedRegion_ignoresRegionCrossing_whenAlreadyTrackingCommute() {
        var exitDate = Calendar.current.date(bySetting: .weekdayOrdinal, value: 3, of: Date())!
        exitDate = Calendar.current.date(bySetting: .hour, value: manager.home.exitWindow.startHour + 1, of: exitDate)!

        let commute = Commute(identifier: "test", start: Date(timeIntervalSinceNow: -120), from: home, to: work)
        store.commutes["active"] = commute
        XCTAssertEqual(manager.activeCommute?.identifier, commute.identifier)

        manager.exitedRegion("home", at: exitDate)
        XCTAssertEqual(manager.activeCommute?.identifier, commute.identifier)
    }

    func testStartCommute_setsActiveCommute() {
        XCTAssertNil(manager.activeCommute)
        manager.startCommute(from: home)
        XCTAssertNotNil(manager.activeCommute)
    }

    func testStartCommute_createsCommuteInStore() {
        XCTAssertNil(store.commute(identifier: "active"))
        manager.startCommute(from: home)
        XCTAssertNotNil(store.commute(identifier: "active"))
    }

    func testEndCommute_doesNothing_whenNoActiveCommute() {
        XCTAssertNil(manager.activeCommute)
        manager.endCommute(save: true)
        XCTAssertNil(manager.activeCommute)
        XCTAssertEqual(store.commutes.count, 0)
    }

    func testEndCommute_savesCommuteWithEndDate() {
        manager.startCommute(from: home)
        XCTAssertNotNil(store.commutes["active"])
        let commute = store.commutes["active"]!
        XCTAssertNil(commute.end)
        XCTAssertNil(store.commutes[commute.identifier])

        manager.endCommute(save: true)
        XCTAssertNil(store.commutes["active"])
        XCTAssertNotNil(store.commutes[commute.identifier])
        XCTAssertNotNil(commute.end)
    }

    func testDelete_deletesCommute_andReturnsTrue() {
        let commute = Commute(start: Date(), from: home, to: work)
        commute.identifier = "test"
        store.commutes["test"] = commute
        XCTAssertEqual(manager.fetchCommutes().filter({ $0.identifier == "test" }).count, 1)
        XCTAssert(manager.delete(commute))
        XCTAssertNil(store.commutes["test"])
    }

    func testDelete_returnsFalse_whenCommuteDoesntExist() {
        let commute = Commute(start: Date(), from: home, to: work)
        commute.identifier = "test"

        XCTAssertNil(store.commutes["test"])
        XCTAssertFalse(manager.delete(commute))
    }

    func testFetchCommutes_sortsCommutesByStartDate() {
        store.commutes = [
            "a": Commute(identifier: "a", start: Date(timeIntervalSinceNow: -120), from: home, to: work),
            "b": Commute(identifier: "b", start: Date(timeIntervalSinceNow: -240), from: home, to: work),
            "c": Commute(identifier: "c", start: Date(timeIntervalSinceNow: -180), from: home, to: work)
        ]

        let commutes = manager.fetchCommutes()
        XCTAssertEqual(commutes[0].identifier, "a")
        XCTAssertEqual(commutes[1].identifier, "c")
        XCTAssertEqual(commutes[2].identifier, "b")
    }

    func testActiveCommute_loadsMostRecentCommuteWithoutAnEnd() {
        XCTAssertNil(manager.activeCommute)
        store.commutes = [
            "a": Commute(identifier: "a", start: Date(timeIntervalSinceNow: -120), from: home, to: work),
            "b": Commute(identifier: "b", start: Date(timeIntervalSinceNow: -20), from: home, to: work),
            "c": Commute(identifier: "c", start: Date(timeIntervalSinceNow: -180), from: home, to: work)
        ]
        store.commutes["c"]?.end = Date()

        XCTAssertEqual(manager.activeCommute?.identifier, "b")
        manager.endCommute(save: true)
        XCTAssertNotNil(store.commutes["b"]?.end)
        XCTAssertEqual(manager.activeCommute?.identifier, "a")
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
