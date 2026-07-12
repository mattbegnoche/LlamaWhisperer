# LlamaWhisperer

A macOS menu bar dictation app that runs **100% locally** — no cloud APIs, no subscriptions, works offline.

Press a hotkey, speak, press it again: your words are transcribed by [Whisper](https://github.com/ggerganov/whisper.cpp), cleaned up by a local LLM via [Ollama](https://ollama.com) (punctuation, capitalization, filler-word removal), and pasted straight into whatever app has focus.

## How it works

1. **⌘⇧D** starts recording from the microphone (menu bar icon shows recording state)
2. **⌘⇧D** again stops it; the audio is transcribed on-device with Whisper (`ggml-base.en`)
3. The transcript is sent to your chosen Ollama model, which fixes punctuation and strips "um"s and "uh"s
4. The cleaned text is pasted into the frontmost app via a simulated ⌘V

If Ollama isn't running, the raw transcript is pasted instead — dictation is never lost — and the menu bar icon shows a warning triangle. Silent recordings are detected and skipped entirely.

## Features

- Global hotkey (⌘⇧D) that works in any app
- Fully offline: audio and text never leave your Mac
- Menu bar status icons: idle, recording, transcribing, Ollama unreachable
- Settings window (⌘,): toggle the LLM cleanup step on/off, and pick any Ollama model you have installed
- Graceful fallback to raw transcription when Ollama is down

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later (to build)
- [Ollama](https://ollama.com) with at least one model installed

## Setup

### 1. Clone and add the Whisper model

The Whisper model file is too large for GitHub, so download it separately into the source folder:

```bash
git clone https://github.com/mattbegnoche/LlamaWhisperer.git
cd LlamaWhisperer
curl -L -o LlamaWhisperer/ggml-base.en.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

### 2. Install Ollama and a model

```bash
brew install ollama
brew services start ollama   # runs in the background, auto-starts at login
ollama pull llama3.2:3b
```

### 3. Build and run

Open `LlamaWhisperer.xcodeproj` in Xcode and run (⌘R). Swift Package Manager fetches the two dependencies ([HotKey](https://github.com/soffes/HotKey), [SwiftWhisper](https://github.com/exPHAT/SwiftWhisper)) automatically.

### 4. Grant permissions

- **Microphone** — macOS prompts on your first recording; click Allow.
- **Accessibility** — required for the auto-paste. Go to **System Settings → Privacy & Security → Accessibility** and enable LlamaWhisperer. Without this, text lands on the clipboard but won't paste automatically.

## Usage

Click into any text field, press **⌘⇧D**, speak, and press **⌘⇧D** again. The cleaned-up text appears where your cursor is.

The menu bar icon also offers Start Recording, Settings…, and Quit.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| ⚠️ triangle in the menu bar | Ollama is unreachable. Check `brew services list`; raw transcripts still paste in the meantime. |
| First dictation after a while is slow | Ollama loads the model into memory on demand; subsequent requests are fast. |
| Nothing pasted after a recording | The recording sounded silent, so the app skipped pasting rather than output junk. |
| Text copies but doesn't paste | Accessibility permission is missing (see Setup step 4). |

## Privacy

Everything runs on your machine: audio is recorded to a temporary local file, transcription happens in-process via whisper.cpp, and cleanup goes to Ollama on `localhost`. No network requests leave your Mac.
