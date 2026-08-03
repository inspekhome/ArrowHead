import SwiftUI

struct MarkerOverlay: View {
    let kind: MarkerKind
    let size: CGFloat
    let rotationDegrees: CGFloat
    var guideOnly = false

    var body: some View {
        Group {
            if guideOnly {
                guideMarker
            } else {
                marker
            }
        }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotationDegrees))
            .shadow(color: .black.opacity(0.7), radius: 2)
            .accessibilityHidden(true)
    }

    private var guideMarker: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            let center = CGPoint(x: width / 2, y: height / 2)
            let lineWidth = max(3, width * 0.035)
            let style = StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: [max(7, width * 0.08), max(6, width * 0.055)]
            )
            var path = Path()

            switch kind {
            case .none:
                return
            case .dot:
                let dotSize = width * 0.24
                path.addEllipse(in: CGRect(
                    x: center.x - dotSize / 2,
                    y: center.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                ))
            case .circle:
                path.addEllipse(in: CGRect(
                    x: lineWidth,
                    y: lineWidth,
                    width: width - lineWidth * 2,
                    height: height - lineWidth * 2
                ))
            case .oval:
                let ovalHeight = height * 0.62
                path.addEllipse(in: CGRect(
                    x: lineWidth,
                    y: center.y - ovalHeight / 2,
                    width: width - lineWidth * 2,
                    height: ovalHeight
                ))
            case .square:
                path.addRect(CGRect(
                    x: lineWidth,
                    y: lineWidth,
                    width: width - lineWidth * 2,
                    height: height - lineWidth * 2
                ))
            case .mosaic:
                let mosaicWidth = width * 0.56
                let mosaicHeight = height * 0.85
                path.addEllipse(in: CGRect(
                    x: center.x - mosaicWidth / 2,
                    y: center.y - mosaicHeight / 2,
                    width: mosaicWidth,
                    height: mosaicHeight
                ))
            case .arrow:
                path.move(to: CGPoint(x: 0, y: center.y))
                path.addLine(to: CGPoint(x: width, y: center.y))
                path.move(to: CGPoint(x: width, y: center.y))
                path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.22))
                path.move(to: CGPoint(x: width, y: center.y))
                path.addLine(to: CGPoint(x: width * 0.68, y: height * 0.78))
            }

            context.stroke(path, with: .color(.white.opacity(0.82)), style: style)
        }
    }

    @ViewBuilder
    private var marker: some View {
        switch kind {
        case .none:
            EmptyView()
        case .arrow, .dot:
            ChasingLightMarker(kind: kind, size: size)
        case .circle:
            Circle()
                .stroke(.red, lineWidth: max(5, size * 0.045))
        case .oval:
            AmberSegmentedOval(size: size)
        case .square:
            BidirectionalSquareLights(size: size)
        case .mosaic:
            MosaicEllipse()
                .frame(width: size * 0.56, height: size * 0.85)
        }
    }
}

private struct ChasingLightMarker: View {
    let kind: MarkerKind
    let size: CGFloat
    private let lightCount = 10
    private let baseRed = Color(red: 0.62, green: 0.0, blue: 0.0)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.08)) { timeline in
            let activeLight = Int(
                timeline.date.timeIntervalSinceReferenceDate / 0.105
            ) % lightCount

            ZStack {
                markerShape(color: baseRed)

                HStack(spacing: size * 0.014) {
                    ForEach(0..<lightCount, id: \.self) { index in
                        let distance = (activeLight - index + lightCount) % lightCount
                        RoundedRectangle(cornerRadius: size * 0.018)
                            .fill(Color(red: 1.0, green: 0.0, blue: 0.0))
                            .frame(width: size * 0.082, height: size * 0.96)
                            .opacity(distance == 0 ? 1 : (distance == 1 ? 0.58 : 0.20))
                            .brightness(distance == 0 ? 0.22 : 0)
                            .shadow(
                                color: distance == 0
                                    ? Color(red: 1.0, green: 0.0, blue: 0.0).opacity(0.95)
                                    : .clear,
                                radius: distance == 0 ? size * 0.055 : 0
                            )
                    }
                }
                .frame(width: size)
                .mask {
                    markerShape(color: .white)
                }
            }
        }
    }

    @ViewBuilder
    private func markerShape(color: Color) -> some View {
        switch kind {
        case .arrow:
            Image(systemName: "arrow.right")
                .resizable()
                .scaledToFit()
                .fontWeight(.black)
                .foregroundStyle(color)
        case .dot:
            Circle()
                .fill(color)
                .frame(width: size * 0.24, height: size * 0.24)
        case .circle:
            Circle()
                .stroke(color, lineWidth: max(5, size * 0.045))
        case .oval:
            Ellipse()
                .stroke(color, lineWidth: max(5, size * 0.045))
                .frame(width: size, height: size * 0.62)
        case .square:
            Rectangle()
                .stroke(color, lineWidth: max(5, size * 0.045))
        case .none, .mosaic:
            EmptyView()
        }
    }
}

