//
//  SettingsView.swift
//  llamaWhisperer
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("cleanupEnabled") private var cleanupEnabled = true

    var body: some View {
        Form {
            Toggle("Clean up transcripts with Ollama", isOn: $cleanupEnabled)
            Text("When off, Whisper's raw transcription is pasted directly — faster, but no punctuation fixes or filler-word removal.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }
}
