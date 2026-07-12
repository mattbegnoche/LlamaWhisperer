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

    private var menuBarIcon: String {
        if hotKeyManager.isRecording { return "mic.circle.fill" }
        if hotKeyManager.isTranscribing { return "hourglass" }
        if hotKeyManager.ollamaIsDown { return "exclamationmark.triangle.fill" }
        return "mic.fill"
    }

    var body: some Scene {
        MenuBarExtra("llamaWhisperer", systemImage: menuBarIcon) {
            if hotKeyManager.ollamaIsDown {
                Text("⚠️ Ollama not running — pasting raw transcripts")
                Divider()
            }
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

