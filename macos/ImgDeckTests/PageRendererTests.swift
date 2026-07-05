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

    func testLayoutKeepsAnEmptyMiddleSlotWhite() throws {
        let first = try makeCGImage(width: 20, height: 20, gray: 30)
        let third = try makeCGImage(width: 20, height: 20, gray: 80)

        let result = try PageRenderer.render(
            imageSlots: [first, nil, third],
            layout: LayoutOption(id: "1x3", rows: 1, columns: 3),
            width: 300,
            height: 100
        )

        XCTAssertLessThan(pixel(in: result, x: 50, y: 50), 100)
        XCTAssertEqual(pixel(in: result, x: 150, y: 50), 255)
        XCTAssertLessThan(pixel(in: result, x: 250, y: 50), 100)
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

    func testDefaultTransformFitsWithoutCropping() throws {
        let source = try makeCGImage(width: 200, height: 100, gray: 40)
        let result = try PageRenderer.render(
            images: [source],
            transforms: [.identity],
            layout: LayoutOption(id: "1x1", rows: 1, columns: 1),
            width: 200,
            height: 200
        )
        XCTAssertEqual(pixel(in: result, x: 10, y: 10), 255)
        XCTAssertLessThan(pixel(in: result, x: 100, y: 100), 100)
    }

    func testImageContentIsClippedToItsCell() throws {
        let source = try makeCGImage(width: 100, height: 100, gray: 30)
        let transform = ImageTransform(offsetX: 0.75, offsetY: 0, scaleX: 2, scaleY: 2)
        let result = try PageRenderer.render(
            images: [source],
            transforms: [transform],
            layout: LayoutOption(id: "1x2", rows: 1, columns: 2),
            width: 200,
            height: 100
        )
        XCTAssertLessThan(pixel(in: result, x: 90, y: 50), 100)
        XCTAssertEqual(pixel(in: result, x: 110, y: 50), 255)
    }

    func testScalingModesStoreIndependentDimensions() {
        var proportional = ImageTransform.identity
        proportional.scaleX = 1.5
        proportional.scaleY = 1.5
        XCTAssertEqual(proportional.scaleX, proportional.scaleY)

        var free = ImageTransform.identity
        free.scalingMode = .free
        free.scaleX = 1.5
        free.scaleY = 0.75
        XCTAssertNotEqual(free.scaleX, free.scaleY)
    }

    func testEncodesPNGAndJPEG() throws {
        let image = try makeCGImage(width: 50, height: 50, gray: 100)
        XCTAssertGreaterThan(try PageRenderer.encodedData(for: image, format: .png).count, 0)
        XCTAssertGreaterThan(try PageRenderer.encodedData(for: image, format: .jpeg).count, 0)
    }

    func testInterfaceStringsSupportAllLanguages() {
        XCTAssertEqual(AppStrings(language: .simplifiedChinese).settingsTitle, "设置")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).settingsTitle, "設定")
        XCTAssertEqual(AppStrings(language: .english).settingsTitle, "Settings")
        XCTAssertEqual(AppStrings(language: .english).unitName(.dpi), "Dots per inch")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).resetImage, "重設目前圖片")
        XCTAssertEqual(AppStrings(language: .english).undoHint, "Undo the last adjustment (⌘Z)")
    }

    func testErrorsFollowSelectedLanguage() {
        let error = ImgDeckError.imageReadFailed("sample.png")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).errorMessage(error), "無法讀取圖片：sample.png")
        XCTAssertEqual(AppStrings(language: .english).errorMessage(error), "Unable to read image: sample.png")
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

@MainActor
final class ImageDeckViewModelTests: XCTestCase {
    func testMovingIntoEmptySlotAndOccupiedSlot() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/first.png"), URL(fileURLWithPath: "/tmp/second.png")])

        let firstID = viewModel.slots[0]?.id
        let secondID = viewModel.slots[1]?.id
        viewModel.selectedID = firstID
        let transform = ImageTransform(offsetX: 0.25, offsetY: -0.1, scaleX: 1.5, scaleY: 1.5)
        viewModel.updateTransform(transform, for: firstID!)
        viewModel.moveSelected(by: 1)
        XCTAssertEqual(viewModel.slots[0]?.id, secondID)
        XCTAssertEqual(viewModel.slots[1]?.id, firstID)
        XCTAssertEqual(viewModel.transform(for: firstID!), transform)

