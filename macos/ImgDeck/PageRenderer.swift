import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum PageRenderer {
    static func render(
        imageURLs: [URL],
        layout: LayoutOption,
        width: Int,
        height: Int
    ) throws -> CGImage {
        let cellWidth = width / layout.columns
        let cellHeight = height / layout.rows
        let images = try imageURLs.prefix(layout.capacity).map { url in
            guard let image = loadImage(at: url, maximumDimension: max(cellWidth, cellHeight)) else {
                throw ImgDeckError.imageReadFailed(url.lastPathComponent)
            }
            return image
        }
        return try render(images: images, layout: layout, width: width, height: height)
    }

    static func render(
        images: [CGImage],
        layout: LayoutOption,
        width: Int,
        height: Int
    ) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImgDeckError.contextCreationFailed
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high

        for (index, image) in images.prefix(layout.capacity).enumerated() {
            let row = index / layout.columns
            let column = index % layout.columns
            let x1 = width * column / layout.columns
            let x2 = width * (column + 1) / layout.columns
            let y1 = height * row / layout.rows
            let y2 = height * (row + 1) / layout.rows
            let cellWidth = x2 - x1
            let cellHeight = y2 - y1

            let scale = min(
                CGFloat(cellWidth) / CGFloat(image.width),
                CGFloat(cellHeight) / CGFloat(image.height)
            )
            let drawWidth = min(cellWidth, max(1, Int((CGFloat(image.width) * scale).rounded())))
            let drawHeight = min(cellHeight, max(1, Int((CGFloat(image.height) * scale).rounded())))
            let drawX = x1 + (cellWidth - drawWidth) / 2
            let imageTop = y1 + (cellHeight - drawHeight) / 2
            let drawY = height - imageTop - drawHeight

            context.draw(
                image,
                in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
            )
        }

        guard let result = context.makeImage() else {
            throw ImgDeckError.contextCreationFailed
        }
        return result
    }

    static func encodedData(for image: CGImage, format: OutputFormat) throws -> Data {
        let data = NSMutableData()
        let type: UTType = format == .png ? .png : .jpeg
        guard let destination = CGImageDestinationCreateWithData(
            data,
            type.identifier as CFString,
            1,
            nil
        ) else {
            throw ImgDeckError.exportFailed
        }

        let properties: CFDictionary?
        if format == .jpeg {
            properties = [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary
        } else {
            properties = nil
        }
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            throw ImgDeckError.exportFailed
        }
        return data as Data
    }

    private static func loadImage(at url: URL, maximumDimension: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maximumDimension),
            kCGImageSourceShouldCacheImmediately: true,
        ] as CFDictionary
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }
}
