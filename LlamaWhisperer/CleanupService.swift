//
//  CleanupService.swift
//  llamaWhisperer
//
//  Created by Matt Begnoche on 7/11/26.
//

import Foundation

/// The outcome of a cleanup attempt. Both cases carry the text to paste,
/// so dictation is never lost — but the caller can tell whether Ollama
/// actually cleaned it or we fell back to the raw transcript.
enum CleanupResult {
    case cleaned(String)
    case ollamaUnavailable(rawText: String)
}

/// Represents an Ollama model available for use
struct OllamaModel: Codable, Identifiable {
    let name: String
    let modifiedAt: Date
    let size: UInt64
    let digest: String
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
        case size
        case digest
    }
}

class CleanupService {
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/generate")!
    private let modelsEndpoint = URL(string: "http://127.0.0.1:11434/api/tags")!
    private var model = "llama3.2:3b"

    func cleanup(text: String) async -> CleanupResult {
        let prompt = "Clean up this dictated transcript. Fix punctuation and capitalization, remove filler words like 'um' and 'uh', but keep the original meaning and wording otherwise. Only return the cleaned text, nothing else:\n\n\(text)"

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]

        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let cleaned = json?["response"] as? String {
                return .cleaned(cleaned.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return .ollamaUnavailable(rawText: text)
        } catch {
            print("Cleanup failed, using raw text: \(error)")
            return .ollamaUnavailable(rawText: text)
        }
    }
    
    /// Fetches all available models from Ollama
    func fetchAvailableModels() async -> [OllamaModel] {
        do {
            var request = URLRequest(url: modelsEndpoint)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let modelsArray = json?["models"] as? [[String: Any]] {
                var models: [OllamaModel] = []
                
                for modelDict in modelsArray {
                    guard let name = modelDict["name"] as? String,
                          let modifiedAtString = modelDict["modified_at"] as? String,
                          let size = modelDict["size"] as? UInt64,
                          let digest = modelDict["digest"] as? String else {
                        continue
                    }
                    
                    // Parse the date string
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let modifiedAt = dateFormatter.date(from: modifiedAtString) {
                        let model = OllamaModel(name: name, modifiedAt: modifiedAt, size: size, digest: digest)
                        models.append(model)
                    }
                }
                return models
            }
        } catch {
            print("Failed to fetch available models: \(error)")
        }
        return []
    }
    
    /// Gets the currently configured model
    func getCurrentModel() -> String {
        print("Switching model to: \(model)")
        return model
    }
    
    /// Sets a new model to use for cleanup
    func setModel(_ newModel: String) {
        print("Current model is: \(newModel)")
        model = newModel
    }
    }
