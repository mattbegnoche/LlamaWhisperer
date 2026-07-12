//
//  SettingsView.swift
//  llamaWhisperer
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("cleanupEnabled") private var cleanupEnabled = true
    @AppStorage("selectedModel") private var selectedModel = "llama3.2:3b"
    @AppStorage("historySize") private var historySize = 5
    
    @State private var availableModels: [OllamaModel] = []
    @State private var isLoading = false
    
    var body: some View {
        Form {
            Toggle("Clean up transcripts with Ollama", isOn: $cleanupEnabled)
            Text("When off, Whisper's raw transcription is pasted directly — faster, but no punctuation fixes or filler-word removal.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Section("Model Selection") {
                if !availableModels.isEmpty {
                    Picker("Select Model", selection: $selectedModel) {
                        ForEach(availableModels) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } else if isLoading {
                    Text("Loading available models...")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Button("Refresh Models") {
                        loadModels()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
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
            // We need to create a temporary cleanup service to fetch models
            let cleanupService = CleanupService()
            let models = await cleanupService.fetchAvailableModels()
            DispatchQueue.main.async {
                self.availableModels = models
                isLoading = false
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
