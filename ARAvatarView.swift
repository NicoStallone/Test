import SwiftUI
import RealityKit
import ARKit
import AVFoundation

/// A SwiftUI view that wraps a RealityKit `ARView` and shows a simple
/// avatar (by default, a blue sphere) in augmented reality.  When the
/// view appears, the provided phrase will be spoken aloud.
struct ARAvatarView: View {
    @Environment(\.dismiss) private var dismiss
    let phraseToSpeak: String
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ARViewContainer().edgesIgnoringSafeArea(.all)
            Button("Închide") {
                dismiss()
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
        }
        .onAppear {
            // Speak the phrase when the AR view is presented
            if !phraseToSpeak.isEmpty {
                let synth = AVSpeechSynthesizer()
                let utterance = AVSpeechUtterance(string: phraseToSpeak)
                utterance.voice = AVSpeechSynthesisVoice(language: "ro-RO")
                synth.speak(utterance)
            }
        }
    }
}

/// A UIViewRepresentable that creates an ARView with a simple 3D model.
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        config.environmentTexturing = .automatic
        arView.session.run(config, options: [])
        // Place a blue sphere one metre in front of the camera
        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.1), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        anchor.addChild(sphere)
        arView.scene.addAnchor(anchor)
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {
        // Nothing to update
    }
}