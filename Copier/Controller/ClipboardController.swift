import Foundation
import AppKit
import Combine

@MainActor
final class ClipboardController: ObservableObject {
    @Published private(set) var entries: [CopyModel] = []
    @Published private(set) var selected: UUID?

    private var lastChangeCount = 0
    private var monitoringTask: Task<Void, Never>?

    init() {
        lastChangeCount = NSPasteboard.general.changeCount

        monitoringTask = Task {
            await monitorClipboard()
        }
    }

    deinit {
        monitoringTask?.cancel()
    }

    private func monitorClipboard() async {
        while !Task.isCancelled {
            checkClipboard()

            try? await Task.sleep(
                for: .milliseconds(200)
            )
        }
    }
    
    func pin(id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else {
            return
        }

        if entries[index].fixed != nil {
            entries[index].fixed = nil
        } else {
            entries[index].fixed = Date()
        }
        
        self.sort()
    }
    
    func sort() {
        entries.sort { a, b in
            switch (a.fixed, b.fixed) {
            case let (aFixed?, bFixed?):
                if aFixed != bFixed {
                    return aFixed > bFixed
                }

                return a.date < b.date

            case (_?, nil):
                return true

            case (nil, _?):
                return false

            case (nil, nil):
                return a.date > b.date
            }
        }

        if entries.count > 25 {
            entries.removeLast(entries.count - 25)
        }
    }
    
    func delete(id: UUID) {
        self.entries = self.entries.filter { model in
            return model.id != id
        }
    }

    func checkClipboard() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = pasteboard.changeCount

        let items = capturePasteboard(pasteboard)

        guard !items.isEmpty else {
            return
        }

        addEntry(items)
    }

    private func capturePasteboard(
        _ pasteboard: NSPasteboard
    ) -> [PasteboardItem] {
        pasteboard.pasteboardItems?.compactMap { item in

            let representations = item.types.compactMap {
                type -> PasteboardRepresentation? in

                guard let data = item.data(forType: type) else {
                    return nil
                }

                return PasteboardRepresentation(
                    type: type.rawValue,
                    data: data
                )
            }

            guard !representations.isEmpty else {
                return nil
            }

            return PasteboardItem(
                representations: representations
            )
        } ?? []
    }

    private func addEntry(
        _ items: [PasteboardItem]
    ) {
        let entry = CopyModel(
            items: items
        )

        entries.insert(entry, at: 0)
        selected = entry.id
        
        self.sort()
    }

    func select(_ entry: CopyModel) {
        let pasteboard = NSPasteboard.general

        pasteboard.clearContents()

        let pasteboardItems = entry.items.map { item in
            let pasteboardItem = NSPasteboardItem()

            for representation in item.representations {
                pasteboardItem.setData(
                    representation.data,
                    forType: NSPasteboard.PasteboardType(
                        representation.type
                    )
                )
            }

            return pasteboardItem
        }

        pasteboard.writeObjects(pasteboardItems)

        // We caused this change ourselves.
        lastChangeCount = pasteboard.changeCount

        selected = entry.id
    }
}
