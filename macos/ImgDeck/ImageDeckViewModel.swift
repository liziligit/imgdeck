import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class ImageDeckViewModel: ObservableObject {
    @Published var slots: [ImageItem?] = Array(repeating: nil, count: 9)
    @Published var selectedID: ImageItem.ID?
    @Published var selectedLayout = LayoutOption.defaultLayout
    @Published var resolutionText = "72"
    @Published var resolutionUnit = ResolutionUnit.dpi
    @Published var outputFormat = OutputFormat.png
    @Published var previewImage: NSImage?
    @Published var renderedImage: CGImage?
    @Published var renderedSize: (width: Int, height: Int)?
    @Published var status = ""
    @Published var alert: AlertMessage?
    @Published var isRendering = false
    @Published private(set) var imageTransforms: [ImageItem.ID: ImageTransform] = [:]
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

    var selectedTransform: ImageTransform? {
        guard let selectedID else { return nil }
        return transform(for: selectedID)
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
        let startIndex = selectedIndex.map { ($0 + 1) % slots.count } ?? 0
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
        if let firstID = newItems.first?.id {
            selectedID = firstID
        }
        invalidatePreview()
        refreshStatus()
        return newItems.count
    }

    func removeSelected() {
        guard let index = selectedIndex else { return }
        guard let removed = slots[index] else { return }
        slots[index] = nil
        imageTransforms.removeValue(forKey: removed.id)
        imageCache.removeValue(forKey: removed.id)
        selectedID = nil
        invalidatePreview()
        refreshStatus()
    }

    func clearImages() {
        slots = Array(repeating: nil, count: 9)
        imageTransforms.removeAll()
        imageCache.removeAll()
        selectedID = nil
        invalidatePreview()
        refreshStatus()
    }

    func moveSelected(by offset: Int) {
        guard let oldIndex = selectedIndex else { return }
        let newIndex = oldIndex + offset
        guard newIndex >= 0, offset < 0 || newIndex < selectedLayout.capacity else { return }
        slots.swapAt(oldIndex, newIndex)
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

    private var selectedItem: ImageItem? {
        guard let selectedID else { return nil }
        return items.first { $0.id == selectedID }
    }

    private var selectedIndex: Int? {
        guard let selectedID else { return nil }
        return slots.firstIndex { $0?.id == selectedID }
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
