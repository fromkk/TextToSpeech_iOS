import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ContentStore: Sendable {
  var generatedURL: URL?
  var isGenerating: Bool = false
  var errorMessage: String?
  var isPlaying: Bool = false

  var text: String = ""
  var voice: String
  var language: String?

  private var audioPlayer: AVAudioPlayer?

  private enum UserDefaultsKey {
    static let voice = "selectedVoice"
    static let language = "selectedLanguage"
  }

  init() {
    // Load saved preferences or use defaults
    if let savedVoice = UserDefaults.standard.string(forKey: UserDefaultsKey.voice),
       Constants.voices.contains(savedVoice) {
      self.voice = savedVoice
    } else {
      self.voice = Constants.voices[0]
    }

    if let savedLanguage = UserDefaults.standard.string(forKey: UserDefaultsKey.language),
       Constants.languages.contains(savedLanguage) {
      self.language = savedLanguage
    } else {
      self.language = Constants.languages.first(where: {
        Locale.current.language.languageCode?.identifier == $0
      })
    }
  }

  func savePreferences() {
    UserDefaults.standard.set(voice, forKey: UserDefaultsKey.voice)
    if let language {
      UserDefaults.standard.set(language, forKey: UserDefaultsKey.language)
    }
  }

  func generateSpeech() async {
    guard !text.isEmpty else { return }

    savePreferences()

    isGenerating = true
    errorMessage = nil
    defer { isGenerating = false }

    do {
      let url = URL(string: "https://api.openai.com/v1/audio/speech")!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue(
        "Bearer \(Constants.OpenAIApiKey)",
        forHTTPHeaderField: "Authorization"
      )
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")

      var requestBody: [String: Any] = [
        "model": "gpt-4o-mini-tts",
        "input": text,
        "voice": voice,
        "format": Constants.format,
      ]
      if let language {
        requestBody["language"] = language
      }
      request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        throw NSError(
          domain: "OpenAI",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Failed to generate speech"]
        )
      }

      let tempDirectory = FileManager.default.temporaryDirectory
      let fileName = "speech_\(UUID().uuidString).mp3"
      let fileURL = tempDirectory.appendingPathComponent(fileName)

      try data.write(to: fileURL)

      generatedURL = fileURL
    } catch {
      errorMessage = error.localizedDescription
      print("Error generating speech: \(error)")
    }
  }

  func playAudio() {
    guard let url = generatedURL else { return }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
      audioPlayer = try AVAudioPlayer(contentsOf: url)
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
      isPlaying = true

      Task {
        try? await Task.sleep(
          nanoseconds: UInt64((audioPlayer?.duration ?? 0) * 1_000_000_000)
        )
        isPlaying = false
      }
    } catch {
      errorMessage = "Failed to play audio: \(error.localizedDescription)"
    }
  }

  func stopAudio() {
    audioPlayer?.stop()
    isPlaying = false
  }
}

struct ContentView: View {
  @State var store: ContentStore = .init()
  @State var showExportDialog: Bool = false
  @FocusState private var isTextEditorFocused: Bool

  var body: some View {
    ScrollView {
      VStack {
        TextEditor(text: $store.text)
          .frame(height: 200)
          .padding()
          .overlay {
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.gray, lineWidth: 1)
          }
          .focused($isTextEditorFocused)

        HStack {
          Text("Voice")

          Picker(
            "Voice",
            selection: $store.voice,
            content: {
              ForEach(Constants.voices, id: \.self) {
                Text($0).tag($0)
              }
            }
          )

          Spacer()
        }

        HStack {
          Text("Language")

          Picker(
            "Language",
            selection: $store.language,
            content: {
              ForEach(Constants.languages, id: \.self) {
                Text($0).tag($0)
              }
            }
          )

          Spacer()
        }

        Button {
          Task {
            isTextEditorFocused = false
            await store.generateSpeech()
          }
        } label: {
          if store.isGenerating {
            ProgressView()
              .controlSize(.small)
              .padding(.horizontal, 8)
          } else {
            Text("Generate")
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.text.isEmpty || store.isGenerating)

        if let errorMessage = store.errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
            .padding()
        }

        if store.generatedURL != nil {
          VStack(spacing: 16) {
            Divider()
              .padding(.vertical)

            Text("Preview")
              .font(.headline)

            HStack(spacing: 16) {
              Button {
                if store.isPlaying {
                  store.stopAudio()
                } else {
                  store.playAudio()
                }
              } label: {
                HStack {
                  Image(systemName: store.isPlaying ? "stop.fill" : "play.fill")
                  Text(store.isPlaying ? "Stop" : "Play")
                }
              }
              .buttonStyle(.bordered)

              Button {
                showExportDialog = true
              } label: {
                HStack {
                  Image(systemName: "square.and.arrow.up")
                  Text("Export")
                }
              }
              .buttonStyle(.borderedProminent)
            }
          }
          .padding()
        }
      }
      .padding()
    }
    .fileExporter(
      isPresented: Binding(
        get: { showExportDialog && store.generatedURL != nil },
        set: { showExportDialog = $0 }
      ),
      document: {
        let url = store.generatedURL ?? FileManager.default.temporaryDirectory
        return ExportFileDocument {
          url
        }
      }(),
      contentType: .mp3
    ) { result in
      let tempURL = store.generatedURL
      switch result {
      case .success(let url):
        print("Exported to: \(url)")
        if let tempURL {
          try? FileManager.default.removeItem(at: tempURL)
        }
      case .failure(let error):
        store.errorMessage = "Export failed: \(error.localizedDescription)"
      }
    }
  }
}

#Preview {
  ContentView()
}
