import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ImageDeckViewModel()
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .simplifiedChinese

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(strings.appTitle)
                    .font(.system(size: 26, weight: .bold))
                Text(strings.appSubtitle)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                controls
                    .frame(width: 360)
                    .frame(maxHeight: .infinity, alignment: .top)
                previewPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
        .onAppear { viewModel.setLanguage(language) }
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
        GroupBox(strings.a4Preview) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.selectedPath)
                    .lineLimit(2)
                    .font(.callout)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)

                A4Preview(
                    image: viewModel.previewImage,
                    layout: viewModel.selectedLayout,
                    strings: strings
                )
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

private struct A4Preview: View {
    let image: NSImage?
    let layout: LayoutOption
    let strings: AppStrings

    var body: some View {
        GeometryReader { geometry in
            let pageSize = fittedPageSize(in: geometry.size)
            ZStack {
                Color(nsColor: .darkGray).opacity(0.75)
                Group {
                    if let image {
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                    } else {
                        PlaceholderPage(layout: layout)
                    }
                }
                .frame(width: pageSize.width, height: pageSize.height)
                .background(.white)
                .overlay(Rectangle().stroke(Color(nsColor: .separatorColor), lineWidth: 1))
                .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
            }
        }
        .accessibilityLabel(image == nil ? strings.blankPreview : strings.resultPreview)
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

private struct PlaceholderPage: View {
    let layout: LayoutOption

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
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
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)

                ForEach(0..<layout.capacity, id: \.self) { index in
                    let row = index / layout.columns
                    let column = index % layout.columns
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .position(
                            x: geometry.size.width * (CGFloat(column) + 0.5) / CGFloat(layout.columns),
                            y: geometry.size.height * (CGFloat(row) + 0.5) / CGFloat(layout.rows)
                        )
                }
            }
        }
    }
}
