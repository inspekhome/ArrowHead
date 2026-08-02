import SwiftUI
import UIKit

private struct RecentPhoto: Identifiable {
    let id: String
    let image: UIImage
}

struct ContentView: View {
    @StateObject private var camera = CameraService()
    @StateObject private var speech = SpeechInputService()
    @AppStorage("selectedMarker") private var storedKind = MarkerKind.arrow.rawValue
    @AppStorage("markerEnabled") private var markerEnabled = true
    @AppStorage("photoRatio") private var storedRatio = PhotoRatio.fourThree.rawValue
    @AppStorage("flashMode") private var storedFlashMode = CameraFlashMode.off.rawValue
    @AppStorage("hiddenPreviewAssetIDs") private var hiddenPreviewAssetIDs = ""
    @AppStorage("shootingModeLocked") private var shootingModeLocked = false
    @AppStorage("lockedCameraPosition") private var lockedCameraPosition = "back"
    @AppStorage("lockedPhotoRatio") private var lockedPhotoRatio = PhotoRatio.fourThree.rawValue
    @AppStorage("lockedFlashMode") private var lockedFlashMode = CameraFlashMode.off.rawValue
    @AppStorage("lockedMarkerKind") private var lockedMarkerKind = MarkerKind.arrow.rawValue
    @AppStorage("lockedMarkerEnabled") private var lockedMarkerEnabled = true
    @State private var captionText = ""
    @State private var markerCenter = CGPoint(x: 0.36, y: 0.68)
    @State private var dragStart = CGPoint(x: 0.36, y: 0.68)
    @State private var markerScale = 1.0
    @State private var scaleStart = 1.0
    @State private var markerRotation = -55.0
    @State private var rotationStart = -55.0
    @State private var isCapturing = false
    @State private var statusMessage = ""
    @State private var cameraPreviewSize = CGSize(width: 3, height: 4)
    @State private var recentPhotos: [RecentPhoto] = []
    @State private var selectedPreviewID: String?
    @State private var isPreviewPresented = false
    @State private var zoomGestureStart: CGFloat = 1
    @State private var captionDraft = ""
    @State private var isCaptionEditing = false
    @State private var isAboutPresented = false
    @State private var speechPrefix = ""
    @FocusState private var captionEditorFocused: Bool

    private let captionCharacterLimit = 100

    private var markerKind: MarkerKind {
        get { MarkerKind(rawValue: storedKind) ?? .arrow }
        nonmutating set { storedKind = newValue.rawValue }
    }

    private var photoRatio: PhotoRatio {
        get { PhotoRatio(rawValue: storedRatio) ?? .fourThree }
        nonmutating set { storedRatio = newValue.rawValue }
    }

