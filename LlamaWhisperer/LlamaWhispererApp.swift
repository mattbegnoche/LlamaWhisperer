//
//  LlamaWhispererApp.swift
//  llamaWhisperer
//
//  Created by Matt Begnoche on 7/11/26.
//

import SwiftUI

@main
struct LlamaWhispererApp: App {
    @StateObject private var hotKeyManager = HotKeyManager()

    var body: some Scene {
        MenuBarExtra("llamaWhisperer", systemImage: hotKeyManager.isRecording ? "mic.circle.fill" : (hotKeyManager.isTranscribing ? "hourglass" : "mic.fill")) {
            Button("Start Recording") {
                hotKeyManager.toggleRecording()
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

