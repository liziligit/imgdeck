import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ImageDeckViewModel()
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .simplifiedChinese
    @Environment(\.undoManager) private var undoManager
    @State private var mosaicBlockSizeStart: Int?

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.appTitle)
                        .font(.system(size: 26, weight: .bold))
                    Text(strings.appSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                controls
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(width: 450)
            .frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading, spacing: 16) {
                Text(strings.a4Preview)
                    .font(.system(size: 26, weight: .bold))

                previewPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(22)
        .frame(minWidth: 960, minHeight: 680)
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(strings.ok))
            )
        }
        .onAppear {
            viewModel.setLanguage(language)
            viewModel.setUndoManager(undoManager)
        }
        .onChange(of: language) { newLanguage in
            viewModel.setLanguage(newLanguage)
        }
    }

    private var controls: some View {
        GroupBox(strings.imagesAndLayout(remaining: viewModel.remainingCapacity)) {
            VStack(spacing: 10) {
                List(selection: $viewModel.selectedSlotIndex) {
                    ForEach(0..<9, id: \.self) { index in
                        Group {
                            if let item = viewModel.slots[index] {
                                HStack(spacing: 4) {
                                    Text("\(index + 1).")
                                        .fontWeight(.bold)
                                        .frame(width: 24, alignment: .trailing)
                                    Text(item.url.lastPathComponent)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .help(item.url.path)
                            } else {
                                HStack(spacing: 4) {
                                    Text("\(index + 1).")
                                        .frame(width: 24, alignment: .trailing)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .tag(index)
                        .frame(maxWidth: .infinity, minHeight: 25, maxHeight: 25, alignment: .leading)
                        .overlay(alignment: .top) {
                            if index == 0 {
                                Rectangle()
                                    .fill(Color(nsColor: .separatorColor))
                                    .frame(height: 2)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color(nsColor: .separatorColor))
                                .frame(height: index == 8 ? 2 : 1)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                        .listRowSeparator(.hidden)
                    }
                }
                .frame(minHeight: 210, maxHeight: .infinity)
                .accessibilityLabel(strings.selectedImages)

                HStack(spacing: 8) {
                    Button(strings.addImages, systemImage: "photo.badge.plus", action: viewModel.chooseImages)
                        .frame(maxWidth: .infinity)
                        .disabled(viewModel.imageCount == 9)
                    Button(strings.remove, systemImage: "minus.circle", action: viewModel.removeSelected)
                        .frame(maxWidth: .infinity)
                        .disabled(!viewModel.canRemove)
                }

                HStack(spacing: 8) {
                    Button(strings.moveUp, systemImage: "arrow.up", action: { viewModel.moveSelected(by: -1) })
                        .frame(maxWidth: .infinity)
                        .disabled(!viewModel.canMoveUp)
                    Button(strings.moveDown, systemImage: "arrow.down", action: { viewModel.moveSelected(by: 1) })
                        .frame(maxWidth: .infinity)
                        .disabled(!viewModel.canMoveDown)
                    Button(strings.clear, systemImage: "trash", action: viewModel.clearImages)
                        .frame(maxWidth: .infinity)
                        .disabled(viewModel.imageCount == 0)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(strings.layout)
                        .font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(LayoutOption.all) { layout in
                            LayoutButton(
                                layout: layout,
                                isSelected: layout == viewModel.selectedLayout,
                                accessibilitySuffix: strings.layoutAccessibilitySuffix,
                                action: { viewModel.selectLayout(layout) }
                            )
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(strings.resolution)
                        TextField("72", text: $viewModel.resolutionText)
                            .frame(width: 64)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: viewModel.resolutionText) { _ in viewModel.resolutionDidChange() }
                        Picker(strings.unit, selection: $viewModel.resolutionUnit) {
                            ForEach(ResolutionUnit.allCases) { unit in
                                Text(strings.unitName(unit)).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: viewModel.resolutionUnit) { _ in viewModel.resolutionDidChange() }
                    }
                    Text(viewModel.outputHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack(spacing: 8) {
                    Button(action: viewModel.renderPreview) {
                        if viewModel.isRendering {
                            ProgressView().controlSize(.small)
                        } else {
                            Label(strings.preview, systemImage: "eye")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isRendering)

                    Button(strings.saveImage, systemImage: "square.and.arrow.down", action: viewModel.saveResult)
                        .disabled(!viewModel.canSave)

                    Picker(strings.format, selection: $viewModel.outputFormat) {
                        ForEach(OutputFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 76)
                }

                Text(viewModel.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                    .accessibilityLabel("\(strings.status): \(viewModel.status)")
            }
            .padding(6)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var previewPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.selectedPath)
                    .lineLimit(2)
                    .font(.callout)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)

                HStack(spacing: 8) {
                    Picker(strings.proportionalScaling, selection: Binding(
                        get: { viewModel.selectedTransform?.scalingMode ?? .proportional },
                        set: { mode in viewModel.setScalingMode(mode) }
                    )) {
                        Text(strings.proportionalScaling).tag(ImageScalingMode.proportional)
                        Text(strings.freeScaling).tag(ImageScalingMode.free)
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.selectedID == nil)

                    Button(strings.resetImage, action: viewModel.resetSelectedTransform)
                        .disabled(viewModel.selectedID == nil || viewModel.selectedTransform == .identity)

                    Button(action: viewModel.undoLastChange) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .help(strings.undoHint)
                    .accessibilityLabel(strings.undoHint)
                    .disabled(!viewModel.canUndo)

                    Button(action: viewModel.redoLastChange) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(strings.redoHint)
                    .accessibilityLabel(strings.redoHint)
                    .disabled(!viewModel.canRedo)
                }

                HStack(spacing: 4) {
                    PreviewZoomControl(viewModel: viewModel, strings: strings)
                    Button(strings.rectangleMosaic, action: viewModel.toggleMosaicMode)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(viewModel.isAddingMosaic ? .accentColor : nil)
                    Button(strings.applyMosaic, action: viewModel.applyPendingMosaic)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!viewModel.canApplyMosaic)
                    Text(strings.blockSize)
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.mosaicBlockSize) },
                            set: { viewModel.updateMosaicBlockSize(Int($0.rounded())) }
                        ),
                        in: 2...100,
                        step: 1,
                        onEditingChanged: { isEditing in
                            if isEditing {
                                mosaicBlockSizeStart = viewModel.mosaicBlockSize
                            } else if let oldValue = mosaicBlockSizeStart {
                                viewModel.commitMosaicBlockSizeChange(from: oldValue)
                                mosaicBlockSizeStart = nil
                            }
                        }
                    )
                    .frame(width: 70)
                    Text("\(viewModel.mosaicBlockSize)")
                        .monospacedDigit()
                        .frame(width: 32)
                        .padding(.vertical, 3)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.accentColor, lineWidth: 2))
                }

                Text(viewModel.isAddingMosaic ? "\(strings.editImageHint) \(strings.mosaicDrawingHint)" : strings.editImageHint)
                    .font(.caption)
                    .foregroundStyle(viewModel.isAddingMosaic ? Color.accentColor : .secondary)
                    .fixedSize(horizontal: false, vertical: true)

                A4Editor(viewModel: viewModel, strings: strings)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(6)
        }
    }
}

