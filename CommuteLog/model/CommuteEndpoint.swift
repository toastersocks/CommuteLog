//
//  CommuteEndpoint.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/9/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

struct CommuteEndPoint {
    let identifier: String
    var entryWindow: CommuteSchedule
    var exitWindow: CommuteSchedule
    var location: Location
    var radius: Double
}

extension CommuteEndPoint {
    init(identifier: String, entryHours: ClosedRange<Int>, exitHours: ClosedRange<Int>, location: Location, radius: Double) {
        self.identifier = identifier
        self.entryWindow = CommuteSchedule(hours: entryHours)
        self.exitWindow = CommuteSchedule(hours: exitHours)
        self.location = location
        self.radius = radius
    }
}