private struct BidirectionalSquareLights: View {
    let size: CGFloat
    private let lightCount = 12
    private let baseRed = Color(red: 0.58, green: 0.0, blue: 0.0)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.08)) { timeline in
            let phase = Int(
                timeline.date.timeIntervalSinceReferenceDate / 0.105
            ) % lightCount
            let forwardHeads = [phase, (phase + lightCount / 2) % lightCount]
            let reversePhase = (lightCount - 1 - phase + lightCount) % lightCount
            let reverseHeads = [reversePhase, (reversePhase + lightCount / 2) % lightCount]

            ZStack {
                squareShape(color: baseRed)

                HStack(spacing: size * 0.012) {
                    ForEach(0..<lightCount, id: \.self) { index in
                        let forwardDistance = forwardHeads
                            .map { ($0 - index + lightCount) % lightCount }
                            .min() ?? lightCount
                        let reverseDistance = reverseHeads
                            .map { (index - $0 + lightCount) % lightCount }
                            .min() ?? lightCount
                        let distance = min(forwardDistance, reverseDistance)

                        RoundedRectangle(cornerRadius: size * 0.016)
                            .fill(.red)
                            .frame(width: size * 0.064, height: size * 0.96)
                            .opacity(distance == 0 ? 1 : (distance == 1 ? 0.55 : 0.13))
                            .brightness(distance == 0 ? 0.24 : 0)
                            .shadow(
                                color: distance == 0 ? Color.red.opacity(0.95) : .clear,
                                radius: distance == 0 ? size * 0.055 : 0
                            )
                    }
                }
                .frame(width: size)
                .mask { squareShape(color: .white) }
            }
        }
    }

    private func squareShape(color: Color) -> some View {
        Rectangle()
            .stroke(color, lineWidth: max(5, size * 0.045))
    }
}

private struct AmberSegmentedOval: View {
    let size: CGFloat
    private let lightCount = 12
    private let amber = Color(red: 1.0, green: 0.31, blue: 0.0)
    private let baseAmber = Color(red: 0.62, green: 0.16, blue: 0.0)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { timeline in
            let forwardLight = Int(
                timeline.date.timeIntervalSinceReferenceDate / 0.14
            ) % lightCount
            let reverseLight = lightCount - 1 - forwardLight

            ZStack {
                ovalShape(color: baseAmber)

                HStack(spacing: size * 0.012) {
                    ForEach(0..<lightCount, id: \.self) { index in
                        let forwardDistance = (forwardLight - index + lightCount) % lightCount
                        let reverseDistance = (index - reverseLight + lightCount) % lightCount
                        let distance = min(forwardDistance, reverseDistance)
                        let lightColor = index.isMultiple(of: 2) ? amber : Color.white

                        RoundedRectangle(cornerRadius: size * 0.016)
                            .fill(lightColor)
                            .frame(width: size * 0.064, height: size * 0.60)
                            .opacity(distance == 0 ? 1 : (distance == 1 ? 0.52 : 0.12))
                            .brightness(distance == 0 ? 0.18 : 0)
                            .shadow(
                                color: distance == 0 ? lightColor.opacity(0.95) : .clear,
                                radius: distance == 0 ? size * 0.055 : 0
                            )
                    }
                }
                .frame(width: size)
                .mask { ovalShape(color: .white) }
            }
        }
    }

    private func ovalShape(color: Color) -> some View {
        Ellipse()
            .stroke(color, lineWidth: max(5, size * 0.045))
            .frame(width: size, height: size * 0.62)
    }
}

private struct MosaicEllipse: View {
    private let colors: [Color] = [
        Color(red: 0.91, green: 0.78, blue: 0.68), // light skin
        Color(red: 0.96, green: 0.72, blue: 0.58), // peach skin
        Color(red: 0.98, green: 0.95, blue: 0.86), // ivory
        Color(red: 0.91, green: 0.84, blue: 0.72), // light beige
        Color(red: 0.78, green: 0.69, blue: 0.58)  // neutral beige
    ]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, _ in
                let columns = 3
                let rows = 5
                let tileWidth = geometry.size.width / CGFloat(columns)
                let tileHeight = geometry.size.height / CGFloat(rows)
                let pattern = [1, 3, 0, 2, 4, 3, 0, 1, 2, 4, 3, 0, 4, 2, 1]
                for row in 0..<rows {
                    for column in 0..<columns {
                        let index = row * columns + column
                        let rect = CGRect(
                            x: CGFloat(column) * tileWidth,
                            y: CGFloat(row) * tileHeight,
                            width: tileWidth + 0.5,
                            height: tileHeight + 0.5
                        )
                        context.fill(Path(rect), with: .color(colors[pattern[index]]))
                    }
                }
            }
        }
        .mask(Ellipse().blur(radius: 7))
    }

}
