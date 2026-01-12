# TextToSpeech

A sample iOS application that converts text to speech using OpenAI's Text-to-Speech API. Generate, play, and export audio files with ease.

## Features

- Text-to-speech conversion using OpenAI TTS API
- Multiple voice options
- Support for 16 languages
- Audio playback
- Export to MP3 format
- Automatic saving of voice and language preferences

## Available Voices

alloy, ash, ballad, coral, echo, fable, nova, onyx, sage, shimmer, verse, marin, cedar

## Supported Languages

de, en, es, fr, hi, id, it, ja, ko, nl, pl, pt, ru, uk, vi, zh

## Requirements

- iOS 17.0+
- Xcode 15.0+
- OpenAI API Key

## Setup

1. Clone the repository
```bash
git clone https://github.com/fromkk/TextToSpeech.git
cd TextToSpeech
```

2. Add your OpenAI API key to `TextToSpeech/Constants.swift`
```swift
static let OpenAIApiKey = "sk-proj-..."  // Replace with your actual API key
```

**Security Note:** The API key is currently hardcoded in the source file. For production use, consider:
- Adding `Constants.swift` to `.gitignore` to prevent committing your API key
- Using environment variables or a secure configuration file
- Using Xcode configuration files (`.xcconfig`) that are excluded from version control

3. Open the project in Xcode and build
```bash
open TextToSpeech.xcodeproj
```

## Usage

1. Enter text in the text editor
2. Select your preferred voice and language
3. Tap "Generate" to create the audio
4. Use "Play" to listen to the generated audio
5. Use "Export" to save as an MP3 file

## Technologies

- SwiftUI
- OpenAI Text-to-Speech API (gpt-4o-mini-tts)
- AVFoundation

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

[Kazuya Ueoka](https://github.com/fromkk)
