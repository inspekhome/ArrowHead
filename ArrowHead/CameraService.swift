import AVFoundation
import Combine
import UIKit

@MainActor
final class CameraService: NSObject, ObservableObject {
    @Published private(set) var permissionDenied = false
    @Published private(set) var isReady = false
    @Published private(set) var cameraPosition: AVCaptureDevice.Position = .back
    @Published private(set) var isSwitchingCamera = false
    @Published private(set) var zoomFactor: CGFloat = 1

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "ArrowHead.CameraSession")
    private var captureContinuation: CheckedContinuation<UIImage, Error>?

    override init() {
        super.init()
        requestAccessAndConfigure()
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func restart() {
        sessionQueue.async { [weak self] in
            guard
                let self,
                !self.session.inputs.isEmpty,
                !self.session.outputs.isEmpty
            else { return }

            if self.session.isRunning {
                self.session.stopRunning()
            }
            self.session.startRunning()
        }
    }

    func capturePhoto(flashMode: CameraFlashMode) async throws -> UIImage {
        guard captureContinuation == nil else {
            throw CameraError.captureAlreadyInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            captureContinuation = continuation
            if let connection = photoOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
            let settings = AVCapturePhotoSettings(format: [
                AVVideoCodecKey: AVVideoCodecType.jpeg
            ])
            // Different iPhone camera configurations expose different maximum
            // quality priorities. Asking for a value above that maximum causes
            // AVFoundation to raise an Objective-C exception and terminate the app.
            settings.photoQualityPrioritization = photoOutput.maxPhotoQualityPrioritization
            if let input = session.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first,
               input.device.hasFlash {
                settings.flashMode = flashMode.avMode
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func switchCamera() {
        guard isReady, captureContinuation == nil, !isSwitchingCamera else { return }
        isSwitchingCamera = true
        isReady = false
        let requestedPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back

        sessionQueue.async { [weak self] in
            guard let self else { return }
            let oldInput = self.session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.first
            guard
                let camera = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: requestedPosition
                ),
                let newInput = try? AVCaptureDeviceInput(device: camera)
            else {
                Task { @MainActor in
                    self.isReady = true
                    self.isSwitchingCamera = false
                }
                return
            }

            self.session.beginConfiguration()
            if let oldInput { self.session.removeInput(oldInput) }
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
            } else if let oldInput, self.session.canAddInput(oldInput) {
                self.session.addInput(oldInput)
            }
            self.session.commitConfiguration()

            let activePosition = self.session.inputs
                .compactMap { $0 as? AVCaptureDeviceInput }
                .first?.device.position ?? .back
            Task { @MainActor in
                self.cameraPosition = activePosition
                self.zoomFactor = 1
                self.isReady = true
                self.isSwitchingCamera = false
            }
        }
    }

    func setZoomFactor(_ requestedFactor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard
                let self,
                let device = self.session.inputs
                    .compactMap({ $0 as? AVCaptureDeviceInput })
                    .first?.device
            else { return }

            let maximum = min(device.maxAvailableVideoZoomFactor, 8)
            let factor = min(max(requestedFactor, device.minAvailableVideoZoomFactor), maximum)
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = factor
                device.unlockForConfiguration()
                Task { @MainActor in self.zoomFactor = factor }
            } catch {
                return
            }
        }
    }

    private func requestAccessAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.configureSession()
                    } else {
                        self.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            defer { self.session.commitConfiguration() }

            guard
                let camera = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                ),
                let input = try? AVCaptureDeviceInput(device: camera),
                self.session.canAddInput(input),
                self.session.canAddOutput(self.photoOutput)
            else {
                Task { @MainActor in
                    self.permissionDenied = true
                }
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.photoOutput)

            Task { @MainActor in
                self.isReady = true
                self.start()
            }
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                captureContinuation?.resume(throwing: error)
                captureContinuation = nil
                return
            }

            guard
                let data = photo.fileDataRepresentation(),
                let image = UIImage(data: data)
            else {
                captureContinuation?.resume(throwing: CameraError.invalidImageData)
                captureContinuation = nil
                return
            }

            captureContinuation?.resume(returning: image)
            captureContinuation = nil
        }
    }
}

enum CameraError: LocalizedError {
    case captureAlreadyInProgress
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .captureAlreadyInProgress:
            "A photo is already being captured."
        case .invalidImageData:
            "The camera did not return a usable photo."
        }
    }
}
