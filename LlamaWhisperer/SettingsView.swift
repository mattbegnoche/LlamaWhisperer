//
//  SettingsView.swift
//  llamaWhisperer
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("cleanupEnabled") private var cleanupEnabled = true
    @AppStorage("selectedModel") private var selectedModel = "llama3.2:3b"

    @State private var availableModels: [OllamaModel] = []
    @State private var isLoading = false

    var body: some View {
        Form {
            Toggle("Clean up transcripts with Ollama", isOn: $cleanupEnabled)
            Text("When off, Whisper's raw transcription is pasted directly — faster, but no punctuation fixes or filler-word removal.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Section("Ollama Model") {
                if !availableModels.isEmpty {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    .pickerStyle(.menu)
                } else if isLoading {
                    Text("Loading available models…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Couldn't reach Ollama for the model list.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Try Again") {
                        loadModels()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
        .onAppear {
            loadModels()
        }
    }

    private func loadModels() {
        isLoading = true
        Task {
            availableModels = await CleanupService().fetchAvailableModels()
            isLoading = false
        }
    }
}

#Preview {
    SettingsView()
}