        viewModel.moveSelected(by: 1)
        XCTAssertNil(viewModel.slots[1])
        XCTAssertEqual(viewModel.slots[2]?.id, firstID)
    }

    func testRemovingLeavesGapAndAddingFillsFirstGap() {
        let viewModel = ImageDeckViewModel()
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/first.png"), URL(fileURLWithPath: "/tmp/second.png")])
        let secondID = viewModel.slots[1]?.id

        viewModel.selectedID = viewModel.slots[0]?.id
        viewModel.removeSelected()
        XCTAssertNil(viewModel.slots[0])
        XCTAssertEqual(viewModel.slots[1]?.id, secondID)

        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/replacement.png")])
        XCTAssertEqual(viewModel.slots[0]?.url.lastPathComponent, "replacement.png")
        XCTAssertEqual(viewModel.slots[1]?.id, secondID)
    }

    func testImportNeverExceedsRemainingSlots() {
        let viewModel = ImageDeckViewModel()
        let firstEight = (0..<8).map { URL(fileURLWithPath: "/tmp/\($0).png") }
        XCTAssertEqual(viewModel.addImages(from: firstEight), 8)
        XCTAssertEqual(
            viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/ninth.png"), URL(fileURLWithPath: "/tmp/tenth.png")]),
            1
        )
        XCTAssertEqual(viewModel.imageCount, 9)
        XCTAssertNotNil(viewModel.alert)
        XCTAssertEqual(viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/eleventh.png")]), 0)
    }

    func testImportWrapsFromTheSlotAfterSelection() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: (1...4).map { URL(fileURLWithPath: "/tmp/existing-\($0).png") })
        viewModel.selectedID = viewModel.slots[3]?.id
        viewModel.moveSelected(by: 1)
        viewModel.moveSelected(by: 1)
        XCTAssertEqual(viewModel.slots[5]?.url.lastPathComponent, "existing-4.png")

        viewModel.addImages(from: (1...5).map { URL(fileURLWithPath: "/tmp/new-\($0).png") })

        XCTAssertEqual(viewModel.slots[6]?.url.lastPathComponent, "new-1.png")
        XCTAssertEqual(viewModel.slots[7]?.url.lastPathComponent, "new-2.png")
        XCTAssertEqual(viewModel.slots[8]?.url.lastPathComponent, "new-3.png")
        XCTAssertEqual(viewModel.slots[3]?.url.lastPathComponent, "new-4.png")
        XCTAssertEqual(viewModel.slots[4]?.url.lastPathComponent, "new-5.png")
    }

    func testImportWrapsAfterNinthSlotAndStartsAtFirstWithoutSelection() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/ninth.png")])
        for _ in 0..<8 { viewModel.moveSelected(by: 1) }
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/first.png")])
        XCTAssertEqual(viewModel.slots[0]?.url.lastPathComponent, "first.png")

        let unselectedViewModel = ImageDeckViewModel()
        unselectedViewModel.addImages(from: [URL(fileURLWithPath: "/tmp/first-without-selection.png")])
        XCTAssertEqual(unselectedViewModel.slots[0]?.url.lastPathComponent, "first-without-selection.png")
    }

    func testRemainingCapacityAndLocalizedGroupTitle() {
        let viewModel = ImageDeckViewModel()
        XCTAssertEqual(viewModel.remainingCapacity, 9)
        viewModel.addImages(from: (1...4).map { URL(fileURLWithPath: "/tmp/\($0).png") })
        XCTAssertEqual(viewModel.remainingCapacity, 5)
        XCTAssertEqual(AppStrings(language: .simplifiedChinese).imagesAndLayout(remaining: 5), "图片与版式（可导入5张）")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).imagesAndLayout(remaining: 5), "圖片與版式（可匯入5張）")
        XCTAssertEqual(AppStrings(language: .english).imagesAndLayout(remaining: 5), "Images & Layout (5 available)")
    }

    func testSwitchingToSmallerLayoutPreservesHiddenSlot() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/image.png")])
        let imageID = viewModel.slots[0]?.id
        viewModel.selectedID = imageID
        for _ in 0..<8 { viewModel.moveSelected(by: 1) }

        viewModel.selectLayout(LayoutOption(id: "2x2", rows: 2, columns: 2))
        XCTAssertEqual(viewModel.slots[8]?.id, imageID)
        XCTAssertTrue(viewModel.canMoveUp)
        XCTAssertFalse(viewModel.canMoveDown)

        for _ in 0..<5 { viewModel.moveSelected(by: -1) }
        XCTAssertEqual(viewModel.slots[3]?.id, imageID)
    }
}
