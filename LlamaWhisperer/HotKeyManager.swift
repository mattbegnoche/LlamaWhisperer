//
//  HotKeyManager.swift
//  llamaWhisperer
//
//  Created by Matt Begnoche on 7/11/26.
//

//
//  HotKeyManager.swift
//  llamaWhisperer
//

import Foundation
import AVFoundation
import Cocoa
import HotKey
import Combine

private let cleanupService = CleanupService()

class HotKeyManager: ObservableObject {
    private var hotKey: HotKey
    private var audioRecorder: AVAudioRecorder?
    @Published private(set) var isRecording = false
    @Published private(set) var isTranscribing = false
    @Published private(set) var ollamaIsDown = false
    private let transcriber = Transcriber()

    init() {
        hotKey = HotKey(key: .d, modifiers: [.command, .shift])

        hotKey.keyDownHandler = { [weak self] in
            self?.toggleRecording()
        }
    }

    func toggleRecording() {
        guard !isTranscribing else {
            print("Still transcribing previous recording, please wait")
            return
        }

        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        let url = recordingURL()

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            print("Recording started: \(url.path)")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isTranscribing = true
        print("Recording stopped")

        let url = recordingURL()

        Task {
            let rawText = await transcriber.transcribe(fileURL: url)
            print("Raw transcription: \(rawText)")

            guard !isSilence(rawText) else {
                print("Recording sounded silent, nothing to paste")
                isTranscribing = false
                return
            }

            // Default to true when the preference has never been set —
            // bool(forKey:) alone would report false for a missing key.
            let cleanupEnabled = UserDefaults.standard.object(forKey: "cleanupEnabled") as? Bool ?? true

            let textToPaste: String
            if cleanupEnabled {
                switch await cleanupService.cleanup(text: rawText) {
                case .cleaned(let cleaned):
                    ollamaIsDown = false
                    textToPaste = cleaned
                case .ollamaUnavailable(let raw):
                    ollamaIsDown = true
                    textToPaste = raw
                }
            } else {
                // Cleanup intentionally off: paste raw and clear any warning.
                ollamaIsDown = false
                textToPaste = rawText
            }
            print("Pasting: \(textToPaste)")

            pasteText(textToPaste)
            isTranscribing = false
        }
    }

    /// Whisper hallucinates on silent audio: annotations like "[BLANK_AUDIO]"
    /// or "(silence)", and repeated filler words like "you". Treat those
    /// transcripts as silence so we never paste junk.
    private func isSilence(_ text: String) -> Bool {
        let stripped = text.replacingOccurrences(
            of: "\\[[^\\]]*\\]|\\([^)]*\\)",
            with: "",
            options: .regularExpression
        )

        let words = stripped
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return words.isEmpty || words.allSatisfy { $0 == "you" }
    }

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func recordingURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("flowlocal_recording.wav")
    }
}
