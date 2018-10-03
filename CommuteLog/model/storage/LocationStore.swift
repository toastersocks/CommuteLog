//
//  LocationStore.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/26/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

protocol LocationStore {
    func save(_ location: Location)
    func locations(for commute: Commute) -> [Location]
}

extension UserDefaults: LocationStore {
    private func locations() -> [Location] {
        guard let data = value(forKey: "locations") as? Data else { return [] }

        let decoder = JSONDecoder()
        guard let locations = try? decoder.decode([Location].self, from: data) else { return [] }

        return locations
    }

    func locations(for commute: Commute) -> [Location] {
        return locations().filter { $0.timestamp >= commute.start && $0.timestamp <= commute.end ?? Date() }
    }

    func save(_ location: Location) {
        var locations = self.locations()
        locations.append(location)

        let encoder = JSONEncoder()
        set(try! encoder.encode(locations), forKey: "locations")
    }
}
