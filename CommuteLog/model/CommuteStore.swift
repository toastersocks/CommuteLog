//
//  CommuteStore.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

protocol CommuteStore {
    func save(commute: Commute)
    func loadCommutes() -> [Commute]
    func save(commutes: [Commute])

    func saveActiveCommute(_ commute: Commute)
    func loadActiveCommute() -> Commute?
    @discardableResult
    func removeActiveCommute() -> Commute?

    @discardableResult
    func delete(commute: Commute) -> Int?
}

extension CommuteStore {
    func save(commute: Commute) {
        var commutes = loadCommutes()
        if let index = commutes.firstIndex(where: { $0.start == commute.start }) {
            commutes[index] = commute
        } else {
            commutes.append(commute)
        }
        save(commutes: commutes)
    }

    func delete(commute: Commute) -> Int? {
        var commutes = loadCommutes()
        guard let index = commutes.firstIndex(where: {
            $0.start == commute.start &&
            $0.end == commute.end &&
            $0.description == commute.description &&
            $0.locations.count == commute.locations.count
        }) else {
            return nil
        }

        commutes.remove(at: index)
        save(commutes: commutes)
        return index
    }
}

extension UserDefaults: CommuteStore {
    func saveActiveCommute(_ commute: Commute) {
        let encoder = JSONEncoder()
        set(try! encoder.encode(commute), forKey: "activeCommute")
    }

    func loadActiveCommute() -> Commute? {
        guard let commuteData = value(forKey: "activeCommute") as? Data else { return nil }

        let decoder = JSONDecoder()
        return try? decoder.decode(Commute.self, from: commuteData)
    }

    func removeActiveCommute() -> Commute? {
        guard let active = loadActiveCommute() else { return nil }
        active.end = Date()
        return active
    }

    func loadCommutes() -> [Commute] {
        guard let commutesData = value(forKey: "commutes") as? Data else { return [] }

        let decoder = JSONDecoder()
        guard let commutes = try? decoder.decode([Commute].self, from: commutesData) else { return [] }
        return commutes
    }

    func save(commutes: [Commute]) {
        let encoder = JSONEncoder()
        set(try! encoder.encode(commutes), forKey: "commutes")
    }
}
