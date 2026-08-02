import AVFoundation
import AVKit
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let hardwareCaptureEnabled: Bool
    let onHardwareCapture: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onHardwareCapture)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        if #available(iOS 17.2, *) {
            let interaction = AVCaptureEventInteraction { event in
                if event.phase == .ended {
                    context.coordinator.onCapture()
                }
            }
            interaction.isEnabled = hardwareCaptureEnabled
            view.addInteraction(interaction)
            context.coordinator.captureInteraction = interaction
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        context.coordinator.onCapture = onHardwareCapture
        if #available(iOS 17.2, *),
           let interaction = context.coordinator.captureInteraction as? AVCaptureEventInteraction {
            interaction.isEnabled = hardwareCaptureEnabled
        }
    }

    final class Coordinator {
        var onCapture: () -> Void
        var captureInteraction: UIInteraction?

        init(onCapture: @escaping () -> Void) {
            self.onCapture = onCapture
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let connection = previewLayer.connection,
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
    }
}
