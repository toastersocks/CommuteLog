//
//  CommuteEndpoint.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/9/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

struct CommuteEndPoint: Codable {
    static let homeIdentifier: String = "home"
    static let workIdentifier: String = "work"
    let identifier: String
    var entryWindow: CommuteSchedule
    var exitWindow: CommuteSchedule
    var location: Location
    var radius: Double
    var isHome: Bool { return identifier == CommuteEndPoint.homeIdentifier }
    var isWork: Bool { return identifier == CommuteEndPoint.workIdentifier }

    func isActive(during date: Date = Date()) -> Bool {
        return entryWindow.contains(date) || exitWindow.contains(date)
    }
}

extension CommuteEndPoint {
    init(identifier: String, entryHours: Range<Int>, exitHours: Range<Int>, location: Location, radius: Double) {
        self.identifier = identifier
        self.entryWindow = CommuteSchedule(hours: entryHours)
        self.exitWindow = CommuteSchedule(hours: exitHours)
        self.location = location
        self.radius = radius
    }
}
