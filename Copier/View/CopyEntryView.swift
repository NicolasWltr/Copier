//
//  CopyEntryView.swift
//  Copier
//
//  Created by Nicolas Walter on 06.09.26.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct CopyEntryView: View {
    let entry: CopyModel
    let selected: Bool
    let highlighted: Bool
    let onSelect: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    @State var hovered: Bool = false
    @State private var animateCheckmark = false

    var body: some View {
        HStack {
            Button {
                onSelect()
            } label: {
                HStack(spacing: 10) {
                    typeIcon
                        .frame(width: 20)

                    Text(contentPreview)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                        .symbolEffect(
                            .bounce,
                            value: animateCheckmark
                        )
                        .rotationEffect(.degrees(animateCheckmark ? 360 : 0))
                        .onAppear {
                            animateCheckmark = true
                        }
                        .onDisappear {
                            animateCheckmark = false
                        }
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.65),
                            value: animateCheckmark
                        )
                }
                
                if hovered {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .frame(width: 24)
                    .transition(
                        .opacity.combined(with: .offset(x: 10))
                    )
                }
                
                if hovered || entry.fixed != nil {
                    Button {
                        onPin()
                    } label: {
                        Image(systemName: entry.fixed == nil ? "pin" : "pin.slash")
                    }
                    .frame(width: 24)
                    .transition(
                        .opacity.combined(with: .offset(x: 10))
                    )
                }
            }
            .frame(width: 96, alignment: .trailing)
        }
        .onHover { hovering in
            hovered = hovering
        }
        .animation(.easeInOut(duration: 0.15), value: hovered)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(highlighted ? .gray.opacity(0.1) : .clear)
        }

    }

    @ViewBuilder
    private var typeIcon: some View {
        if containsImage {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        } else if containsFile {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
        } else if containsURL {
            Image(systemName: "link")
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "text.alignleft")
                .foregroundStyle(.secondary)
        }
    }

    private var contentPreview: String {
        if let fileName {
            return fileName
        }

        if let text {
            return text
        }

        if containsImage {
            return "Image"
        }

        return "Unknown clipboard content"
    }

    // MARK: - Text

    private var text: String? {
        for item in entry.items {
            for representation in item.representations {
                guard let type = UTType(representation.type) else {
                    continue
                }

                if type.conforms(to: .plainText) {
                    if let text = String(
                        data: representation.data,
                        encoding: .utf8
                    ) {
                        return text
                    }
                }

                if type.conforms(to: .rtf) ||
                   type.conforms(to: .rtfd) {

                    if let attributed = try? NSAttributedString(
                        data: representation.data,
                        options: [:],
                        documentAttributes: nil
                    ) {
                        return attributed.string
                    }
                }

                if type.conforms(to: .html) {
                    if let attributed = try? NSAttributedString(
                        data: representation.data,
                        options: [
                            .documentType:
                                NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        return attributed.string
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Image

    private var containsImage: Bool {
        entry.items.contains { item in
            item.representations.contains { representation in
                guard let type = UTType(representation.type) else {
                    return false
                }

                return type.conforms(to: .image)
            }
        }
    }

    // MARK: - File

    private var containsFile: Bool {
        entry.items.contains { item in
            item.representations.contains { representation in
                guard let type = UTType(representation.type) else {
                    return false
                }

                return type.conforms(to: .fileURL)
            }
        }
    }

    private var fileName: String? {
        for item in entry.items {
            for representation in item.representations {
                guard let type = UTType(representation.type),
                      type.conforms(to: .fileURL)
                else {
                    continue
                }

                if let url = URL(
                    dataRepresentation: representation.data,
                    relativeTo: nil
                ) {
                    return url.lastPathComponent
                }

                if let string = String(
                    data: representation.data,
                    encoding: .utf8
                ),
                let url = URL(string: string) {
                    return url.lastPathComponent
                }
            }
        }

        return nil
    }

    // MARK: - URL

    private var containsURL: Bool {
        guard text != nil else {
            return false
        }

        return entry.items.contains { item in
            item.representations.contains { representation in
                guard let type = UTType(representation.type) else {
                    return false
                }

                return type.conforms(to: .url)
            }
        }
    }
}

#Preview {
    VStack {
        CopyEntryView(
            entry: CopyModel(
                items: [
                    PasteboardItem(
                        representations: [
                            PasteboardRepresentation(
                                type: UTType.plainText.identifier,
                                data: Data(
                                    "This is some copied text".utf8
                                )
                            )
                        ]
                    )
                ]
            ),
            selected: true,
            highlighted: false,
            onSelect: {},
            onPin: {},
            onDelete: {}
        )

        CopyEntryView(
            entry: CopyModel(
                items: [
                    PasteboardItem(
                        representations: [
                            PasteboardRepresentation(
                                type: UTType.plainText.identifier,
                                data: Data(
                                    "Another clipboard entry".utf8
                                )
                            )
                        ]
                    )
                ]
            ),
            selected: false,
            highlighted: false,
            onSelect: {},
            onPin: {},
            onDelete: {}
        )
    }
    .padding()
}
