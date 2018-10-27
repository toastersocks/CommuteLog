//
//  CommuteStore.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

protocol CommuteStore {
    func save(_ commute: Commute)
    func loadCommutes() -> [String: Commute]
    func save(_ commutes: [String: Commute])

    @discardableResult
    func delete(_ commute: Commute) -> Bool
    @discardableResult
    func delete(commuteIdentifier: String) -> Bool

    func loadEndPoint(_ identifier: String) -> CommuteEndPoint?
    func saveEndPoint(_ endPoint: CommuteEndPoint)

    var defaultHome: CommuteEndPoint { get }
    var defaultWork: CommuteEndPoint { get }
}

extension CommuteStore {
    func commute(identifier: String) -> Commute? {
        return loadCommutes()[identifier]
    }
    
    func save(_ commute: Commute) {
        var commutes = loadCommutes()
        if commute.end == nil {
            commutes["active"] = commute
        } else {
            commutes[commute.identifier] = commute
        }
        save(commutes)
    }

    func delete(_ commute: Commute) -> Bool {
        return delete(commuteIdentifier: commute.identifier)
    }

    func delete(commuteIdentifier: String) -> Bool {
        var commutes = loadCommutes()
        let result = commutes.removeValue(forKey: commuteIdentifier)
        save(commutes)
        return result != nil
    }

    var defaultHome: CommuteEndPoint {
        return CommuteEndPoint(
            identifier: CommuteEndPoint.homeIdentifier,
            entryHours: 17..<22,
            exitHours: 5..<10,
            location: Location(latitude: 45.5085273, longitude: -122.6538027),
            radius: 50
        )
    }

    func loadHome() -> CommuteEndPoint {
        return loadEndPoint(CommuteEndPoint.homeIdentifier) ?? defaultHome
    }

    var defaultWork: CommuteEndPoint {
        return CommuteEndPoint(
            identifier: CommuteEndPoint.workIdentifier,
            entryHours: 6..<11,
            exitHours: 16..<21,
            location: Location(latitude: 45.5167522, longitude: -122.6792086),
            radius: 50
        )
    }

    func loadWork() -> CommuteEndPoint {
        return loadEndPoint(CommuteEndPoint.workIdentifier) ?? defaultWork
    }
}

extension UserDefaults: CommuteStore {
    func loadCommutes() -> [String: Commute] {
        guard let commutesData = value(forKey: "commutes") as? Data else { return [:] }

        let decoder = JSONDecoder()
        guard let commutes = try? decoder.decode([String: Commute].self, from: commutesData) else { return [:] }
        return commutes
    }

    func save(_ commutes: [String: Commute]) {
        let encoder = JSONEncoder()
        set(try! encoder.encode(commutes), forKey: "commutes")
    }

    func saveEndPoint(_ endPoint: CommuteEndPoint) {
        let encoder = JSONEncoder()
        do {
            set(try encoder.encode(endPoint), forKey: "endPoints-\(endPoint.identifier)")
        } catch {
            Logger.error("Failed to encode endPoint `\(endPoint.identifier)`: \(error)")
        }
    }

    func loadEndPoint(_ identifier: String) -> CommuteEndPoint? {
        guard let data = data(forKey: "endPoints-\(identifier)") else { return nil }
        do {
            let decoder = JSONDecoder()
            let endPoint = try decoder.decode(CommuteEndPoint.self, from: data)
            return endPoint
        } catch {
            Logger.error("Failed to decode endPoint '\(identifier)': \(error)")
            return nil
        }
    }
}
