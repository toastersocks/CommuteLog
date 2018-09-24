//
//  Commute.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/19/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

final class Commute: Codable {
    var identifier: String
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

    init(identifier: String? = nil, start: Date, from beginning: CommuteEndPoint, to end: CommuteEndPoint) {
        self.start = start
        self.identifier = identifier ?? "\(beginning.identifier) -> \(end.identifier) \(formatter.string(from: start))"
    }
}