    private var flashMode: CameraFlashMode {
        get { CameraFlashMode(rawValue: storedFlashMode) ?? .off }
        nonmutating set { storedFlashMode = newValue.rawValue }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                recentPhotoStrip
                cameraArea
                controls
            }
        }
        .foregroundStyle(.white)
        .onDisappear { camera.stop() }
        .task {
            if shootingModeLocked {
                storedRatio = lockedPhotoRatio
                storedFlashMode = lockedFlashMode
                storedKind = lockedMarkerKind
                markerEnabled = lockedMarkerEnabled
            }
            let hidden = Set(hiddenPreviewAssetIDs.split(separator: "\n").map(String.init))
            recentPhotos = await PhotoLibrarySaver.recentImages()
                .filter { !hidden.contains($0.assetIdentifier) }
                .map { RecentPhoto(id: $0.assetIdentifier, image: $0.image) }
            if shootingModeLocked, lockedCameraPosition == "front" {
                for _ in 0..<20 where !camera.isReady {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                if camera.isReady, camera.cameraPosition == .back {
                    camera.switchCamera()
                }
            }
        }
        .fullScreenCover(isPresented: $isPreviewPresented) {
            photoPreview
        }
        .sheet(isPresented: $isAboutPresented) {
            AboutView()
        }
    }

    private var recentPhotoStrip: some View {
        HStack(spacing: 6) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        if recentPhotos.isEmpty {
                            Text("拍摄后的照片会显示在这里")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .frame(width: 220, height: 70)
                        } else {
                            ForEach(recentPhotos) { photo in
                                Button {
                                    selectedPreviewID = photo.id
                                    isPreviewPresented = true
                                } label: {
                                    Image(uiImage: photo.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.35)))
                                }
                                .buttonStyle(.plain)
                                .id(photo.id)
                            }
                        }
                    }
                    .padding(.leading, 10)
                }
                .onChange(of: recentPhotos.count) { _, count in
                    guard count > 0 else { return }
                    withAnimation { proxy.scrollTo(recentPhotos.last?.id, anchor: .trailing) }
                }
            }

            Button {
                isAboutPresented = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("关于 ArrowHead 和隐私政策")
            .padding(.trailing, 10)
        }
        .frame(height: 82)
        .background(.black)
    }

    private var photoPreview: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: Binding(
                get: { selectedPreviewID ?? recentPhotos.first?.id ?? "" },
                set: { selectedPreviewID = $0 }
            )) {
                ForEach(recentPhotos) { photo in
                    Image(uiImage: photo.image)
                        .resizable()
                        .scaledToFit()
                        .padding(.vertical, 80)
                        .tag(photo.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Button {
                        isPreviewPresented = false
                    } label: {
                        Label("关闭", systemImage: "xmark")
                            .font(.headline.weight(.bold))
                            .frame(minWidth: 90, minHeight: 54)
                            .background(.black.opacity(0.7), in: Capsule())
                    }
                    Spacer()
                    Button(role: .destructive) {
                        removeSelectedPreview()
                    } label: {
                        Label("移除预览", systemImage: "trash.fill")
                            .font(.headline.weight(.bold))
                            .frame(minWidth: 130, minHeight: 54)
                            .background(.black.opacity(0.7), in: Capsule())
                    }
                }
                .foregroundStyle(.white)
                .padding()
                Spacer()
                Text("只从顶部预览移除；相册原照片会保留")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.75), in: Capsule())
                    .padding(.bottom, 20)
            }
        }
    }

    private func removeSelectedPreview() {
        guard
            let selectedPreviewID,
            let index = recentPhotos.firstIndex(where: { $0.id == selectedPreviewID })
        else { return }

        var hidden = Set(hiddenPreviewAssetIDs.split(separator: "\n").map(String.init))
        hidden.insert(selectedPreviewID)
        hiddenPreviewAssetIDs = hidden.sorted().joined(separator: "\n")
        recentPhotos.remove(at: index)

        guard !recentPhotos.isEmpty else {
            self.selectedPreviewID = nil
            isPreviewPresented = false
            return
        }
        self.selectedPreviewID = recentPhotos[min(index, recentPhotos.count - 1)].id
    }

    private var cameraArea: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let markerSize = min(size.width, size.height) * 0.24 * fixedMarkerScale
            let fixedCenter = fixedPreviewCenter(in: size, markerSize: markerSize)
            ZStack {
                if camera.permissionDenied {
                    ContentUnavailableView(
                        "需要相机权限",
                        systemImage: "camera.fill",
                        description: Text("请在 iPhone 设置中允许 ArrowHead 使用相机。")
                    )
                } else {
                    CameraPreview(
                        session: camera.session,
                        hardwareCaptureEnabled: camera.isReady && !isCapturing && !isCaptionEditing,
                        onHardwareCapture: takePicture
                    )
                }

                if markerKind != .none {
                    MarkerOverlay(
                        kind: markerKind,
                        size: markerSize,
                        rotationDegrees: fixedMarkerRotation,
                        guideOnly: !markerEnabled
                    )
                    .position(x: fixedCenter.x * size.width, y: fixedCenter.y * size.height)
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(cameraZoomGesture)
            .onTapGesture {
                toggleCaptionEditing()
            }
            .onAppear { cameraPreviewSize = size }
            .onChange(of: size) { _, newSize in cameraPreviewSize = newSize }
            .overlay(alignment: .top) {
                cameraToolbar
                    .padding(.top, 10)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f×", camera.zoomFactor))
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.65), in: Capsule())
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.75), in: Capsule())
                    }
                    if isCaptionEditing {
                        VStack(spacing: 4) {
                            HStack(spacing: 10) {
                                TextField(
                                    "输入照片文字…",
                                    text: Binding(
                                        get: { captionDraft },
                                        set: { captionDraft = limitedCaption($0) }
                                    ),
                                    axis: .vertical
                                )
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .tint(.white)
                                .lineLimit(1...5)
                                .focused($captionEditorFocused)
                                .submitLabel(.done)
                                .onSubmit { finishCaptionEditing() }

                                Button {
                                    if !speech.isListening {
                                        speechPrefix = captionDraft.isEmpty ? "" : captionDraft + " "
                                    }
                                    captionEditorFocused = false
                                    speech.toggle { recognizedText in
                                        captionDraft = limitedCaption(speechPrefix + recognizedText)
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Image(systemName: speech.isListening ? "mic.fill" : "mic")
                                            .font(.title2.weight(.bold))
                                        Text(speech.isListening ? "正在听…" : "语音")
                                            .font(.caption2.weight(.bold))
                                    }
                                    .foregroundStyle(speech.isListening ? .red : .white)
                                    .frame(minWidth: 64, minHeight: 48)
                                }
                            }
                            HStack {
                                if !speech.errorMessage.isEmpty {
                                    Text(speech.errorMessage).foregroundStyle(.yellow)
                                } else if captionDraft.count >= captionCharacterLimit - 15 {
                                    Text("即将达到文字上限").foregroundStyle(.yellow)
                                } else {
                                    Text("第二次点击画面结束输入")
                                }
                                Spacer()
                                Text("\(captionDraft.count)/\(captionCharacterLimit)")
                                    .foregroundStyle(captionDraft.count == captionCharacterLimit ? .yellow : .white)
                            }
                            .font(.caption2.weight(.semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.95), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                    } else if !captionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(captionText)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(5)
                            .multilineTextAlignment(captionText.count <= 20 ? .center : .leading)
                            .frame(
                                minWidth: 144,
                                alignment: captionText.count <= 20 ? .center : .leading
                            )
                            .padding(.horizontal, 28)
                            .padding(.vertical, 20)
                            .background(Color.blue.opacity(0.9), in: RoundedRectangle(cornerRadius: 28))
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    private var cameraZoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                camera.setZoomFactor(zoomGestureStart * value.magnification)
            }
            .onEnded { _ in
                zoomGestureStart = camera.zoomFactor
            }
    }

    private func toggleCaptionEditing() {
        if isCaptionEditing {
            finishCaptionEditing()
        } else {
            captionDraft = captionText
            isCaptionEditing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                captionEditorFocused = true
            }
        }
    }

    private func finishCaptionEditing() {
        speech.stop()
        captionText = captionDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        isCaptionEditing = false
        captionEditorFocused = false
    }

    private func limitedCaption(_ value: String) -> String {
        let flattened = value.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        return String(flattened.prefix(captionCharacterLimit))
    }

    private var cameraToolbar: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(PhotoRatio.allCases) { ratio in
                    Button(ratio.rawValue) { photoRatio = ratio }
                }
            } label: {
                cameraToolButton(title: photoRatio.rawValue, icon: "aspectratio")
            }
            .disabled(shootingModeLocked)

            Menu {
                ForEach(CameraFlashMode.allCases) { mode in
                    Button {
                        flashMode = mode
                    } label: {
                        Label(mode.rawValue, systemImage: mode.systemImage)
                    }
                }
            } label: {
                cameraToolButton(title: "Flash \(flashMode.rawValue)", icon: flashMode.systemImage)
            }
            .disabled(shootingModeLocked)

            Button {
                let switchingToFront = camera.cameraPosition == .back
                camera.switchCamera()
                if switchingToFront {
                    flashMode = .off
                }
            } label: {
                cameraToolButton(
                    title: camera.cameraPosition == .back ? "后置镜头" : "前置镜头",
                    icon: camera.isSwitchingCamera ? "hourglass" : "camera.rotate.fill"
                )
            }
            .disabled(shootingModeLocked || isCapturing || camera.isSwitchingCamera)

            Button {
                if shootingModeLocked {
                    shootingModeLocked = false
                } else {
                    lockedPhotoRatio = photoRatio.rawValue
                    lockedFlashMode = flashMode.rawValue
                    lockedMarkerKind = markerKind.rawValue
                    lockedMarkerEnabled = markerEnabled
                    lockedCameraPosition = camera.cameraPosition == .front ? "front" : "back"
                    shootingModeLocked = true
                }
            } label: {
                cameraToolButton(
                    title: shootingModeLocked ? "模式已锁" : "锁定模式",
                    icon: shootingModeLocked ? "lock.fill" : "lock.open.fill"
                )
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }

    private func cameraToolButton(title: String, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.headline)
            Text(title).font(.caption2.weight(.bold)).lineLimit(1)
        }
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.yellow, lineWidth: 2.5))
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Menu {
                ForEach(MarkerKind.allCases.filter { $0 != .none }) { kind in
                    Button {
                        selectMarker(kind)
                    } label: {
                        Label(kind.rawValue, systemImage: kind.systemImage)
                    }
                }
            } label: {
                controlButton(title: markerKind.rawValue, icon: markerKind.systemImage, active: true)
            }
            .disabled(shootingModeLocked)

            Button(action: takePicture) {
                ZStack {
                    Circle().stroke(.white.opacity(0.55), lineWidth: 5).frame(width: 82, height: 82)
                    Circle().fill(isCapturing ? .gray : .white).frame(width: 68, height: 68)
                }
            }
            .disabled(!camera.isReady || isCapturing)
            .accessibilityLabel("拍照")

            Button { markerEnabled.toggle() } label: {
                controlButton(
                    title: markerEnabled ? "ON" : "OFF",
                    icon: markerEnabled ? "eye.fill" : "eye.slash.fill",
                    active: markerEnabled
                )
            }
            .disabled(shootingModeLocked)
            .accessibilityLabel(markerEnabled ? "关闭标注" : "打开标注")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(.black)
    }

    private func controlButton(title: String, icon: String, active: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.title2.weight(.bold))
            Text(title).font(.caption.weight(.bold))
        }
        .foregroundStyle(active ? .red : .white)
        .frame(width: 92, height: 62)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(active ? .yellow : .gray, lineWidth: 3))
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                markerCenter = CGPoint(
                    x: min(max(dragStart.x + value.translation.width / size.width, 0.06), 0.94),
                    y: min(max(dragStart.y + value.translation.height / size.height, 0.06), 0.94)
                )
            }
            .onEnded { _ in dragStart = markerCenter }
    }

    private var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { markerScale = min(max(scaleStart * $0.magnification, 0.35), 2.2) }
            .onEnded { _ in scaleStart = markerScale }
    }

    private var rotationGesture: some Gesture {
        RotateGesture()
            .onChanged { markerRotation = rotationStart + $0.rotation.degrees }
            .onEnded { _ in rotationStart = markerRotation }
    }

    private func takePicture() {
        isCapturing = true
        statusMessage = "正在拍照…"
        let previewMarkerSize = min(cameraPreviewSize.width, cameraPreviewSize.height)
            * 0.24 * fixedMarkerScale
        let screenPlacement = MarkerPlacement(
            kind: markerEnabled ? markerKind : .none,
            normalizedCenter: fixedPreviewCenter(
                in: cameraPreviewSize,
                markerSize: previewMarkerSize
            ),
            normalizedSize: 0.24 * fixedMarkerScale,
            rotationDegrees: fixedMarkerRotation
        )
        let placement = photoPlacement(from: screenPlacement)

        Task {
            do {
                let source = try await camera.capturePhoto(flashMode: flashMode)
                let result = try ImageProcessor.makeInspectionPhoto(
                    from: source,
                    ratio: photoRatio,
                    outputSize: .large,
                    quarterTurns: 0,
                    marker: placement,
                    caption: captionText
                )
                let saveResult = try await PhotoLibrarySaver.save(result)
                recentPhotos.append(RecentPhoto(id: saveResult.assetIdentifier, image: result))
                captionText = ""
                captionDraft = ""
                isCaptionEditing = false
                speech.stop()
                captionEditorFocused = false
                if recentPhotos.count > 20 {
                    recentPhotos.removeFirst(recentPhotos.count - 20)
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if saveResult.addedToAlbum {
                    statusMessage = markerEnabled
                        ? "已保存带标注照片到 Inspection Photos"
                        : "已保存原始照片到 Inspection Photos"
                } else {
                    statusMessage = "照片已保存；无法加入 Inspection Photos 相册"
                }
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                statusMessage = "保存失败：\(error.localizedDescription)"
            }
            isCapturing = false
            try? await Task.sleep(for: .seconds(2))
            statusMessage = ""
        }
    }

    /// Converts the marker in two stages: portrait preview -> portrait camera
    /// sensor -> selected landscape crop. The second stage is essential because
    /// a landscape result removes a large area from the top and bottom.
    private func photoPlacement(from marker: MarkerPlacement) -> MarkerPlacement {
        guard cameraPreviewSize.width > 0, cameraPreviewSize.height > 0 else { return marker }

        let previewAspect = cameraPreviewSize.width / cameraPreviewSize.height
        let sensorAspect: CGFloat = 3.0 / 4.0
        let photoAspect = photoRatio.value

        // Stage 1: undo AVCaptureVideoPreviewLayer.resizeAspectFill.
        let previewScale = max(previewAspect / sensorAspect, 1)
        let mappedSize = marker.normalizedSize
            * min(previewAspect, 1)
            * photoAspect
            / (previewScale * sensorAspect)

        let finalCenter: CGPoint
        if marker.kind == .arrow {
            // The saved arrow renderer uses 72.5% of the placement size.
            // Position its tip exactly at the center of the landscape result.
            let renderedSize = mappedSize * 0.725
            let radians = fixedMarkerRotation * .pi / 180
            finalCenter = CGPoint(
                x: 0.5 - cos(radians) * renderedSize / (2 * photoAspect),
                y: 0.5 - sin(radians) * renderedSize / 2
            )
        } else if marker.kind == .mosaic {
            finalCenter = CGPoint(x: 0.5, y: 0.35)
        } else {
            finalCenter = CGPoint(x: 0.5, y: 0.5)
        }

        return MarkerPlacement(
            kind: marker.kind,
            normalizedCenter: finalCenter,
            normalizedSize: mappedSize,
            rotationDegrees: fixedMarkerRotation
        )
    }

    private var fixedMarkerScale: CGFloat {
        switch markerKind {
        case .circle, .oval, .square: 2
        case .mosaic: 1.3
        case .arrow: 0.75
        case .dot, .none: 1
        }
    }

    private var fixedMarkerRotation: CGFloat {
        markerKind == .arrow ? -45 : 0
    }

    private func fixedPreviewCenter(in size: CGSize, markerSize: CGFloat) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return CGPoint(x: 0.5, y: 0.5) }
        if markerKind == .mosaic { return CGPoint(x: 0.5, y: 0.35) }
        guard markerKind == .arrow else { return CGPoint(x: 0.5, y: 0.5) }

        let radians = fixedMarkerRotation * .pi / 180
        return CGPoint(
            x: 0.5 - cos(radians) * markerSize / (2 * size.width),
            y: 0.5 - sin(radians) * markerSize / (2 * size.height)
        )
    }

    private func selectMarker(_ kind: MarkerKind) {
        markerKind = kind
        markerEnabled = true
    }
}

#Preview { ContentView() }
