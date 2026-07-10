import AppKit
import Combine

@MainActor
final class ImageDeckViewModel: ObservableObject {
    @Published var slots: [ImageItem?] = Array(repeating: nil, count: 9)
    @Published var selectedSlotIndex: Int? {
        didSet {
            selectedID = selectedSlotIndex.flatMap { slots.indices.contains($0) ? slots[$0]?.id : nil }
        }
    }
    @Published private(set) var selectedID: ImageItem.ID?
    @Published var selectedLayout = LayoutOption.defaultLayout
    @Published var resolutionText = "72"
    @Published var resolutionUnit = ResolutionUnit.dpi
    @Published var outputFormat = OutputFormat.png
    @Published private(set) var previewZoomPercent = 100
    @Published var previewImage: NSImage?
    @Published var renderedImage: CGImage?
    @Published var renderedSize: (width: Int, height: Int)?
    @Published var status = ""
    @Published var alert: AlertMessage?
    @Published var isRendering = false
    @Published private(set) var imageTransforms: [ImageItem.ID: ImageTransform] = [:]
    @Published private(set) var mosaicRegions: [MosaicRegion] = []
    @Published private(set) var mosaicBlockSize = 15
    @Published private(set) var pendingMosaicRect: CGRect?
    @Published var isAddingMosaic = false
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    private var language: AppLanguage = .simplifiedChinese
    private var statusState = StatusState.initial
    private var strings: AppStrings { AppStrings(language: language) }
    private weak var undoManager: UndoManager?
    private var imageCache: [ImageItem.ID: NSImage] = [:]

    var items: [ImageItem] { slots.compactMap { $0 } }
    var imageCount: Int { items.count }
    var remainingCapacity: Int { 9 - imageCount }

    init() {
        updateStatus()
    }

    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var selectedPath: String {
        guard let selectedItem else { return strings.noSelection }
        return strings.selectedPath(selectedItem.url.path)
    }

    var outputHint: String {
        do {
            let size = try outputSize()
            let estimatedBytes: Double
            if let renderedImage, renderedSize?.width == size.width, renderedSize?.height == size.height,
               let data = try? PageRenderer.encodedData(for: renderedImage, format: outputFormat) {
                estimatedBytes = Double(data.count)
            } else {
                estimatedBytes = Double(size.width * size.height) * (outputFormat == .png ? 0.0822 : 0.14)
            }
            return strings.outputHint(width: size.width, height: size.height, fileSize: formatFileSize(estimatedBytes))
        } catch {
            return strings.errorMessage(error)
        }
    }

    var canMoveUp: Bool {
        guard let selectedIndex else { return false }
        return selectedIndex > 0
    }

    var canMoveDown: Bool {
        guard let selectedIndex else { return false }
        return selectedIndex < selectedLayout.capacity - 1
    }

    var canRemove: Bool { selectedIndex != nil }
    var canSave: Bool { !items.isEmpty }
    var canApplyMosaic: Bool { pendingMosaicRect != nil }

    var selectedTransform: ImageTransform? {
        guard let selectedID else { return nil }
        return transform(for: selectedID)
    }

    func selectSlot(_ index: Int?) {
        guard let index else {
            selectedSlotIndex = nil
            return
        }
        guard slots.indices.contains(index) else { return }
        selectedSlotIndex = index
    }

    func adjustPreviewZoom(by amount: Int) {
        setPreviewZoomPercent(previewZoomPercent + amount)
    }

    func setPreviewZoomPercent(_ percent: Int) {
        previewZoomPercent = min(max(percent, 25), 200)
    }

    func toggleMosaicMode() {
        isAddingMosaic.toggle()
        if !isAddingMosaic {
            pendingMosaicRect = nil
        }
    }

    func updateMosaicBlockSize(_ size: Int) {
        let clampedSize = min(max(size, 2), 100)
        guard mosaicBlockSize != clampedSize else { return }
        mosaicBlockSize = clampedSize
        invalidatePreview()
    }

    func commitMosaicBlockSizeChange(from oldValue: Int) {
        guard oldValue != mosaicBlockSize else { return }
        registerMosaicUndo(
            state: MosaicState(regions: mosaicRegions, blockSize: oldValue, pendingRect: pendingMosaicRect),
            actionName: strings.changeMosaicBlockSizeAction
        )
    }

    func addMosaic(_ normalizedRect: CGRect) {
        setPendingMosaic(normalizedRect)
        applyPendingMosaic()
    }

    func setPendingMosaic(_ normalizedRect: CGRect) {
        let rect = normalizedRect.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard !rect.isNull, rect.width > 0.002, rect.height > 0.002 else { return }
        pendingMosaicRect = rect
    }