private struct LayoutButton: View {
    let layout: LayoutOption
    let isSelected: Bool
    let accessibilitySuffix: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                LayoutGlyph(layout: layout)
                    .frame(width: 32, height: 50)
                Text(layout.label)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel("\(layout.label) \(accessibilitySuffix)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LayoutGlyph: View {
    let layout: LayoutOption

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(.white)
                Path { path in
                    let size = geometry.size
                    for column in 1..<layout.columns {
                        let x = size.width * CGFloat(column) / CGFloat(layout.columns)
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for row in 1..<layout.rows {
                        let y = size.height * CGFloat(row) / CGFloat(layout.rows)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                }
                .stroke(Color(nsColor: .secondaryLabelColor), lineWidth: 1)
            }
            .overlay(Rectangle().stroke(Color(nsColor: .secondaryLabelColor), lineWidth: 1))
        }
    }
}

private struct A4Editor: View {
    @ObservedObject var viewModel: ImageDeckViewModel
    let strings: AppStrings

    var body: some View {
        GeometryReader { geometry in
            let pageSize = fittedPageSize(in: geometry.size)
            let zoomScale = CGFloat(viewModel.previewZoomPercent) / 100
            let zoomedPageSize = CGSize(width: pageSize.width * zoomScale, height: pageSize.height * zoomScale)
            ZStack {
                Color(nsColor: .darkGray).opacity(0.75)
                ScrollView([.horizontal, .vertical]) {
                    PageEditorCanvas(viewModel: viewModel, strings: strings)
                        .frame(width: zoomedPageSize.width, height: zoomedPageSize.height)
                        .background(.white)
                        .overlay(Rectangle().stroke(Color(nsColor: .separatorColor), lineWidth: 1))
                        .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
                        .padding(18)
                        .frame(
                            minWidth: geometry.size.width,
                            minHeight: geometry.size.height,
                            alignment: .center
                        )
                }
            }
        }
        .accessibilityLabel(viewModel.imageCount == 0 ? strings.blankPreview : strings.resultPreview)
    }

