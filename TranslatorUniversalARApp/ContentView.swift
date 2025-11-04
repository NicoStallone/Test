import SwiftUI
import Speech
import AVFoundation

/// Main view providing two modes: voice translation and camera translation.
///
/// The user can toggle between voice mode (recognise speech from the microphone
/// and translate it) and camera mode (capture a photo and extract text to
/// translate). A button is provided to present an AR avatar after a translation
/// has been generated.  See `VoiceTranslator` and `CameraTranslator` for
/// implementation details.
struct ContentView: View {
    @StateObject private var voiceTranslator = VoiceTranslator()
    @StateObject private var cameraTranslator = CameraTranslator()
    @State private var showAR = false
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            // Allow the user to switch modes
            Picker(selection: $selectedTab, label: Text("Mod")) {
                Text("Voce").tag(0)
                Text("Cameră").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Voice mode UI
            if selectedTab == 0 {
                VStack(spacing: 16) {
                    Text("Vorbește în microfon și traducerea va fi redată vocal în limba țintă.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text(voiceTranslator.transcribedText)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .font(.title3)
                        .animation(.easeInOut, value: voiceTranslator.transcribedText)
                    Text(voiceTranslator.translatedText)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                        .font(.title3)
                        .animation(.easeInOut, value: voiceTranslator.translatedText)
                    HStack(spacing: 20) {
                        Button(action: {
                            if !voiceTranslator.isListening {
                                // Request permission and start listening
                                SFSpeechRecognizer.requestAuthorization { authStatus in
                                    if authStatus == .authorized {
                                        do {
                                            try voiceTranslator.startListening()
                                        } catch {
                                            print("Nu a putut porni înregistrarea: \(error)")
                                        }
                                    } else {
                                        print("Permisiune recunoaștere vorbire refuzată")
                                    }
                                }
                            } else {
                                voiceTranslator.stopListening()
                            }
                        }) {
                            Image(systemName: voiceTranslator.isListening ? "stop.circle.fill" : "mic.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(voiceTranslator.isListening ? .red : .blue)
                        }
                        .padding()
                        .accessibilityLabel("Pornește sau oprește ascultarea")
                        Button(action: {
                            voiceTranslator.speakTranslatedText()
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .disabled(voiceTranslator.translatedText.isEmpty)
                        .accessibilityLabel("Redă vocea traducerii")
                    }
                    .padding(.top, 10)
                    // Button to present AR avatar
                    if !voiceTranslator.translatedText.isEmpty {
                        Button(action: {
                            showAR = true
                        }) {
                            Label("Afișează Avatar AR", systemImage: "person.crop.circle.badge.eye")
                        }
                        .padding()
                        .background(Color.purple.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            // Camera mode UI
            else {
                ZStack(alignment: .bottom) {
                    // Camera preview
                    CameraPreviewView(session: cameraTranslator.session)
                        .onAppear {
                            cameraTranslator.setupSession()
                            cameraTranslator.startSession()
                        }
                        .onDisappear {
                            cameraTranslator.stopSession()
                        }
                    // Overlay with translated text
                    if let translated = cameraTranslator.translatedText {
                        Text(translated)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .animation(.easeIn, value: translated)
                    }
                    // Capture button
                    VStack {
                        Spacer()
                        Button(action: {
                            cameraTranslator.captureAndTranslate()
                        }) {
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.black)
                                        .font(.system(size: 30))
                                )
                        }
                        .padding(.bottom, 50)
                        .accessibilityLabel("Capturează text pentru traducere")
                    }
                }
            }
        }
        .sheet(isPresented: $showAR) {
            ARAvatarView(phraseToSpeak: voiceTranslator.translatedText)
        }
    }
}