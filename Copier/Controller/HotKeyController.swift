//
//  HotKeyController.swift
//  Copier
//
//  Created by Nicolas Walter on 06.09.26.
//

import Carbon.HIToolbox
import AppKit

final class HotKeyController {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init() {
        registerHotKey()
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func registerHotKey() {
        let hotKeyID = EventHotKeyID(
            signature: OSType("COPR".fourCharCode),
            id: 1
        )

        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            print("Failed to register hotkey: \(status)")
            return
        }

        self.hotKeyRef = hotKeyRef

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        var handlerRef: EventHandlerRef?

        let status2 = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            &eventType,
            nil,
            &handlerRef
        )

        guard status2 == noErr else {
            print("Failed to install hotkey handler: \(status2)")
            return
        }

        self.eventHandlerRef = handlerRef
    }
}

// MARK: - Carbon callback

private func hotKeyCallback(
    _: EventHandlerCallRef?,
    event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else {
        return noErr
    }

    var hotKeyID = EventHotKeyID()

    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr, hotKeyID.id == 1 else {
        return noErr
    }

    DispatchQueue.main.async {
        openMenuBarExtra()
    }

    return noErr
}

// MARK: - MenuBarExtra

private func openMenuBarExtra() {
    guard let statusItem = NSApp.windows.first?.value(
        forKey: "statusItem"
    ) as? NSStatusItem else {
        print("Could not find MenuBarExtra status item")
        return
    }

    statusItem.button?.performClick(nil)
}

// MARK: - Four character code

private extension String {
    var fourCharCode: UInt32 {
        var result: UInt32 = 0

        for byte in utf8 {
            result = (result << 8) | UInt32(byte)
        }

        return result
    }
}