    private func fittedPageSize(in available: CGSize) -> CGSize {
        let insetWidth = max(80, available.width - 36)
        let insetHeight = max(110, available.height - 36)
        let ratio = CGFloat(210.0 / 297.0)
        if insetWidth / insetHeight > ratio {
            return CGSize(width: insetHeight * ratio, height: insetHeight)
        }
        return CGSize(width: insetWidth, height: insetWidth / ratio)
    }
}

private struct PreviewZoomControl: View {
    @ObservedObject var viewModel: ImageDeckViewModel
    let strings: AppStrings

    private let presets = [25, 50, 75, 100, 150, 200]

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.adjustPreviewZoom(by: -5) }) {
                Image(systemName: "minus")
            }
            .help(strings.zoomOut)
            .accessibilityLabel(strings.zoomOut)
            .disabled(viewModel.previewZoomPercent <= 25)

            Menu {
                Button(strings.fitPage) { viewModel.setPreviewZoomPercent(100) }
                Divider()
                ForEach(presets, id: \.self) { percent in
                    Button("\(percent)%") { viewModel.setPreviewZoomPercent(percent) }
                }
            } label: {
                Text("\(viewModel.previewZoomPercent)%")
                    .monospacedDigit()
                    .frame(minWidth: 48)
            }
            .menuStyle(.borderlessButton)

            Button(action: { viewModel.adjustPreviewZoom(by: 5) }) {
                Image(systemName: "plus")
            }
            .help(strings.zoomIn)
            .accessibilityLabel(strings.zoomIn)
            .disabled(viewModel.previewZoomPercent >= 200)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