    func applyPendingMosaic() {
        guard let pendingMosaicRect else { return }
        let oldState = MosaicState(regions: mosaicRegions, blockSize: mosaicBlockSize, pendingRect: pendingMosaicRect)
        mosaicRegions.append(MosaicRegion(normalizedRect: pendingMosaicRect))
        self.pendingMosaicRect = nil
        invalidatePreview()
        registerMosaicUndo(state: oldState, actionName: strings.addMosaicAction)
    }

    func editorPreviewImage(width: Int, height: Int) -> NSImage? {
        guard width > 0, height > 0 else { return nil }
        guard let image = try? PageRenderer.render(
            imageURLs: slots.map { $0?.url },
            transforms: slots.map { $0.map { transform(for: $0.id) } ?? .identity },
            mosaics: mosaicRegions,
            mosaicBlockSize: mosaicBlockSize,
            layout: selectedLayout,
            width: width,
            height: height
        ) else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: width, height: height))
    }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        updateStatus()
    }

    func setUndoManager(_ undoManager: UndoManager?) {
        self.undoManager = undoManager
        refreshUndoAvailability()
    }

    func undoLastChange() {
        undoManager?.undo()
        refreshUndoAvailability()
    }

    func redoLastChange() {
        undoManager?.redo()
        refreshUndoAvailability()
    }

    func image(for item: ImageItem) -> NSImage? {
        if let cached = imageCache[item.id] { return cached }
        let image = NSImage(contentsOf: item.url)
        imageCache[item.id] = image
        return image
    }

    func transform(for id: ImageItem.ID) -> ImageTransform {
        imageTransforms[id] ?? .identity
    }

    func updateTransform(_ transform: ImageTransform, for id: ImageItem.ID) {
        imageTransforms[id] = transform
        invalidatePreview()
    }

    func commitTransformChange(from oldValue: ImageTransform, for id: ImageItem.ID) {
        let newValue = transform(for: id)
        guard oldValue != newValue else { return }
        registerUndo(value: oldValue, for: id, actionName: strings.adjustImageAction)
    }

    func setScalingMode(_ mode: ImageScalingMode) {
        guard let id = selectedID else { return }
        let oldValue = transform(for: id)
        guard oldValue.scalingMode != mode else { return }
        var newValue = oldValue
        newValue.scalingMode = mode
        if mode == .proportional {
            let scale = max(newValue.scaleX, newValue.scaleY)
            newValue.scaleX = scale
            newValue.scaleY = scale
        }
        updateTransform(newValue, for: id)
        registerUndo(value: oldValue, for: id, actionName: strings.changeScalingModeAction)
    }

    func resetSelectedTransform() {
        guard let id = selectedID else { return }
        let oldValue = transform(for: id)
        guard oldValue != .identity else { return }
        updateTransform(.identity, for: id)
        registerUndo(value: oldValue, for: id, actionName: strings.resetImageAction)
    }

    func chooseImages() {
        let remaining = remainingCapacity
        guard remaining > 0 else {
            alert = .init(title: strings.maximumReachedTitle, message: strings.maximumReachedMessage)
            return
        }

        let panel = NSOpenPanel()
        panel.title = strings.chooseImagesPanelTitle
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }

        addImages(from: panel.urls)
    }

    @discardableResult
    func addImages(from urls: [URL]) -> Int {
        let remaining = remainingCapacity
        let startIndex = selectedSlotIndex.map { ($0 + 1) % slots.count } ?? 0
        let emptyIndices = (0..<slots.count)
            .map { (startIndex + $0) % slots.count }
            .filter { slots[$0] == nil }
        if urls.count > remaining {
            alert = .init(title: strings.tooManyImagesTitle, message: strings.remainingImagesMessage(remaining))
        }
        let acceptedURLs = Array(urls.prefix(remaining))
        let newItems = acceptedURLs.map { ImageItem(url: $0) }
        for item in newItems {
            imageTransforms[item.id] = .identity
            imageCache[item.id] = NSImage(contentsOf: item.url)
        }
        for (item, emptyIndex) in zip(newItems, emptyIndices) {
            slots[emptyIndex] = item
        }
        if !newItems.isEmpty, let firstIndex = emptyIndices.first {
            selectSlot(firstIndex)
        }
        invalidatePreview()
        refreshStatus()
        return newItems.count
    }

    @discardableResult
    func replaceImage(at index: Int, with urls: [URL]) -> Bool {
        guard let url = urls.first else { return false }
        return replaceImage(at: index, with: url)
    }

    @discardableResult
    func replaceImage(at index: Int, with url: URL) -> Bool {
        guard slots.indices.contains(index), url.isFileURL else { return false }
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }
        guard let image = NSImage(contentsOf: url) else { return false }

        let oldState = slotState(at: index)
        if let oldItem = oldState.item {
            imageTransforms.removeValue(forKey: oldItem.id)
            imageCache.removeValue(forKey: oldItem.id)
        }
        let item = ImageItem(url: url)
        imageTransforms[item.id] = .identity
        imageCache[item.id] = image
        slots[index] = item
        selectSlot(index)
        invalidatePreview()
        refreshStatus()
        registerSlotUndo(state: oldState, at: index, actionName: strings.replaceImageAction)
        return true
    }

    func removeSelected() {
        guard let index = selectedIndex else { return }
        guard let removed = slots[index] else { return }
        slots[index] = nil
        imageTransforms.removeValue(forKey: removed.id)
        imageCache.removeValue(forKey: removed.id)
        selectSlot(index)
        invalidatePreview()
        refreshStatus()
    }

    func clearImages() {
        slots = Array(repeating: nil, count: 9)
        imageTransforms.removeAll()
        imageCache.removeAll()
        selectSlot(nil)
        invalidatePreview()
        refreshStatus()
    }

    func moveSelected(by offset: Int) {
        guard let oldIndex = selectedIndex else { return }
        let newIndex = oldIndex + offset
        guard newIndex >= 0, offset < 0 || newIndex < selectedLayout.capacity else { return }
        slots.swapAt(oldIndex, newIndex)
        selectSlot(newIndex)
        invalidatePreview()
        refreshStatus()
    }

    func selectLayout(_ layout: LayoutOption) {
        selectedLayout = layout
        invalidatePreview()
        refreshStatus()
    }

    func resolutionDidChange() {
        guard let renderedSize, let size = try? outputSize(),
              renderedSize.width != size.width || renderedSize.height != size.height else { return }
        statusState = .resolutionChanged
        updateStatus()
    }

    func renderPreview() {
        guard imageCount > 0 else {
            alert = .init(title: strings.noImagesTitle, message: strings.noImagesMessage)
            return
        }

        isRendering = true
        defer { isRendering = false }
        do {
            let size = try outputSize()
            let image = try PageRenderer.render(
                imageURLs: slots.map { $0?.url },
                transforms: slots.map { $0.map { transform(for: $0.id) } ?? .identity },
                mosaics: mosaicRegions,
                mosaicBlockSize: mosaicBlockSize,
                layout: selectedLayout,
                width: size.width,
                height: size.height
            )
            renderedImage = image
            renderedSize = size
            previewImage = NSImage(cgImage: image, size: NSSize(width: size.width, height: size.height))

            let shown = slots.prefix(selectedLayout.capacity).compactMap { $0 }.count
            let blanks = selectedLayout.capacity - shown
            let hidden = slots.dropFirst(selectedLayout.capacity).compactMap { $0 }.count
            statusState = .preview(width: size.width, height: size.height, shown: shown, blanks: blanks, hidden: hidden)
            updateStatus()
        } catch {
            alert = .init(title: strings.renderFailedTitle, message: strings.errorMessage(error))
        }
    }

    func saveResult() {
        guard imageCount > 0 else { return }
        let image: CGImage
        do {
            let size = try outputSize()
            image = try PageRenderer.render(
                imageURLs: slots.map { $0?.url },
                transforms: slots.map { $0.map { transform(for: $0.id) } ?? .identity },
                mosaics: mosaicRegions,
                mosaicBlockSize: mosaicBlockSize,
                layout: selectedLayout,
                width: size.width,
                height: size.height
            )
            renderedImage = image
            renderedSize = size
        } catch {
            alert = .init(title: strings.renderFailedTitle, message: strings.errorMessage(error))
            return
        }
        let panel = NSSavePanel()
        panel.title = strings.savePanelTitle
        panel.allowedContentTypes = outputFormat == .png ? [.png] : [.jpeg]
        panel.nameFieldStringValue = "imgdeck_result.\(outputFormat.fileExtension)"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, var url = panel.url else { return }

        if url.pathExtension.lowercased() != outputFormat.fileExtension {
            url.deletePathExtension()
            url.appendPathExtension(outputFormat.fileExtension)
        }

        do {
            let data = try PageRenderer.encodedData(for: image, format: outputFormat)
            try data.write(to: url, options: .atomic)
            statusState = .saved(url.path)
            updateStatus()
            alert = .init(title: strings.saveSuccessTitle, message: strings.saveSuccessMessage)
        } catch {
            alert = .init(title: strings.saveFailedTitle, message: strings.errorMessage(error))
        }
    }

    private var selectedItem: ImageItem? { selectedIndex.flatMap { slots[$0] } }

    private var selectedIndex: Int? {
        guard let selectedSlotIndex,
              slots.indices.contains(selectedSlotIndex),
              slots[selectedSlotIndex] != nil else { return nil }
        return selectedSlotIndex
    }

    private func outputSize() throws -> (width: Int, height: Int) {
        guard let resolution = Double(resolutionText) else {
            throw ImgDeckError.invalidResolutionNumber
        }
        return try A4Size.pixels(resolution: resolution, unit: resolutionUnit)
    }

    private func invalidatePreview() {
        previewImage = nil
        renderedImage = nil
        renderedSize = nil
    }

    private func refreshStatus() {
        statusState = imageCount == 0 ? .initial : .selection
        updateStatus()
    }

    private func updateStatus() {
        switch statusState {
        case .initial:
            status = strings.initialStatus
        case .selection:
            status = strings.selectionStatus(count: imageCount, layout: selectedLayout.label, capacity: selectedLayout.capacity)
        case .resolutionChanged:
            status = strings.resolutionChanged
        case .preview(let width, let height, let shown, let blanks, let hidden):
            status = strings.previewStatus(width: width, height: height, shown: shown, blanks: blanks, hidden: hidden)
        case .saved(let path):
            status = strings.savedPath(path)
        }
    }

    private func formatFileSize(_ bytes: Double) -> String {
        if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        }
        return String(format: "%.1f MB", bytes / (1024 * 1024))
    }

    private func registerUndo(value: ImageTransform, for id: ImageItem.ID, actionName: String) {
        undoManager?.registerUndo(withTarget: self) { target in
            let current = target.transform(for: id)
            target.updateTransform(value, for: id)
            target.registerUndo(value: current, for: id, actionName: actionName)
            target.refreshUndoAvailability()
        }
        undoManager?.setActionName(actionName)
        refreshUndoAvailability()
    }

    private struct MosaicState {
        let regions: [MosaicRegion]
        let blockSize: Int
        let pendingRect: CGRect?
    }

    private func restoreMosaicState(_ state: MosaicState) {
        mosaicRegions = state.regions
        mosaicBlockSize = state.blockSize
        pendingMosaicRect = state.pendingRect
        invalidatePreview()
    }

    private func registerMosaicUndo(state: MosaicState, actionName: String) {
        undoManager?.registerUndo(withTarget: self) { target in
            let currentState = MosaicState(
                regions: target.mosaicRegions,
                blockSize: target.mosaicBlockSize,
                pendingRect: target.pendingMosaicRect
            )
            target.restoreMosaicState(state)
            target.registerMosaicUndo(state: currentState, actionName: actionName)
        }
        undoManager?.setActionName(actionName)
        refreshUndoAvailability()
    }

    private struct SlotState {
        let item: ImageItem?
        let transform: ImageTransform?
        let selectedSlotIndex: Int?
    }

    private func slotState(at index: Int) -> SlotState {
        let item = slots[index]
        return SlotState(
            item: item,
            transform: item.map { transform(for: $0.id) },
            selectedSlotIndex: selectedSlotIndex
        )
    }

    private func restoreSlotState(_ state: SlotState, at index: Int) {
        if let currentItem = slots[index], currentItem.id != state.item?.id {
            imageTransforms.removeValue(forKey: currentItem.id)
            imageCache.removeValue(forKey: currentItem.id)
        }
        slots[index] = state.item
        if let item = state.item, let transform = state.transform {
            imageTransforms[item.id] = transform
            if imageCache[item.id] == nil {
                imageCache[item.id] = NSImage(contentsOf: item.url)
            }
        }
        selectSlot(state.selectedSlotIndex)
        invalidatePreview()
        refreshStatus()
    }

    private func registerSlotUndo(state: SlotState, at index: Int, actionName: String) {
        undoManager?.registerUndo(withTarget: self) { target in
            let currentState = target.slotState(at: index)
            target.restoreSlotState(state, at: index)
            target.registerSlotUndo(state: currentState, at: index, actionName: actionName)
        }
        undoManager?.setActionName(actionName)
        refreshUndoAvailability()
    }

    private func refreshUndoAvailability() {
        canUndo = undoManager?.canUndo ?? false
        canRedo = undoManager?.canRedo ?? false
    }

    private enum StatusState {
        case initial
        case selection
        case resolutionChanged
        case preview(width: Int, height: Int, shown: Int, blanks: Int, hidden: Int)
        case saved(String)
    }
}
