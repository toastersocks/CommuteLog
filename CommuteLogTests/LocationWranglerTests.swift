//
//  LocationWranglerTests.swift
//  CommuteLogTests
//
//  Created by Ryan Arana on 10/2/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import XCTest
@testable import CommuteLog

class LocationWranglerTests: XCTestCase {
    private var store: MockLocationStore!
    private var wrangler: LocationWrangler!
    private var accuracyFilter: Double!
    private var delegate: MockLocationWranglerDelegate!

    override func setUp() {
        super.setUp()
        store = MockLocationStore()
        accuracyFilter = 75
        wrangler = LocationWrangler(store: store, accuracyFilter: accuracyFilter)
        delegate = MockLocationWranglerDelegate()

        wrangler.delegate = delegate
    }

    func testProcessLocations_discardsLocations_withWorseAccuracyThanLimit() {
        XCTAssert(store.savedLocations.isEmpty)
        XCTAssert(delegate.receivedLocations.isEmpty)
        let date = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        let location = Location(latitude: 1, longitude: 1, accuracy: wrangler.accuracyFilter + 1, timestamp: date)
        wrangler.processLocation(location)
        XCTAssert(store.savedLocations.isEmpty)
        XCTAssert(delegate.receivedLocations.isEmpty)
    }

    func testProcessLocations_includesLocations_withAccuracyEqualToLimit() {
        XCTAssert(store.savedLocations.isEmpty)
        XCTAssert(delegate.receivedLocations.isEmpty)
        let date = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        let location = Location(latitude: 1, longitude: 1, accuracy: wrangler.accuracyFilter, timestamp: date)

        delegate.expectation = expectation(description: "Delegate Callback")
        wrangler.processLocation(location)

        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(store.savedLocations.isEmpty)
        XCTAssertFalse(delegate.receivedLocations.isEmpty)
    }

}

private class MockLocationStore: LocationStore {
    var savedLocations: [Location] = []
    func save(_ location: Location) {
        savedLocations.append(location)
    }

    var locationsForCommute_received: [Commute] = []
    var locationsForCommute_output: [String: [Location]] = [:]
    func locations(for commute: Commute) -> [Location] {
        locationsForCommute_received.append(commute)
        return locationsForCommute_output[commute.identifier] ?? []
    }
}

private class MockLocationWranglerDelegate: LocationWranglerDelegate {
    var expectation: XCTestExpectation?
    var receivedLocations: [Location] = []
    func wrangler(_ wrangler: LocationWrangler, didReceiveLocation location: Location) {
        receivedLocations.append(location)
        expectation?.fulfill()
    }
}