private struct PageEditorCanvas: View {
    @ObservedObject var viewModel: ImageDeckViewModel
    let strings: AppStrings
    @State private var dropTargetIndex: Int?
    @State private var mosaicStart: CGPoint?
    @State private var mosaicCurrent: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            let cellSize = CGSize(
                width: geometry.size.width / CGFloat(viewModel.selectedLayout.columns),
                height: geometry.size.height / CGFloat(viewModel.selectedLayout.rows)
            )
            let renderedPage = viewModel.mosaicRegions.isEmpty ? nil : viewModel.editorPreviewImage(
                width: max(1, Int(geometry.size.width.rounded())),
                height: max(1, Int(geometry.size.height.rounded()))
            )
            ZStack(alignment: .topLeading) {
                Color.white
                if let renderedPage {
                    Image(nsImage: renderedPage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                ForEach(0..<viewModel.selectedLayout.capacity, id: \.self) { index in
                    let row = index / viewModel.selectedLayout.columns
                    let column = index % viewModel.selectedLayout.columns
                    let item = viewModel.slots[index]
                    EditableImageCell(
                        index: index,
                        item: item,
                        image: item.flatMap(viewModel.image),
                        transform: item.map { viewModel.transform(for: $0.id) } ?? .identity,
                        showsImage: renderedPage == nil,
                        isSelected: viewModel.selectedSlotIndex == index,
                        isDropTarget: dropTargetIndex == index,
                        isAddingMosaic: viewModel.isAddingMosaic,
                        cellSize: cellSize,
                        strings: strings,
                        select: { viewModel.selectSlot(index) },
                        update: { transform in
                            guard let id = item?.id else { return }
                            viewModel.updateTransform(transform, for: id)
                        },
                        commit: { oldValue in
                            guard let id = item?.id else { return }
                            viewModel.commitTransformChange(from: oldValue, for: id)
                        }
                    )
                    .frame(width: cellSize.width, height: cellSize.height)
                    .position(
                        x: cellSize.width * (CGFloat(column) + 0.5),
                        y: cellSize.height * (CGFloat(row) + 0.5)
                    )
                    .zIndex(viewModel.selectedSlotIndex == index ? 1 : 0)
                }
                if let mosaicStart, let mosaicCurrent {
                    mosaicOutline(
                        for: normalizedRect(from: mosaicStart, to: mosaicCurrent, in: geometry.size),
                        in: geometry.size,
                        color: .accentColor
                    )
                }
                if let pendingMosaicRect = viewModel.pendingMosaicRect {
                    mosaicOutline(for: pendingMosaicRect, in: geometry.size, color: .accentColor)
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(mosaicGesture(in: geometry.size))
            .onDrop(of: [.fileURL], delegate: CanvasImageDropDelegate(
                grid: PreviewGridDropTarget(
                    cellSize: cellSize,
                    columns: viewModel.selectedLayout.columns,
                    capacity: viewModel.selectedLayout.capacity
                ),
                targetIndex: $dropTargetIndex,
                handleDrop: replaceDroppedImage
            ))
        }
    }

    private func replaceDroppedImage(at index: Int, providers: [NSItemProvider]) -> Bool {
        dropTargetIndex = nil
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let resolvedURL: URL?
            if let itemURL = item as? URL {
                resolvedURL = itemURL
            } else if let data = item as? Data {
                resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
            } else {
                resolvedURL = nil
            }
            guard let resolvedURL,
                  let type = UTType(filenameExtension: resolvedURL.pathExtension),
                  type.conforms(to: .image) else { return }
            Task { @MainActor in
                _ = viewModel.replaceImage(at: index, with: resolvedURL)
                dropTargetIndex = nil
            }
        }
        return true
    }

    private func mosaicGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard viewModel.isAddingMosaic else { return }
                mosaicStart = mosaicStart ?? value.startLocation
                mosaicCurrent = value.location
            }
            .onEnded { value in
                guard viewModel.isAddingMosaic, let mosaicStart else { return }
                let rect = normalizedRect(from: mosaicStart, to: value.location, in: size)
                self.mosaicStart = nil
                mosaicCurrent = nil
                viewModel.setPendingMosaic(rect)
            }
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint, in size: CGSize) -> CGRect {
        let x1 = min(max(start.x, 0), size.width)
        let x2 = min(max(end.x, 0), size.width)
        let y1 = min(max(start.y, 0), size.height)
        let y2 = min(max(end.y, 0), size.height)
        return CGRect(
            x: min(x1, x2) / max(size.width, 1),
            y: min(y1, y2) / max(size.height, 1),
            width: abs(x2 - x1) / max(size.width, 1),
            height: abs(y2 - y1) / max(size.height, 1)
        )
    }

    @ViewBuilder
    private func mosaicOutline(for rect: CGRect, in size: CGSize, color: Color) -> some View {
        Rectangle()
            .fill(color.opacity(0.08))
            .overlay(Rectangle().stroke(color, style: StrokeStyle(lineWidth: 2, dash: [5, 3])))
            .frame(width: rect.width * size.width, height: rect.height * size.height)
            .position(
                x: (rect.minX + rect.width / 2) * size.width,
                y: (rect.minY + rect.height / 2) * size.height
            )
            .allowsHitTesting(false)
    }
}

