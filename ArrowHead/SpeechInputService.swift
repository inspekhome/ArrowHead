import AVFoundation
import Speech

@MainActor
final class SpeechInputService: ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var errorMessage = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func toggle(onText: @escaping (String) -> Void) {
        if isListening {
            stop()
        } else {
            requestPermissionAndStart(onText: onText)
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestPermissionAndStart(onText: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] speechStatus in
            AVAudioApplication.requestRecordPermission { microphoneAllowed in
                Task { @MainActor in
                    guard let self else { return }
                    guard speechStatus == .authorized, microphoneAllowed else {
                        self.errorMessage = "请在设置中允许麦克风和语音识别权限"
                        return
                    }
                    self.start(onText: onText)
                }
            }
        }
    }

    private func start(onText: @escaping (String) -> Void) {
        stop()
        errorMessage = ""

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let newRequest = SFSpeechAudioBufferRecognitionRequest()
            newRequest.shouldReportPartialResults = true
            request = newRequest

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                newRequest.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true

            task = recognizer?.recognitionTask(with: newRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let result {
                        onText(result.bestTranscription.formattedString)
                        if result.isFinal { self.stop() }
                    } else if error != nil {
                        self.stop()
                    }
                }
            }
        } catch {
            errorMessage = "无法开始语音输入"
            stop()
        }
    }

    deinit {
        audioEngine.stop()
    }
}
