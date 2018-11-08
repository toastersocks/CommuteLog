//
//  Table+Section.swift
//  CommuteLog
//
//  Created by James Pamplona on 11/2/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

struct Section<Item> {
    let title: String?
    let hideIfEmpty: Bool
    let items: [Item]

    init(title: String? = nil, hideIfEmpty: Bool = true, items: [Item] = []) {
        self.title = title
        self.hideIfEmpty = hideIfEmpty
        self.items = items
    }

    init(title: String? = nil, hideIfEmpty: Bool = true, items: Item...) {
        self.init(title: title, hideIfEmpty: hideIfEmpty, items: items)
    }

    init(_ title: String?, hideIfEmpty: Bool = true, with getItems: () -> [Item] ) {
        self.init(title: title, hideIfEmpty: hideIfEmpty, items: getItems())
    }
}

struct Table<Item> {
    let sections: [Section<Item>]
    var allItems: [Item] {
        return sections.reduce([Item]()) {
            $0 + $1.items
        }
    }

    init(sections: [Section<Item>]) {
        self.sections = Array(sections.filter { !($0.hideIfEmpty && $0.items.isEmpty) })
    }

    init(_ sections: Section<Item>...) {
        self.init(sections: sections)
    }

    init(with getSections: () -> [Section<Item>]) {
        self.init(sections: getSections())
    }

    subscript(_ sectionIndex: Int) -> Section<Item> {
        return sections[sectionIndex]
    }
}
