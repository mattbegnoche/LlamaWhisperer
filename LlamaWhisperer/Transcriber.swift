//
//  Transcriber.swift
//  llamaWhisperer
//
//  Created by Matt Begnoche on 7/11/26.
//

import Foundation
import SwiftWhisper
import AVFoundation

class Transcriber {
    private let whisper: Whisper

    init() {
        let modelURL = Bundle.main.url(forResource: "ggml-base.en", withExtension: "bin")!
        whisper = Whisper(fromFileURL: modelURL)
        whisper.params.language = .english
    }

    func transcribe(fileURL: URL) async -> String {
        do {
            let audioFrames = try readPCMAudio(fileURL: fileURL)
            let segments = try await whisper.transcribe(audioFrames: audioFrames)
            return segments.map(\.text).joined()
        } catch {
            print("Transcription failed: \(error)")
            return ""
        }
    }

    private func readPCMAudio(fileURL: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: fileURL)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))!
        try file.read(into: buffer)

        let floatArray = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
        return floatArray
    }
}
