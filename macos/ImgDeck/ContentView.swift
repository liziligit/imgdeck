import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ImageDeckViewModel()
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .simplifiedChinese
    @Environment(\.undoManager) private var undoManager

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
            .frame(width: 360)
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
        GroupBox(strings.imagesAndLayout) {
            VStack(spacing: 10) {
                List(selection: $viewModel.selectedID) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        Text("\(index + 1). \(item.url.lastPathComponent)")
                            .lineLimit(1)
                            .tag(item.id)
                            .help(item.url.path)
                    }
                }
                .frame(minHeight: 225, maxHeight: .infinity)
                .accessibilityLabel(strings.selectedImages)

                HStack(spacing: 8) {
                    Button(strings.addImages, systemImage: "photo.badge.plus", action: viewModel.chooseImages)
                        .frame(maxWidth: .infinity)
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
                        .disabled(viewModel.items.isEmpty)
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

                Text(strings.editImageHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
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
            ZStack {
                Color(nsColor: .darkGray).opacity(0.75)
                PageEditorCanvas(viewModel: viewModel, strings: strings)
                .frame(width: pageSize.width, height: pageSize.height)
                .background(.white)
                .overlay(Rectangle().stroke(Color(nsColor: .separatorColor), lineWidth: 1))
                .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
            }
        }
        .accessibilityLabel(viewModel.items.isEmpty ? strings.blankPreview : strings.resultPreview)
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

private struct PageEditorCanvas: View {
    @ObservedObject var viewModel: ImageDeckViewModel
    let strings: AppStrings

    var body: some View {
        GeometryReader { geometry in
            let cellSize = CGSize(
                width: geometry.size.width / CGFloat(viewModel.selectedLayout.columns),
                height: geometry.size.height / CGFloat(viewModel.selectedLayout.rows)
            )
            ZStack(alignment: .topLeading) {
                Color.white
                ForEach(0..<viewModel.selectedLayout.capacity, id: \.self) { index in
                    let row = index / viewModel.selectedLayout.columns
                    let column = index % viewModel.selectedLayout.columns
                    let item = viewModel.items.indices.contains(index) ? viewModel.items[index] : nil
                    EditableImageCell(
                        index: index,
                        item: item,
                        image: item.flatMap(viewModel.image),
                        transform: item.map { viewModel.transform(for: $0.id) } ?? .identity,
                        isSelected: item?.id == viewModel.selectedID,
                        cellSize: cellSize,
                        strings: strings,
                        select: { viewModel.selectedID = item?.id },
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
                    .zIndex(item?.id == viewModel.selectedID ? 1 : 0)
                }
            }
        }
    }
}

private struct EditableImageCell: View {
    let index: Int
    let item: ImageItem?
    let image: NSImage?
    let transform: ImageTransform
    let isSelected: Bool
    let cellSize: CGSize
    let strings: AppStrings
    let select: () -> Void
    let update: (ImageTransform) -> Void
    let commit: (ImageTransform) -> Void

    @State private var dragStart: ImageTransform?

    var body: some View {
        let baseSize = fittedImageSize(image?.size ?? .zero, in: cellSize)
        ZStack {
            Color.white
            if let image {
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
            } else {
                Text("\(index + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: cellSize.width, height: cellSize.height)
        .clipped()
        .contentShape(Rectangle())
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
