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
    @Published var status = "请选择图片和版式"
    @Published var alert: AlertMessage?
    @Published var isRendering = false

    struct AlertMessage: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var selectedPath: String {
        guard let selectedItem else { return "所选图片：尚未选择" }
        return "所选图片：\(selectedItem.url.path)"
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
            return "输出约 \(size.width) × \(size.height) 像素（\(formatFileSize(estimatedBytes))）"
        } catch {
            return error.localizedDescription
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

    func chooseImages() {
        let remaining = 9 - items.count
        guard remaining > 0 else {
            alert = .init(title: "数量已满", message: "最多只能选择 9 张图片。")
            return
        }

        let panel = NSOpenPanel()
        panel.title = "选择要拼接的图片"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }

        var urls = panel.urls
        if urls.count > remaining {
            urls = Array(urls.prefix(remaining))
            alert = .init(title: "图片过多", message: "最多还能添加 \(remaining) 张图片。")
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
        status = "分辨率已调整；当前预览保持不变，点击“预览”后应用新尺寸。"
    }

    func renderPreview() {
        guard !items.isEmpty else {
            alert = .init(title: "尚未选择图片", message: "请至少添加 1 张图片。")
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
            status = "A4 预览 \(size.width) × \(size.height)：显示 \(shown) 张，空白 \(blanks) 个，未显示 \(hidden) 张"
        } catch {
            alert = .init(title: "拼接失败", message: error.localizedDescription)
        }
    }

    func saveResult() {
        guard let renderedImage else { return }
        let panel = NSSavePanel()
        panel.title = "保存 A4 拼接图片"
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
            status = "已保存到：\(url.path)"
            alert = .init(title: "保存成功", message: "A4 拼接图片已保存。")
        } catch {
            alert = .init(title: "保存失败", message: error.localizedDescription)
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
            throw ImgDeckError.invalidResolution("请输入有效的分辨率数值。")
        }
        return try A4Size.pixels(resolution: resolution, unit: resolutionUnit)
    }

    private func invalidatePreview() {
        previewImage = nil
        renderedImage = nil
        renderedSize = nil
    }

    private func refreshStatus() {
        status = "已选择 \(items.count) 张图片；当前 \(selectedLayout.label) 版式可放 \(selectedLayout.capacity) 张"
    }

    private func formatFileSize(_ bytes: Double) -> String {
        if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        }
        return String(format: "%.1f MB", bytes / (1024 * 1024))
    }
}
