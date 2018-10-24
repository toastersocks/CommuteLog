//
//  CommuteEndpoint.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/9/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

struct CommuteEndPoint: Codable {
    let identifier: String
    var entryWindow: CommuteSchedule
    var exitWindow: CommuteSchedule
    var location: Location
    var radius: Double
    var isHome: Bool
    var isWork: Bool { return !isHome }

    var isActive: Bool {
        return active(during: Date())
    }

    func active(during date: Date) -> Bool {
        return entryWindow.contains(date) || exitWindow.contains(date)
    }
}

extension CommuteEndPoint {
    init(identifier: String, entryHours: Range<Int>, exitHours: Range<Int>, location: Location, radius: Double, isHome: Bool) {
        self.identifier = identifier
        self.entryWindow = CommuteSchedule(hours: entryHours)
        self.exitWindow = CommuteSchedule(hours: exitHours)
        self.location = location
        self.radius = radius
        self.isHome = isHome
    }
}
