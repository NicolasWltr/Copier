//
//  CopyModel.swift
//  Copier
//
//  Created by Nicolas Walter on 06.09.26.
//

import Foundation

struct CopyModel: Identifiable {
    let id: UUID
    let date: Date
    let items: [PasteboardItem]
    var fixed: Date? = nil

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        items: [PasteboardItem]
    ) {
        self.id = id
        self.date = date
        self.items = items
    }
}

struct PasteboardItem {
    let representations: [PasteboardRepresentation]
}

struct PasteboardRepresentation {
    let type: String
    let data: Data
}