struct PreviewGridDropTarget {
    let cellSize: CGSize
    let columns: Int
    let capacity: Int

    func cellIndex(for location: CGPoint) -> Int? {
        guard location.x >= 0, location.y >= 0,
              cellSize.width > 0, cellSize.height > 0 else { return nil }
        let column = Int(location.x / cellSize.width)
        let row = Int(location.y / cellSize.height)
        guard column >= 0, column < columns else { return nil }
        let index = row * columns + column
        return index < capacity ? index : nil
    }
}

private struct CanvasImageDropDelegate: DropDelegate {
    let grid: PreviewGridDropTarget
    @Binding var targetIndex: Int?
    let handleDrop: (Int, [NSItemProvider]) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [UTType.fileURL.identifier]) else {
            targetIndex = nil
            return false
        }
        updateTarget(for: info.location)
        return targetIndex != nil
    }

    func dropEntered(info: DropInfo) {
        updateTarget(for: info.location)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateTarget(for: info.location)
        return targetIndex == nil ? nil : DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) {
        targetIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        defer { targetIndex = nil }
        guard let index = cellIndex(for: info.location) else { return false }
        return handleDrop(index, info.itemProviders(for: [UTType.fileURL.identifier]))
    }

    private func updateTarget(for location: CGPoint) {
        targetIndex = cellIndex(for: location)
    }

    private func cellIndex(for location: CGPoint) -> Int? {
        grid.cellIndex(for: location)
    }
}

private struct EditableImageCell: View {
    let index: Int
    let item: ImageItem?
    let image: NSImage?
    let transform: ImageTransform
    let showsImage: Bool
    let isSelected: Bool
    let isDropTarget: Bool
    let isAddingMosaic: Bool
    let cellSize: CGSize
    let strings: AppStrings
    let select: () -> Void
    let update: (ImageTransform) -> Void
    let commit: (ImageTransform) -> Void

    @State private var dragStart: ImageTransform?

