import CoreGraphics
import ImageIO
import XCTest
@testable import ImgDeck

final class PageRendererTests: XCTestCase {
    func testA4PixelSizeSupportsDPIAndDPCM() throws {
        let dpi = try A4Size.pixels(resolution: 72, unit: .dpi)
        let dpcm = try A4Size.pixels(resolution: 72, unit: .dpcm)
        XCTAssertEqual(dpi.width, 595)
        XCTAssertEqual(dpi.height, 842)
        XCTAssertEqual(dpcm.width, 1512)
        XCTAssertEqual(dpcm.height, 2138)
    }

    func testLayoutKeepsUnusedCellsWhite() throws {
        let source = try makeCGImage(width: 620, height: 877, gray: 40)

        let result = try PageRenderer.render(
            images: [source],
            layout: LayoutOption(id: "2x2", rows: 2, columns: 2),
            width: 1240,
            height: 1754
        )

        XCTAssertLessThan(pixel(in: result, x: 100, y: 100), 100)
        XCTAssertEqual(pixel(in: result, x: 1000, y: 100), 255)
        XCTAssertEqual(pixel(in: result, x: 100, y: 1400), 255)
    }

    func testOneCellUsesOnlyFirstImage() throws {
        let first = try makeCGImage(width: 20, height: 20, gray: 30)
        let second = try makeCGImage(width: 20, height: 20, gray: 220)

        let result = try PageRenderer.render(
            images: [first, second],
            layout: LayoutOption(id: "1x1", rows: 1, columns: 1),
            width: 200,
            height: 200
        )
        XCTAssertLessThan(pixel(in: result, x: 100, y: 100), 100)
    }

    func testEncodesPNGAndJPEG() throws {
        let image = try makeCGImage(width: 50, height: 50, gray: 100)
        XCTAssertGreaterThan(try PageRenderer.encodedData(for: image, format: .png).count, 0)
        XCTAssertGreaterThan(try PageRenderer.encodedData(for: image, format: .jpeg).count, 0)
    }

    private func makeCGImage(width: Int, height: Int, gray: UInt8) throws -> CGImage {
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
        context.setFillColor(CGColor(red: CGFloat(gray) / 255, green: CGFloat(gray) / 255, blue: CGFloat(gray) / 255, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw ImgDeckError.contextCreationFailed }
        return image
    }

    private func pixel(in image: CGImage, x: Int, y: Int) -> UInt8 {
        guard let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return 0 }
        let offset = y * image.bytesPerRow + x * 4
        return bytes[offset]
    }
}
