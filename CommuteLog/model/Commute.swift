//
//  Commute.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

private let twelveHours = TimeInterval(12 * 60 * 60)
final class Commute: Codable {
    var start: Date
    var end: Date?
    var locations: [Location] = []
    var description: String = ""

    var duration: DateInterval {
        return DateInterval(start: start, end: end ?? Date())
    }

    var isActive: Bool {
        return end == nil
    }

    init(start: Date) {
        self.start = start
    }
}
