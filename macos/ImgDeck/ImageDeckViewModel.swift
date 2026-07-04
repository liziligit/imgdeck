import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class ImageDeckViewModel: ObservableObject {
    @Published var items: [ImageItem] = []
    @Published var selectedID: ImageItem.ID?
    @Published var selectedLayout = LayoutOption.all[0]
    @Published var resolutionText = "72"
    @Published var resolutionUnit = ResolutionUnit.dpi
    @Published var outputFormat = OutputFormat.png
    @Published var previewImage: NSImage?
    @Published var renderedImage: CGImage?
    @Published var renderedSize: (width: Int, height: Int)?
    @Published var status = ""
    @Published var alert: AlertMessage?
    @Published var isRendering = false

    private var language: AppLanguage = .simplifiedChinese
    private var statusState = StatusState.initial
    private var strings: AppStrings { AppStrings(language: language) }

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
        return selectedIndex < items.count - 1
    }

    var canRemove: Bool { selectedIndex != nil }
    var canSave: Bool { renderedImage != nil }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        updateStatus()
    }

    func chooseImages() {
        let remaining = 9 - items.count
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

        var urls = panel.urls
        if urls.count > remaining {
            urls = Array(urls.prefix(remaining))
            alert = .init(title: strings.tooManyImagesTitle, message: strings.remainingImagesMessage(remaining))
        }
        let newItems = urls.map { ImageItem(url: $0) }
        items.append(contentsOf: newItems)
        selectedID = newItems.first?.id
        invalidatePreview()
        refreshStatus()
    }

    func removeSelected() {
        guard let index = selectedIndex else { return }
        items.remove(at: index)
        if items.isEmpty {
            selectedID = nil
        } else {
            selectedID = items[min(index, items.count - 1)].id
        }
        invalidatePreview()
        refreshStatus()
    }

    func clearImages() {
        items.removeAll()
        selectedID = nil
        invalidatePreview()
        refreshStatus()
    }

    func moveSelected(by offset: Int) {
        guard let oldIndex = selectedIndex else { return }
        let newIndex = oldIndex + offset
        guard items.indices.contains(newIndex) else { return }
        items.swapAt(oldIndex, newIndex)
        selectedID = items[newIndex].id
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
        guard !items.isEmpty else {
            alert = .init(title: strings.noImagesTitle, message: strings.noImagesMessage)
            return
        }

        isRendering = true
        defer { isRendering = false }
        do {
            let size = try outputSize()
            let image = try PageRenderer.render(
                imageURLs: items.map(\.url),
                layout: selectedLayout,
                width: size.width,
                height: size.height
            )
            renderedImage = image
            renderedSize = size
            previewImage = NSImage(cgImage: image, size: NSSize(width: size.width, height: size.height))

            let shown = min(items.count, selectedLayout.capacity)
            let blanks = selectedLayout.capacity - shown
            let hidden = max(0, items.count - selectedLayout.capacity)
            statusState = .preview(width: size.width, height: size.height, shown: shown, blanks: blanks, hidden: hidden)
            updateStatus()
        } catch {
            alert = .init(title: strings.renderFailedTitle, message: strings.errorMessage(error))
        }
    }

    func saveResult() {
        guard let renderedImage else { return }
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
            let data = try PageRenderer.encodedData(for: renderedImage, format: outputFormat)
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
        return items.firstIndex { $0.id == selectedID }
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
        statusState = items.isEmpty ? .initial : .selection
        updateStatus()
    }

    private func updateStatus() {
        switch statusState {
        case .initial:
            status = strings.initialStatus
        case .selection:
            status = strings.selectionStatus(count: items.count, layout: selectedLayout.label, capacity: selectedLayout.capacity)
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

    private enum StatusState {
        case initial
        case selection
        case resolutionChanged
        case preview(width: Int, height: Int, shown: Int, blanks: Int, hidden: Int)
        case saved(String)
    }
}
