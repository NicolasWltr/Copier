//
//  CopierView.swift
//  Copier
//
//  Created by Nicolas Walter on 06.09.26.
//

import SwiftUI
import AppKit

struct CopierView: View {
    @EnvironmentObject private var controller: ClipboardController

    @State private var highlightedIndex = 0

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Copier")
                    .font(.title.bold())

                ForEach(
                    Array(controller.entries.enumerated()),
                    id: \.element.id
                ) { index, entry in
                    Divider()

                    CopyEntryView(
                        entry: entry,
                        selected: entry.id == controller.selected,
                        highlighted: highlightedIndex == index,
                        onSelect: {
                            select(index)
                        },
                        onPin: {
                            controller.pin(id: entry.id)
                        },
                        onDelete: {
                            controller.delete(id: entry.id)
                        }
                    )
                }
                
                Divider()
                    .padding(.vertical, 5)
                
                HStack {
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(20)

            Spacer()
        }
        .background {
            KeyboardMonitor { event in
                handleKey(event)
            }
        }
        .onAppear {
            highlightedIndex = 0
        }
        .onChange(of: controller.entries.count) {
            if controller.entries.isEmpty {
                highlightedIndex = 0
            } else {
                highlightedIndex = min(
                    highlightedIndex,
                    controller.entries.count - 1
                )
            }
        }
    }

    // MARK: - Keyboard

    private func handleKey(_ event: NSEvent) {
        switch event.keyCode {
        case 126: // Arrow Up
            moveUp()

        case 125: // Arrow Down
            moveDown()

        case 36, 76: // Return / Enter
            selectHighlighted()

        default:
            break
        }
    }

    private func moveUp() {
        guard !controller.entries.isEmpty else {
            return
        }

        if highlightedIndex > 0 {
            highlightedIndex -= 1
        }
    }

    private func moveDown() {
        guard !controller.entries.isEmpty else {
            return
        }

        if highlightedIndex < controller.entries.count - 1 {
            highlightedIndex += 1
        }
    }

    private func selectHighlighted() {
        guard controller.entries.indices.contains(highlightedIndex) else {
            return
        }

        select(highlightedIndex)
    }

    private func select(_ index: Int) {
        guard controller.entries.indices.contains(index) else {
            return
        }

        highlightedIndex = index
        controller.select(controller.entries[index])
    }
}

// MARK: - Keyboard Monitor

private struct KeyboardMonitor: NSViewRepresentable {
    let onKey: (NSEvent) -> Void

    func makeNSView(context: Context) -> KeyboardView {
        let view = KeyboardView()
        view.onKey = onKey
        return view
    }

    func updateNSView(
        _ nsView: KeyboardView,
        context: Context
    ) {
        nsView.onKey = onKey
    }

    final class KeyboardView: NSView {
        var onKey: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            if window != nil {
                window?.makeFirstResponder(self)
            }
        }

        override func keyDown(with event: NSEvent) {
            onKey?(event)
        }
    }
}

#Preview {
    CopierView()
}
