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

/// One installed Ollama model, as listed by the /api/tags endpoint.
struct OllamaModel: Decodable, Identifiable {
    let name: String
    var id: String { name }
}

/// The shape of the /api/tags response: { "models": [...] }
private struct OllamaTagsResponse: Decodable {
    let models: [OllamaModel]
}

class CleanupService {
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/generate")!
    private let modelsEndpoint = URL(string: "http://127.0.0.1:11434/api/tags")!

    /// The model picked in Settings; read fresh on every request so a
    /// change takes effect immediately without restarting the app.
    private var model: String {
        UserDefaults.standard.string(forKey: "selectedModel") ?? "llama3.2:3b"
    }

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
    
    /// Fetches the models installed in Ollama, for the Settings picker.
    /// Returns an empty array if Ollama is unreachable.
    func fetchAvailableModels() async -> [OllamaModel] {
        do {
            let (data, _) = try await URLSession.shared.data(from: modelsEndpoint)
            return try JSONDecoder().decode(OllamaTagsResponse.self, from: data).models
        } catch {
            print("Failed to fetch available models: \(error)")
            return []
        }
    }
}
