import Foundation
import AVFoundation
import Vision

/// View model responsible for capturing a still image from the camera,
/// recognising printed text using Vision and translating it.
///
/// The translation functionality is left as a placeholder; by default
/// this class returns the recognized text as the translation. Replace
/// `translate(text:)` with a proper translation implementation.
final class CameraTranslator: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var translatedText: String? = nil
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    func setupSession() {
        session.beginConfiguration()
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
    }

    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    /// Capture a single photo and translate text found in it.
    func captureAndTranslate() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = false
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Eroare captură foto: \(error!.localizedDescription)")
            return
        }
        guard let pixelBuffer = photo.pixelBuffer else {
            print("Nu s-a putut obține pixelBuffer.")
            return
        }
        // Use Vision to recognise text
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let observations = request.results as? [VNRecognizedTextObservation] {
                var fullText = ""
                for obs in observations {
                    if let candidate = obs.topCandidates(1).first {
                        fullText += candidate.string + " "
                    }
                }
                // Perform translation on the recognised text
                let translated = self.translate(text: fullText)
                DispatchQueue.main.async {
                    self.translatedText = translated
                }
            }
        }
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Eroare la procesarea OCR: \(error.localizedDescription)")
        }
    }

    /// Placeholder translation method.  Replace this with your own translation
    /// logic.  Currently it simply returns the original text.
    private func translate(text: String) -> String {
        // TODO: Replace this placeholder with a real translation implementation
        return text
    }
}