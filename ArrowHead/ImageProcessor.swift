import UIKit

enum ImageProcessor {
    static func makeInspectionPhoto(
        from source: UIImage,
        ratio: PhotoRatio,
        outputSize: PhotoSize,
        quarterTurns: Int,
        marker: MarkerPlacement,
        caption: String = ""
    ) throws -> UIImage {
        let oriented = normalizedImage(source)
        // Standard inspection ratios are landscape. The optional 9:16 ratio
        // is a portrait export for social sharing while the phone stays upright.
        let cropRatio = ratio.value
        let cropped = centerCrop(oriented, ratio: cropRatio)
        let rotated = rotate(cropped, quarterTurns: quarterTurns)

        var requestedDimensions = outputSize.dimensions(for: ratio)
        if quarterTurns.isMultiple(of: 2) == false {
            requestedDimensions = CGSize(
                width: requestedDimensions.height,
                height: requestedDimensions.width
            )
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let transformedMarker = rotateMarker(marker, quarterTurns: quarterTurns)
        return UIGraphicsImageRenderer(size: requestedDimensions, format: format).image { context in
            rotated.draw(in: CGRect(origin: .zero, size: requestedDimensions))
            drawMarker(
                transformedMarker,
                in: context.cgContext,
                canvasSize: requestedDimensions
            )
            drawCaption(caption, canvasSize: requestedDimensions)
        }
    }

    private static func drawCaption(_ caption: String, canvasSize: CGSize) {
        let text = String(
            caption
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(100)
        )
        guard !text.isEmpty else { return }

        let isPortrait = canvasSize.height > canvasSize.width
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byCharWrapping

        let outerInset = max(14, canvasSize.width * 0.018)
        let horizontalPadding = max(44, canvasSize.width * 0.05)
        let verticalPadding = max(28, canvasSize.height * 0.024)
        let maximumBarWidth = canvasSize.width - outerInset * 2
        let availableTextWidth = maximumBarWidth - horizontalPadding * 2
        let maximumTextHeight = canvasSize.height * (isPortrait ? 0.30 : 0.32)
        var fontSize: CGFloat = isPortrait ? 60 : 68
        var measured = CGRect.zero

        while fontSize >= 40 {
            let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
            measured = (text as NSString).boundingRect(
                with: CGSize(width: availableTextWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font, .paragraphStyle: paragraph],
                context: nil
            )
            if measured.height <= maximumTextHeight { break }
            fontSize -= 1
        }

        fontSize = max(fontSize, 40)
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let isSingleLine = measured.height <= font.lineHeight * 1.25
        paragraph.alignment = isSingleLine ? .center : .left
        let barHeight = ceil(measured.height) + verticalPadding * 2
        // Even a one-character note keeps a four-character-wide blue badge.
        // Longer notes grow naturally until they reach the safe photo margin.
        let minimumBarWidth = fontSize * 4 + horizontalPadding * 2
        let naturalBarWidth = ceil(measured.width) + horizontalPadding * 2
        let barWidth = min(maximumBarWidth, max(minimumBarWidth, naturalBarWidth))
        let barRect = CGRect(
            x: (canvasSize.width - barWidth) / 2,
            y: canvasSize.height - outerInset - barHeight,
            width: barWidth,
            height: barHeight
        )
        UIColor.systemBlue.setFill()
        UIBezierPath(
            roundedRect: barRect,
            cornerRadius: max(32, min(barRect.height, barRect.width) * 0.10)
        ).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        let textRect = isSingleLine
            ? CGRect(
                x: barRect.minX + horizontalPadding,
                y: barRect.midY - font.lineHeight / 2,
                width: barRect.width - horizontalPadding * 2,
                height: font.lineHeight
            )
            : barRect.insetBy(dx: horizontalPadding, dy: verticalPadding)
        (text as NSString).draw(
            with: textRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
    }

    private static func normalizedImage(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    private static func centerCrop(_ image: UIImage, ratio: CGFloat) -> UIImage {
        let sourceRatio = image.size.width / image.size.height
        let cropRect: CGRect

        if sourceRatio > ratio {
            let width = image.size.height * ratio
            cropRect = CGRect(
                x: (image.size.width - width) / 2,
                y: 0,
                width: width,
                height: image.size.height
            )
        } else {
            let height = image.size.width / ratio
            cropRect = CGRect(
                x: 0,
                y: (image.size.height - height) / 2,
                width: image.size.width,
                height: height
            )
        }

        guard
            let cgImage = image.cgImage,
            let cropped = cgImage.cropping(to: cropRect.integral)
        else {
            return image
        }
        return UIImage(cgImage: cropped, scale: 1, orientation: .up)
    }

    private static func rotate(_ image: UIImage, quarterTurns: Int) -> UIImage {
        let turns = ((quarterTurns % 4) + 4) % 4
        guard turns != 0 else { return image }

        let outputSize = turns.isMultiple(of: 2)
            ? image.size
            : CGSize(width: image.size.height, height: image.size.width)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            let cg = context.cgContext
            cg.translateBy(x: outputSize.width / 2, y: outputSize.height / 2)
            cg.rotate(by: CGFloat(turns) * .pi / 2)
            image.draw(
                in: CGRect(
                    x: -image.size.width / 2,
                    y: -image.size.height / 2,
                    width: image.size.width,
                    height: image.size.height
                )
            )
        }
    }

    private static func drawMarker(
        _ marker: MarkerPlacement,
        in context: CGContext,
        canvasSize: CGSize
    ) {
        guard marker.kind != .none else { return }

        let center = CGPoint(
            x: marker.normalizedCenter.x * canvasSize.width,
            y: marker.normalizedCenter.y * canvasSize.height
        )
        let baseSize = marker.normalizedSize * min(canvasSize.width, canvasSize.height)
        let sizeMultiplier: CGFloat
        switch marker.kind {
        case .oval:
            // 33% smaller than the previous saved-photo oval (2.0 × 0.67).
            sizeMultiplier = 1.34
        case .circle, .square, .mosaic:
            // Half the size of their previous saved-photo versions.
            sizeMultiplier = 1
        case .arrow:
            // Half the size of the previous enlarged photo arrow.
            sizeMultiplier = 0.725
        case .none, .dot:
            sizeMultiplier = 1
        }
        let size = baseSize * sizeMultiplier
        let half = size / 2

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: marker.rotationDegrees * .pi / 180)
        context.setStrokeColor(UIColor.systemRed.cgColor)
        context.setFillColor(UIColor.systemRed.cgColor)
        let lineWidth = marker.kind == .arrow
            ? max(8, size * 0.10)
            : max(4, baseSize * 0.045)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch marker.kind {
        case .none:
            break
        case .dot:
            let dotSize = size * 0.24
            context.fillEllipse(
                in: CGRect(
                    x: -dotSize / 2,
                    y: -dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
            )
        case .circle:
            context.strokeEllipse(
                in: CGRect(x: -half, y: -half, width: size, height: size)
            )
        case .oval:
            context.strokeEllipse(
                in: CGRect(x: -half, y: -size * 0.31, width: size, height: size * 0.62)
            )
        case .square:
            context.stroke(
                CGRect(x: -half, y: -half, width: size, height: size)
            )
        case .mosaic:
            let mosaicRect = CGRect(
                x: -size * 0.28,
                y: -size * 0.425,
                width: size * 0.56,
                height: size * 0.85
            )
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            context.saveGState()
            context.addEllipse(in: mosaicRect)
            context.clip()
            let colors: [UIColor] = [
                UIColor(red: 0.91, green: 0.78, blue: 0.68, alpha: 1),
                UIColor(red: 0.96, green: 0.72, blue: 0.58, alpha: 1),
                UIColor(red: 0.98, green: 0.95, blue: 0.86, alpha: 1),
                UIColor(red: 0.91, green: 0.84, blue: 0.72, alpha: 1),
                UIColor(red: 0.78, green: 0.69, blue: 0.58, alpha: 1)
            ]
            let columns = 3
            let rows = 5
            let tileWidth = mosaicRect.width / CGFloat(columns)
            let tileHeight = mosaicRect.height / CGFloat(rows)
            let pattern = [1, 3, 0, 2, 4, 3, 0, 1, 2, 4, 3, 0, 4, 2, 1]
            for row in 0..<rows {
                for column in 0..<columns {
                    let index = row * columns + column
                    context.setFillColor(colors[pattern[index]].cgColor)
                    context.fill(CGRect(
                        x: mosaicRect.minX + CGFloat(column) * tileWidth,
                        y: mosaicRect.minY + CGFloat(row) * tileHeight,
                        width: tileWidth + 1,
                        height: tileHeight + 1
                    ))
                }
            }
            context.restoreGState()

            // Fade the last 18% of the ellipse so the mosaic has no hard edge.
            context.saveGState()
            context.setBlendMode(.destinationIn)
            context.scaleBy(x: 0.56, y: 0.85)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: [UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor] as CFArray,
                locations: [0, 0.82, 1]
            ) {
                context.drawRadialGradient(
                    gradient,
                    startCenter: .zero,
                    startRadius: 0,
                    endCenter: .zero,
                    endRadius: size / 2,
                    options: [.drawsBeforeStartLocation]
                )
            }
            context.restoreGState()
            context.endTransparencyLayer()
        case .arrow:
            // The system symbol gives the saved photo a balanced, rounded,
            // solid arrow instead of the old three-segment line drawing.
            let configuration = UIImage.SymbolConfiguration(
                pointSize: size,
                weight: .black,
                scale: .large
            )
            if let arrow = UIImage(systemName: "arrow.right", withConfiguration: configuration)?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal) {
                arrow.draw(in: CGRect(x: -half, y: -half, width: size, height: size))
            }
        }

        context.restoreGState()
    }

    private static func rotateMarker(
        _ marker: MarkerPlacement,
        quarterTurns: Int
    ) -> MarkerPlacement {
        let turns = ((quarterTurns % 4) + 4) % 4
        let point: CGPoint

        switch turns {
        case 1:
            point = CGPoint(
                x: 1 - marker.normalizedCenter.y,
                y: marker.normalizedCenter.x
            )
        case 2:
            point = CGPoint(
                x: 1 - marker.normalizedCenter.x,
                y: 1 - marker.normalizedCenter.y
            )
        case 3:
            point = CGPoint(
                x: marker.normalizedCenter.y,
                y: 1 - marker.normalizedCenter.x
            )
        default:
            point = marker.normalizedCenter
        }

        return MarkerPlacement(
            kind: marker.kind,
            normalizedCenter: point,
            normalizedSize: marker.normalizedSize,
            rotationDegrees: marker.rotationDegrees + CGFloat(turns * 90)
        )
    }
}
