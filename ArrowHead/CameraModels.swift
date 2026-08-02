import CoreGraphics
import SwiftUI
import AVFoundation

enum MarkerKind: String, CaseIterable, Identifiable {
    case none = "None"
    case arrow = "Arrow"
    case dot = "Dot"
    case circle = "Circle"
    case oval = "Oval"
    case square = "Square"
    case mosaic = "Mosaic"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .none: "nosign"
        case .arrow: "arrow.right"
        case .dot: "circle.fill"
        case .circle: "circle"
        case .oval: "oval"
        case .square: "square"
        case .mosaic: "square.grid.3x3.fill"
        }
    }
}

enum PhotoRatio: String, CaseIterable, Identifiable {
    case fourThree = "4:3"
    case square = "1:1"
    case sixteenNine = "16:9"
    case nineSixteen = "9:16"

    var id: String { rawValue }

    var value: CGFloat {
        switch self {
        case .fourThree: 4.0 / 3.0
        case .square: 1
        case .sixteenNine: 16.0 / 9.0
        case .nineSixteen: 9.0 / 16.0
        }
    }
}

enum PhotoSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case large = "Large"

    var id: String { rawValue }

    func dimensions(for ratio: PhotoRatio) -> CGSize {
        switch (ratio, self) {
        case (.sixteenNine, .small): CGSize(width: 640, height: 360)
        case (.sixteenNine, .large): CGSize(width: 1280, height: 720)
        case (.nineSixteen, .small): CGSize(width: 360, height: 640)
        case (.nineSixteen, .large): CGSize(width: 720, height: 1280)
        case (.square, .small): CGSize(width: 640, height: 640)
        case (.square, .large): CGSize(width: 1280, height: 1280)
        case (.fourThree, .small): CGSize(width: 640, height: 480)
        case (.fourThree, .large): CGSize(width: 1280, height: 960)
        }
    }
}

enum CameraFlashMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case on = "On"
    case auto = "Auto"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .off: "bolt.slash.fill"
        case .on: "bolt.fill"
        case .auto: "bolt.badge.automatic.fill"
        }
    }

    var avMode: AVCaptureDevice.FlashMode {
        switch self {
        case .off: .off
        case .on: .on
        case .auto: .auto
        }
    }
}

struct MarkerPlacement {
    let kind: MarkerKind
    let normalizedCenter: CGPoint
    let normalizedSize: CGFloat
    let rotationDegrees: CGFloat
}
