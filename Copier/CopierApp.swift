//
//  CopierApp.swift
//  Copier
//
//  Created by Nicolas Walter on 06.09.26.
//

import SwiftUI

@main
struct CopierApp: App {
    @StateObject private var clipboardController = ClipboardController()
    private let hotKeyController = HotKeyController()
    
    var body: some Scene {
        MenuBarExtra {
            CopierView()
                .fixedSize(horizontal: true, vertical: true)
                .environmentObject(clipboardController)
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)
    }
}
