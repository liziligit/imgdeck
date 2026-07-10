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

    func testRectangularMosaicPixelatesOnlyItsSelectedArea() throws {
        let source = try makeCheckerboardImage(width: 100, height: 100, tileSize: 2)
        let plain = try PageRenderer.render(
            images: [source],
            layout: LayoutOption(id: "1x1", rows: 1, columns: 1),
            width: 100,
            height: 100
        )
        let mosaicked = try PageRenderer.render(
            images: [source],
            mosaics: [MosaicRegion(normalizedRect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5))],
            mosaicBlockSize: 50,
            layout: LayoutOption(id: "1x1", rows: 1, columns: 1),
            width: 100,
            height: 100
        )

        XCTAssertNotEqual(pixel(in: plain, x: 1, y: 1), pixel(in: plain, x: 3, y: 1))
        XCTAssertEqual(pixel(in: mosaicked, x: 1, y: 1), pixel(in: mosaicked, x: 3, y: 1))
        XCTAssertEqual(pixel(in: mosaicked, x: 75, y: 75), pixel(in: plain, x: 75, y: 75))
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
        XCTAssertEqual(AppStrings(language: .japanese).settingsTitle, "設定")
        XCTAssertEqual(AppStrings(language: .korean).settingsTitle, "설정")
        XCTAssertEqual(AppStrings(language: .english).unitName(.dpi), "Dots per inch")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).resetImage, "重設目前圖片")
        XCTAssertEqual(AppStrings(language: .english).undoHint, "Undo the last adjustment (⌘Z)")
        XCTAssertEqual(AppStrings(language: .english).replaceImageAction, "Replace Image")
        XCTAssertEqual(AppStrings(language: .spanish).replaceImageAction, "Reemplazar imagen")
        XCTAssertEqual(AppStrings(language: .french).dropImageHint, "Faites glisser une image depuis Finder pour placer ou remplacer cette case")
        XCTAssertEqual(AppLanguage.allCases.map(\.displayName), ["简体中文", "繁體中文", "English", "日本語", "한국어", "Español", "Français", "Deutsch", "Português (Brasil)"])
        XCTAssertEqual(AppStrings(language: .spanish).settingsTitle, "Ajustes")
        XCTAssertEqual(AppStrings(language: .french).settingsTitle, "Réglages")
        XCTAssertEqual(AppStrings(language: .german).settingsTitle, "Einstellungen")
        XCTAssertEqual(AppStrings(language: .portugueseBrazil).settingsTitle, "Ajustes")
        XCTAssertEqual(AppStrings(language: .spanish).appSubtitle, "Elige de 1 a 9 imágenes y un diseño; muévelas a cualquier celda.\nLas celdas sin usar permanecen blancas.")
        XCTAssertEqual(AppStrings(language: .french).appSubtitle, "Choisissez 1 à 9 images et placez-les dans la case voulue.\nLes cases inutilisées restent blanches.")
        XCTAssertEqual(AppStrings(language: .portugueseBrazil).appSubtitle, "Escolha de 1 a 9 imagens e mova-as para qualquer espaço.\nOs espaços não usados permanecem brancos.")
        XCTAssertEqual(AppStrings(language: .german).appSubtitle, "Wähle 1–9 Bilder und verschiebe sie in beliebige freie Felder.\nUngenutzte Felder bleiben weiß.")
    }

    func testErrorsFollowSelectedLanguage() {
        let error = ImgDeckError.imageReadFailed("sample.png")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).errorMessage(error), "無法讀取圖片：sample.png")
        XCTAssertEqual(AppStrings(language: .english).errorMessage(error), "Unable to read image: sample.png")
        XCTAssertEqual(AppStrings(language: .japanese).errorMessage(error), "画像を読み込めません：sample.png")
        XCTAssertEqual(AppStrings(language: .korean).errorMessage(error), "이미지를 읽을 수 없습니다: sample.png")
        XCTAssertEqual(AppStrings(language: .spanish).errorMessage(error), "No se puede leer la imagen: sample.png")
        XCTAssertEqual(AppStrings(language: .french).errorMessage(error), "Impossible de lire l’image : sample.png")
        XCTAssertEqual(AppStrings(language: .german).errorMessage(error), "Bild kann nicht gelesen werden: sample.png")
        XCTAssertEqual(AppStrings(language: .portugueseBrazil).errorMessage(error), "Não foi possível ler a imagem: sample.png")
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

    private func makeCheckerboardImage(width: Int, height: Int, tileSize: Int) throws -> CGImage {
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
        for y in stride(from: 0, to: height, by: tileSize) {
            for x in stride(from: 0, to: width, by: tileSize) {
                let isDark = ((x / tileSize) + (y / tileSize)).isMultiple(of: 2)
                let value: CGFloat = isDark ? 0 : 1
                context.setFillColor(CGColor(red: value, green: value, blue: value, alpha: 1))
                context.fill(CGRect(x: x, y: y, width: tileSize, height: tileSize))
            }
        }
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
    func testDefaultLayoutIsTwoByTwo() {
        let viewModel = ImageDeckViewModel()
        XCTAssertEqual(viewModel.selectedLayout.id, "2x2")
        XCTAssertEqual(viewModel.selectedLayout.capacity, 4)
    }

    func testPreviewZoomChangesInFivePercentStepsAndClamps() {
        let viewModel = ImageDeckViewModel()
        viewModel.adjustPreviewZoom(by: 5)
        XCTAssertEqual(viewModel.previewZoomPercent, 105)
        viewModel.adjustPreviewZoom(by: -5)
        XCTAssertEqual(viewModel.previewZoomPercent, 100)
        viewModel.setPreviewZoomPercent(500)
        XCTAssertEqual(viewModel.previewZoomPercent, 200)
        viewModel.setPreviewZoomPercent(1)
        XCTAssertEqual(viewModel.previewZoomPercent, 25)
    }

    func testMosaicAdditionAndBlockSizeSupportUndoRedo() {
        let viewModel = ImageDeckViewModel()
        let undoManager = UndoManager()
        viewModel.setUndoManager(undoManager)

        XCTAssertFalse(viewModel.canApplyMosaic)
        viewModel.setPendingMosaic(CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
        XCTAssertTrue(viewModel.canApplyMosaic)
        XCTAssertTrue(viewModel.mosaicRegions.isEmpty)
        viewModel.applyPendingMosaic()
        XCTAssertFalse(viewModel.canApplyMosaic)
        XCTAssertEqual(viewModel.mosaicRegions.count, 1)

        viewModel.toggleMosaicMode()
        viewModel.setPendingMosaic(CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2))
        XCTAssertTrue(viewModel.canApplyMosaic)
        viewModel.toggleMosaicMode()
        XCTAssertFalse(viewModel.canApplyMosaic)
        XCTAssertEqual(viewModel.mosaicRegions.count, 1)

        undoManager.undo()
        XCTAssertTrue(viewModel.mosaicRegions.isEmpty)
        XCTAssertTrue(viewModel.canApplyMosaic)
        undoManager.redo()
        XCTAssertEqual(viewModel.mosaicRegions.count, 1)

        XCTAssertEqual(viewModel.mosaicBlockSize, 15)
        viewModel.updateMosaicBlockSize(60)
        viewModel.commitMosaicBlockSizeChange(from: 15)
        XCTAssertEqual(viewModel.mosaicBlockSize, 60)
        undoManager.undo()
        XCTAssertEqual(viewModel.mosaicBlockSize, 15)
        undoManager.redo()
        XCTAssertEqual(viewModel.mosaicBlockSize, 60)
    }

    func testMovingIntoEmptySlotAndOccupiedSlot() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/first.png"), URL(fileURLWithPath: "/tmp/second.png")])

        let firstID = viewModel.slots[0]?.id
        let secondID = viewModel.slots[1]?.id
        viewModel.selectSlot(0)
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

    func testRemovingKeepsEmptySlotSelectedAndImportsAfterIt() {
        let viewModel = ImageDeckViewModel()
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/first.png"), URL(fileURLWithPath: "/tmp/second.png")])
        let secondID = viewModel.slots[1]?.id

        viewModel.selectSlot(0)
        viewModel.removeSelected()
        XCTAssertNil(viewModel.slots[0])
        XCTAssertEqual(viewModel.slots[1]?.id, secondID)

        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/replacement.png")])
        XCTAssertNil(viewModel.slots[0])
        XCTAssertEqual(viewModel.slots[1]?.id, secondID)
        XCTAssertEqual(viewModel.slots[2]?.url.lastPathComponent, "replacement.png")
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
        viewModel.selectSlot(3)
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
        XCTAssertEqual(AppStrings(language: .simplifiedChinese).imagesAndLayout(remaining: 5), "图片与版式（还可导入5张）")
        XCTAssertEqual(AppStrings(language: .traditionalChinese).imagesAndLayout(remaining: 5), "圖片與版式（還可匯入5張）")
        XCTAssertEqual(AppStrings(language: .english).imagesAndLayout(remaining: 5), "Images & Layout (5 more available)")
        XCTAssertEqual(AppStrings(language: .japanese).imagesAndLayout(remaining: 5), "画像とレイアウト（あと5枚追加可能）")
        XCTAssertEqual(AppStrings(language: .korean).imagesAndLayout(remaining: 5), "이미지 및 레이아웃(5장 더 추가 가능)")
        XCTAssertEqual(AppStrings(language: .spanish).imagesAndLayout(remaining: 5), "Imágenes y diseño (se pueden añadir 5 más)")
        XCTAssertEqual(AppStrings(language: .french).imagesAndLayout(remaining: 5), "Images et disposition (encore 5 disponibles)")
        XCTAssertEqual(AppStrings(language: .german).imagesAndLayout(remaining: 5), "Bilder und Layout (noch 5 verfügbar)")
        XCTAssertEqual(AppStrings(language: .portugueseBrazil).imagesAndLayout(remaining: 5), "Imagens e layout (mais 5 disponíveis)")
    }

    func testSelectingAnEmptySlotKeepsSlotSelectionAndImportsAfterIt() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: [
            URL(fileURLWithPath: "/tmp/first.png"),
            URL(fileURLWithPath: "/tmp/second.png")
        ])

        viewModel.selectSlot(4)
        XCTAssertEqual(viewModel.selectedSlotIndex, 4)
        XCTAssertNil(viewModel.selectedID)
        XCTAssertFalse(viewModel.canRemove)
        XCTAssertFalse(viewModel.canMoveUp)
        XCTAssertFalse(viewModel.canMoveDown)

        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/after-empty-selection.png")])
        XCTAssertEqual(viewModel.slots[5]?.url.lastPathComponent, "after-empty-selection.png")
        XCTAssertEqual(viewModel.selectedSlotIndex, 5)
    }

    func testSelectingHiddenEmptySlotPreservesCurrentLayout() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "2x2", rows: 2, columns: 2))
        viewModel.selectSlot(7)

        XCTAssertEqual(viewModel.selectedLayout.id, "2x2")
        XCTAssertEqual(viewModel.selectedSlotIndex, 7)
        XCTAssertNil(viewModel.selectedID)
    }

    func testPreviewGridDropTargetMapsEveryVisibleCell() {
        let oneByOne = PreviewGridDropTarget(cellSize: CGSize(width: 100, height: 100), columns: 1, capacity: 1)
        XCTAssertEqual(oneByOne.cellIndex(for: CGPoint(x: 50, y: 50)), 0)
        XCTAssertNil(oneByOne.cellIndex(for: CGPoint(x: 100, y: 50)))

        let twoByTwo = PreviewGridDropTarget(cellSize: CGSize(width: 100, height: 100), columns: 2, capacity: 4)
        XCTAssertEqual(twoByTwo.cellIndex(for: CGPoint(x: 150, y: 150)), 3)

        let threeByThree = PreviewGridDropTarget(cellSize: CGSize(width: 100, height: 100), columns: 3, capacity: 9)
        XCTAssertEqual(threeByThree.cellIndex(for: CGPoint(x: 250, y: 250)), 8)
        XCTAssertNil(threeByThree.cellIndex(for: CGPoint(x: 300, y: 250)))
        XCTAssertNil(threeByThree.cellIndex(for: CGPoint(x: -1, y: 0)))
    }

    func testSwitchingToSmallerLayoutPreservesHiddenSlot() {
        let viewModel = ImageDeckViewModel()
        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/image.png")])
        let imageID = viewModel.slots[0]?.id
        viewModel.selectSlot(0)
        for _ in 0..<8 { viewModel.moveSelected(by: 1) }

        viewModel.selectLayout(LayoutOption(id: "2x2", rows: 2, columns: 2))
        XCTAssertEqual(viewModel.slots[8]?.id, imageID)
        XCTAssertTrue(viewModel.canMoveUp)
        XCTAssertFalse(viewModel.canMoveDown)

        for _ in 0..<5 { viewModel.moveSelected(by: -1) }
        XCTAssertEqual(viewModel.slots[3]?.id, imageID)
    }

    func testReplacingOccupiedSlotUsesFirstURLAndSupportsUndoRedo() throws {
        let viewModel = ImageDeckViewModel()
        let undoManager = UndoManager()
        viewModel.setUndoManager(undoManager)
        viewModel.addImages(from: [URL(fileURLWithPath: "/tmp/original.png")])
        let original = try XCTUnwrap(viewModel.slots[0])
        let originalTransform = ImageTransform(offsetX: 0.2, offsetY: -0.15, scaleX: 1.4, scaleY: 1.4)
        viewModel.updateTransform(originalTransform, for: original.id)

        let firstURL = try makeTemporaryImageURL(gray: 60)
        let secondURL = try makeTemporaryImageURL(gray: 180)
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }

        XCTAssertTrue(viewModel.replaceImage(at: 0, with: [firstURL, secondURL]))
        let replacement = try XCTUnwrap(viewModel.slots[0])
        XCTAssertEqual(replacement.url, firstURL)
        XCTAssertNotEqual(replacement.url, secondURL)
        XCTAssertEqual(viewModel.selectedID, replacement.id)
        XCTAssertEqual(viewModel.transform(for: replacement.id), .identity)

        undoManager.undo()
        XCTAssertEqual(viewModel.slots[0]?.id, original.id)
        XCTAssertEqual(viewModel.transform(for: original.id), originalTransform)
        XCTAssertEqual(viewModel.selectedID, original.id)

        undoManager.redo()
        XCTAssertEqual(viewModel.slots[0]?.url, firstURL)
        XCTAssertEqual(viewModel.selectedID, replacement.id)
    }

    func testReplacingEmptySlotAndInvalidURL() throws {
        let viewModel = ImageDeckViewModel()
        let undoManager = UndoManager()
        viewModel.setUndoManager(undoManager)
        let imageURL = try makeTemporaryImageURL(gray: 120)
        defer { try? FileManager.default.removeItem(at: imageURL) }

        XCTAssertTrue(viewModel.replaceImage(at: 3, with: [imageURL]))
        XCTAssertEqual(viewModel.slots[3]?.url, imageURL)
        XCTAssertEqual(viewModel.imageCount, 1)
        undoManager.undo()
        XCTAssertNil(viewModel.slots[3])
        XCTAssertEqual(viewModel.imageCount, 0)

        XCTAssertFalse(viewModel.replaceImage(at: 3, with: URL(fileURLWithPath: "/tmp/not-an-image.txt")))
        XCTAssertNil(viewModel.slots[3])
    }

    func testReplacingVisibleSlotsSelectsTheirTarget() throws {
        let viewModel = ImageDeckViewModel()
        let firstURL = try makeTemporaryImageURL(gray: 30)
        let secondURL = try makeTemporaryImageURL(gray: 90)
        let thirdURL = try makeTemporaryImageURL(gray: 150)
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
            try? FileManager.default.removeItem(at: thirdURL)
        }

        viewModel.selectLayout(LayoutOption(id: "1x1", rows: 1, columns: 1))
        XCTAssertTrue(viewModel.replaceImage(at: 0, with: firstURL))
        XCTAssertEqual(viewModel.selectedSlotIndex, 0)

        viewModel.selectLayout(LayoutOption(id: "2x2", rows: 2, columns: 2))
        XCTAssertTrue(viewModel.replaceImage(at: 3, with: secondURL))
        XCTAssertEqual(viewModel.selectedSlotIndex, 3)

        viewModel.selectLayout(LayoutOption(id: "3x3", rows: 3, columns: 3))
        XCTAssertTrue(viewModel.replaceImage(at: 8, with: thirdURL))
        XCTAssertEqual(viewModel.selectedSlotIndex, 8)
    }

    private func makeTemporaryImageURL(gray: UInt8) throws -> URL {
        guard let context = CGContext(
            data: nil,
            width: 20,
            height: 20,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImgDeckError.contextCreationFailed
        }
        context.setFillColor(CGColor(red: CGFloat(gray) / 255, green: CGFloat(gray) / 255, blue: CGFloat(gray) / 255, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        guard let image = context.makeImage() else { throw ImgDeckError.contextCreationFailed }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("imgdeck-drop-\(UUID().uuidString)")
            .appendingPathExtension("png")
        try PageRenderer.encodedData(for: image, format: .png).write(to: url)
        return url
    }
}