    var body: some View {
        let baseSize = fittedImageSize(image?.size ?? .zero, in: cellSize)
        ZStack {
            showsImage ? Color.white : Color.clear
            if let image, showsImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(
                        width: baseSize.width * transform.scaleX,
                        height: baseSize.height * transform.scaleY
                    )
                    .position(
                        x: cellSize.width / 2 + transform.offsetX * cellSize.width,
                        y: cellSize.height / 2 + transform.offsetY * cellSize.height
                    )
            } else if showsImage {
                Text("\(index + 1)")
                    .font(.system(size: 88, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: cellSize.width, height: cellSize.height)
        .clipped()
        .contentShape(Rectangle())
        .allowsHitTesting(!isAddingMosaic)
        .onTapGesture(perform: select)
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    guard item != nil else { return }
                    if dragStart == nil {
                        dragStart = transform
                        select()
                    }
                    guard var next = dragStart else { return }
                    next.offsetX += value.translation.width / max(cellSize.width, 1)
                    next.offsetY += value.translation.height / max(cellSize.height, 1)
                    update(next)
                }
                .onEnded { _ in
                    guard let oldValue = dragStart else { return }
                    commit(oldValue)
                    dragStart = nil
                }
        )
        .overlay {
            Rectangle()
                .stroke(Color.blue.opacity(0.9), style: StrokeStyle(lineWidth: isSelected ? 1.5 : 1, dash: [5, 4]))
                .allowsHitTesting(false)
            if isDropTarget {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 4)
                    .allowsHitTesting(false)
            }
            if isSelected, image != nil {
                SelectionHandles(
                    transform: transform,
                    baseSize: baseSize,
                    cellSize: cellSize,
                    strings: strings,
                    update: update,
                    commit: commit
                )
            }
        }
        .accessibilityLabel("\(strings.imageCell) \(index + 1)")
        .accessibilityHint(strings.dropImageHint)
    }

    private func fittedImageSize(_ imageSize: CGSize, in cellSize: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(cellSize.width / imageSize.width, cellSize.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}

private struct SelectionHandles: View {
    let transform: ImageTransform
    let baseSize: CGSize
    let cellSize: CGSize
    let strings: AppStrings
    let update: (ImageTransform) -> Void
    let commit: (ImageTransform) -> Void

    private var handles: [ResizeHandle] {
        transform.scalingMode == .proportional ? ResizeHandle.corners : ResizeHandle.allCases
    }

    var body: some View {
        let width = baseSize.width * transform.scaleX
        let height = baseSize.height * transform.scaleY
        let center = CGPoint(
            x: cellSize.width / 2 + transform.offsetX * cellSize.width,
            y: cellSize.height / 2 + transform.offsetY * cellSize.height
        )
        ZStack {
            Rectangle()
                .stroke(Color.accentColor, lineWidth: 1)
                .frame(width: width, height: height)
                .position(center)
                .allowsHitTesting(false)

            ForEach(handles) { handle in
                ResizeHandleView(
                    handle: handle,
                    transform: transform,
                    baseSize: baseSize,
                    center: center,
                    strings: strings,
                    update: update,
                    commit: commit
                )
                .position(handle.position(center: center, width: width, height: height))
            }
        }
    }
}

private enum ResizeHandle: String, CaseIterable, Identifiable {
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

    static let corners: [ResizeHandle] = [.topLeft, .topRight, .bottomRight, .bottomLeft]
    var id: Self { self }

    var horizontal: CGFloat {
        switch self {
        case .topLeft, .left, .bottomLeft: -1
        case .topRight, .right, .bottomRight: 1
        default: 0
        }
    }

    var vertical: CGFloat {
        switch self {
        case .topLeft, .top, .topRight: -1
        case .bottomLeft, .bottom, .bottomRight: 1
        default: 0
        }
    }

    func position(center: CGPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        CGPoint(x: center.x + horizontal * width / 2, y: center.y + vertical * height / 2)
    }
}

private struct ResizeHandleView: View {
    let handle: ResizeHandle
    let transform: ImageTransform
    let baseSize: CGSize
    let center: CGPoint
    let strings: AppStrings
    let update: (ImageTransform) -> Void
    let commit: (ImageTransform) -> Void

    @State private var resizeStart: ImageTransform?

    var body: some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            .frame(width: 11, height: 11)
            .contentShape(Rectangle().inset(by: -8))
            .highPriorityGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if resizeStart == nil { resizeStart = transform }
                        guard let start = resizeStart else { return }
                        update(resizedTransform(from: start, translation: value.translation))
                    }
                    .onEnded { _ in
                        guard let oldValue = resizeStart else { return }
                        commit(oldValue)
                        resizeStart = nil
                    }
            )
            .accessibilityLabel(strings.resizeHandle)
    }

    private func resizedTransform(from start: ImageTransform, translation: CGSize) -> ImageTransform {
        var next = start
        if start.scalingMode == .proportional {
            let width = max(baseSize.width, 1)
            let height = max(baseSize.height, 1)
            let projected = (
                translation.width * handle.horizontal * width
                + translation.height * handle.vertical * height
            ) / (width * width + height * height)
            let scale = max(0.1, start.scaleX + 2 * projected)
            next.scaleX = scale
            next.scaleY = scale
        } else {
            if handle.horizontal != 0 {
                next.scaleX = max(0.1, start.scaleX + 2 * translation.width * handle.horizontal / max(baseSize.width, 1))
            }
            if handle.vertical != 0 {
                next.scaleY = max(0.1, start.scaleY + 2 * translation.height * handle.vertical / max(baseSize.height, 1))
            }
        }
        return next
    }
}
