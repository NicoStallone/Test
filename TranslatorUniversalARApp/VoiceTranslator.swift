import Foundation
import Speech
import AVFoundation

/// A view model responsible for recognising speech from the microphone,
/// translating it and speaking the result.  The translation logic is
/// intentionally left as a placeholder for you to replace with your own
/// translation implementation (for example, using Apple's Translation
/// framework on iOS 17+ or an external API).
final class VoiceTranslator: NSObject, ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechSynth = AVSpeechSynthesizer()

    @Published var isListening: Bool = false
    @Published var transcribedText: String = ""
    @Published var translatedText: String = ""

    func startListening() throws {
        cancelListening()
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = false
        recognitionRequest.requiresOnDeviceRecognition = true
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        self.transcribedText = ""
        self.translatedText = ""
        self.isListening = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let bestTranscription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = bestTranscription
                }
                if result.isFinal {
                    self.stopListening()
                    // Perform translation after transcription is final
                    self.translateTranscribedText()
                }
            }
            if error != nil {
                self.stopListening()
            }
        }
    }

    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        isListening = false
    }

    func cancelListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    /// Placeholder translation method.  Replace this implementation with an
    /// actual translation call.  At present it simply copies the transcribed
    /// text to the translated text.  To translate offline, you might use
    /// Apple's Translation framework when available or a custom CoreML model.
    private func translateTranscribedText() {
        // TODO: Replace this placeholder with a real translation implementation
        DispatchQueue.main.async {
            self.translatedText = self.transcribedText
            // After translation, speak the translation automatically
            self.speakTranslatedText()
        }
    }

    /// Speaks the current translated text using AVSpeechSynthesizer.
    func speakTranslatedText() {
        guard !translatedText.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: translatedText)
        // Use the target language voice if needed (here set to Romanian)
        utterance.voice = AVSpeechSynthesisVoice(language: "ro-RO")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynth.stopSpeaking(at: .immediate)
        speechSynth.speak(utterance)
    }
}