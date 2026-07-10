import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum PageRenderer {
    static func render(
        imageURLs: [URL?],
        transforms: [ImageTransform] = [],
        mosaics: [MosaicRegion] = [],
        mosaicBlockSize: Int = 40,
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
        return try render(
            imageSlots: images,
            transforms: transforms,
            mosaics: mosaics,
            mosaicBlockSize: mosaicBlockSize,
            layout: layout,
            width: width,
            height: height
        )
    }

    static func render(
        images: [CGImage],
        transforms: [ImageTransform] = [],
        mosaics: [MosaicRegion] = [],
        mosaicBlockSize: Int = 40,
        layout: LayoutOption,
        width: Int,
        height: Int
    ) throws -> CGImage {
        try render(
            imageSlots: images.map(Optional.some),
            transforms: transforms,
            mosaics: mosaics,
            mosaicBlockSize: mosaicBlockSize,
            layout: layout,
            width: width,
            height: height
        )
    }

    static func render(
        imageSlots: [CGImage?],
        transforms: [ImageTransform] = [],
        mosaics: [MosaicRegion] = [],
        mosaicBlockSize: Int = 40,
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
        return applyMosaics(to: result, regions: mosaics, blockSize: mosaicBlockSize)
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

    private static func applyMosaics(to image: CGImage, regions: [MosaicRegion], blockSize: Int) -> CGImage {
        guard !regions.isEmpty,
              let context = CGContext(
                data: nil,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return image }

        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let fullRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let scaledBlockSize = max(2, Int((CGFloat(blockSize.clamped(to: 2...100)) * CGFloat(image.width) / 595).rounded()))

        for region in regions {
            let normalized = region.normalizedRect.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            guard !normalized.isNull, !normalized.isEmpty else { continue }
            let rect = CGRect(
                x: normalized.minX * CGFloat(image.width),
                y: (1 - normalized.maxY) * CGFloat(image.height),
                width: normalized.width * CGFloat(image.width),
                height: normalized.height * CGFloat(image.height)
            ).integral.intersection(fullRect)
            guard !rect.isNull, !rect.isEmpty,
                  let crop = image.cropping(to: rect) else { continue }

            let sampledWidth = max(1, Int(ceil(rect.width / CGFloat(scaledBlockSize))))
            let sampledHeight = max(1, Int(ceil(rect.height / CGFloat(scaledBlockSize))))
            guard let sampledContext = CGContext(
                data: nil,
                width: sampledWidth,
                height: sampledHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { continue }
            sampledContext.interpolationQuality = .medium
            sampledContext.draw(crop, in: CGRect(x: 0, y: 0, width: sampledWidth, height: sampledHeight))
            guard let sampledImage = sampledContext.makeImage() else { continue }

            context.saveGState()
            context.clip(to: rect)
            context.interpolationQuality = .none
            context.draw(sampledImage, in: rect)
            context.restoreGState()
        }

        return context.makeImage() ?? image
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
