import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum PageRenderer {
    static func render(
        imageURLs: [URL?],
        transforms: [ImageTransform] = [],
        layout: LayoutOption,
        width: Int,
        height: Int
    ) throws -> CGImage {
        let cellWidth = width / layout.columns
        let cellHeight = height / layout.rows
        let images: [CGImage?] = try imageURLs.prefix(layout.capacity).enumerated().map { index, url in
            guard let url else { return nil }
            let transform = transforms.indices.contains(index) ? transforms[index] : .identity
            let maximumScale = max(transform.scaleX, transform.scaleY, 1)
            let maximumDimension = Int(ceil(CGFloat(max(cellWidth, cellHeight)) * maximumScale))
            guard let image = loadImage(at: url, maximumDimension: maximumDimension) else {
                throw ImgDeckError.imageReadFailed(url.lastPathComponent)
            }
            return image
        }
        return try render(imageSlots: images, transforms: transforms, layout: layout, width: width, height: height)
    }

    static func render(
        images: [CGImage],
        transforms: [ImageTransform] = [],
        layout: LayoutOption,
        width: Int,
        height: Int
    ) throws -> CGImage {
        try render(imageSlots: images.map(Optional.some), transforms: transforms, layout: layout, width: width, height: height)
    }

    static func render(
        imageSlots: [CGImage?],
        transforms: [ImageTransform] = [],
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

        for (index, image) in imageSlots.prefix(layout.capacity).enumerated() {
            guard let image else { continue }
            let transform = transforms.indices.contains(index) ? transforms[index] : .identity
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
            let baseWidth = CGFloat(image.width) * scale
            let baseHeight = CGFloat(image.height) * scale
            let drawWidth = max(1, Int((baseWidth * transform.scaleX).rounded()))
            let drawHeight = max(1, Int((baseHeight * transform.scaleY).rounded()))
            let drawX = x1 + (cellWidth - drawWidth) / 2 + Int((transform.offsetX * CGFloat(cellWidth)).rounded())
            let imageTop = y1 + (cellHeight - drawHeight) / 2 + Int((transform.offsetY * CGFloat(cellHeight)).rounded())
            let drawY = height - imageTop - drawHeight

            context.saveGState()
            context.clip(to: CGRect(x: x1, y: height - y2, width: cellWidth, height: cellHeight))
            context.draw(
                image,
                in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
            )
            context.restoreGState()
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
