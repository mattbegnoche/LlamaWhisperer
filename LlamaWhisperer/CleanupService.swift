//
//  CleanupService.swift
//  llamaWhisperer
//
//  Created by Matt Begnoche on 7/11/26.
//

import Foundation

class CleanupService {
    private let endpoint = URL(string: "http://localhost:11434/api/generate")!
    private let model = "llama3.2:3b"

    func cleanup(text: String) async -> String {
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
            let cleaned = json?["response"] as? String

            return cleaned?.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
        } catch {
            print("Cleanup failed, using raw text: \(error)")
            return text
        }
    }
}
