//
//  CommuteSchedule.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/9/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

struct CommuteSchedule: Codable {
    let startHour: Int
    let endHour: Int

    var hours: Range<Int> { return startHour..<endHour }

    func contains(_ date: Date) -> Bool {
        guard !Calendar.current.isDateInWeekend(date) else { return false }
        guard let hour = Calendar.current.dateComponents([.hour], from: date).hour else { return false }
        return contains(hour)
    }

    func contains(_ hour: Int) -> Bool {
        return hours.contains(hour)
    }

    func distance(from hour: Int) -> Int {
        switch hour {
        case 0..<startHour:
            return startHour - hour
        case endHour+1 ..< 24:
            return hour - endHour - 1
        default: return 0
        }
    }
}

extension CommuteSchedule {
    init(hours: Range<Int>) {
        self.startHour = hours.startIndex
        self.endHour = hours.endIndex
    }
}
