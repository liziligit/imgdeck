import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese
    case traditionalChinese
    case english

    static let storageKey = "appLanguage"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .english: "English"
        }
    }
}

struct AppStrings {
    let language: AppLanguage

    var appTitle: String { text("ImgDeck A4 图片拼接", "ImgDeck A4 圖片拼接", "ImgDeck A4 Image Layout") }
    var appSubtitle: String { text("选择 1–9 张图片和版式，可将图片移动到任意格位，\n未使用的位置保留白色。", "選擇 1–9 張圖片和版式，可將圖片移動到任意格位，\n未使用的位置保留白色。", "Choose 1–9 images and a layout. Move images to any available cell;\nunused cells remain white.") }
    func imagesAndLayout(remaining: Int) -> String {
        text("图片与版式（还可导入\(remaining)张）", "圖片與版式（還可匯入\(remaining)張）", "Images & Layout (\(remaining) more available)")
    }
    var selectedImages: String { text("已选图片列表", "已選圖片列表", "Selected images") }
    var addImages: String { text("添加图片", "加入圖片", "Add Images") }
    var remove: String { text("移除", "移除", "Remove") }
    var moveUp: String { text("上移", "上移", "Move Up") }
    var moveDown: String { text("下移", "下移", "Move Down") }
    var clear: String { text("清空", "清空", "Clear") }
    var layout: String { text("版式（行 × 列）", "版式（列 × 欄）", "Layout (Rows × Columns)") }
    var resolution: String { text("分辨率：", "解析度：", "Resolution:") }
    var unit: String { text("单位", "單位", "Unit") }
    var preview: String { text("预览", "預覽", "Preview") }
    var saveImage: String { text("保存图片", "儲存圖片", "Save Image") }
    var format: String { text("格式", "格式", "Format") }
    var status: String { text("状态", "狀態", "Status") }
    var a4Preview: String { text("A4 预览（210 × 297 mm）", "A4 預覽（210 × 297 mm）", "A4 Preview (210 × 297 mm)") }
    var ok: String { text("好", "好", "OK") }
    var settingsTitle: String { text("设置", "設定", "Settings") }
    var languageLabel: String { text("界面语言", "介面語言", "Interface Language") }
    var languageHint: String { text("语言切换会立即应用，并在下次启动时保留。", "語言切換會立即套用，並在下次啟動時保留。", "Language changes apply immediately and are remembered for the next launch.") }
    var blankPreview: String { text("空白 A4 版式预览", "空白 A4 版式預覽", "Blank A4 layout preview") }
    var resultPreview: String { text("A4 拼接结果预览", "A4 拼接結果預覽", "A4 layout result preview") }
    var layoutAccessibilitySuffix: String { text("版式", "版式", "layout") }
    var noSelection: String { text("所选图片：尚未选择", "所選圖片：尚未選擇", "Selected image: None") }
    var proportionalScaling: String { text("保持长宽比", "保持長寬比", "Keep Aspect Ratio") }
    var freeScaling: String { text("自由拉伸", "自由拉伸", "Free Transform") }
    var resetImage: String { text("重置当前图片", "重設目前圖片", "Reset Image") }
    var undoHint: String { text("撤销上一次调整（⌘Z）", "還原上一次調整（⌘Z）", "Undo the last adjustment (⌘Z)") }
    var redoHint: String { text("重做上一次调整（⇧⌘Z）", "重做上一次調整（⇧⌘Z）", "Redo the last adjustment (⇧⌘Z)") }
    var editImageHint: String { text("拖动图片调整位置，拖动控制点调整大小；蓝色虚线外的内容不会导出。", "拖動圖片調整位置，拖動控制點調整大小；藍色虛線外的內容不會匯出。", "Drag an image to reposition it and drag handles to resize. Content outside the blue dashed line is not exported.") }
    var adjustImageAction: String { text("调整图片", "調整圖片", "Adjust Image") }
    var changeScalingModeAction: String { text("更改拉伸方式", "更改拉伸方式", "Change Scaling Mode") }
    var resetImageAction: String { text("重置图片", "重設圖片", "Reset Image") }
    var imageCell: String { text("图片格", "圖片格", "Image cell") }
    var resizeHandle: String { text("缩放控制点", "縮放控制點", "Resize handle") }

    func selectedPath(_ path: String) -> String {
        text("所选图片：\(path)", "所選圖片：\(path)", "Selected image: \(path)")
    }

    func outputHint(width: Int, height: Int, fileSize: String) -> String {
        text("输出约 \(width) × \(height) 像素（\(fileSize)）", "輸出約 \(width) × \(height) 像素（\(fileSize)）", "Output approx. \(width) × \(height) pixels (\(fileSize))")
    }

    func unitName(_ unit: ResolutionUnit) -> String {
        switch unit {
        case .dpi: text("每英寸点数", "每英吋點數", "Dots per inch")
        case .dpcm: text("每厘米点数", "每公分點數", "Dots per centimeter")
        }
    }

    var initialStatus: String { text("请选择图片和版式", "請選擇圖片和版式", "Choose images and a layout") }
    var maximumReachedTitle: String { text("数量已满", "數量已滿", "Image Limit Reached") }
    var maximumReachedMessage: String { text("最多只能选择 9 张图片。", "最多只能選擇 9 張圖片。", "You can select up to 9 images.") }
    var chooseImagesPanelTitle: String { text("选择要拼接的图片", "選擇要拼接的圖片", "Choose Images") }
    var tooManyImagesTitle: String { text("图片过多", "圖片過多", "Too Many Images") }
    func remainingImagesMessage(_ count: Int) -> String { text("最多还能添加 \(count) 张图片。", "最多還能加入 \(count) 張圖片。", "You can add up to \(count) more images.") }
    var resolutionChanged: String { text("分辨率已调整；当前预览保持不变，点击“预览”后应用新尺寸。", "解析度已調整；目前預覽保持不變，按一下「預覽」後套用新尺寸。", "Resolution changed. The current preview is unchanged; click Preview to apply the new size.") }
    var noImagesTitle: String { text("尚未选择图片", "尚未選擇圖片", "No Images Selected") }
    var noImagesMessage: String { text("请至少添加 1 张图片。", "請至少加入 1 張圖片。", "Add at least one image.") }
    var renderFailedTitle: String { text("拼接失败", "拼接失敗", "Layout Failed") }
    var savePanelTitle: String { text("保存 A4 拼接图片", "儲存 A4 拼接圖片", "Save A4 Image") }
    var saveSuccessTitle: String { text("保存成功", "儲存成功", "Saved") }
    var saveSuccessMessage: String { text("A4 拼接图片已保存。", "A4 拼接圖片已儲存。", "The A4 image has been saved.") }
    var saveFailedTitle: String { text("保存失败", "儲存失敗", "Save Failed") }

    func previewStatus(width: Int, height: Int, shown: Int, blanks: Int, hidden: Int) -> String {
        text(
            "A4 预览 \(width) × \(height)：显示 \(shown) 张，空白 \(blanks) 个，未显示 \(hidden) 张",
            "A4 預覽 \(width) × \(height)：顯示 \(shown) 張，空白 \(blanks) 個，未顯示 \(hidden) 張",
            "A4 preview \(width) × \(height): \(shown) shown, \(blanks) blank, \(hidden) hidden"
        )
    }

    func savedPath(_ path: String) -> String { text("已保存到：\(path)", "已儲存至：\(path)", "Saved to: \(path)") }
    func selectionStatus(count: Int, layout: String, capacity: Int) -> String {
        text("已选择 \(count) 张图片；当前 \(layout) 版式可放 \(capacity) 张", "已選擇 \(count) 張圖片；目前 \(layout) 版式可放 \(capacity) 張", "\(count) image(s) selected; the \(layout) layout holds \(capacity)")
    }

    func errorMessage(_ error: Error) -> String {
        guard let error = error as? ImgDeckError else { return error.localizedDescription }
        switch error {
        case .invalidResolutionNumber:
            return text("请输入有效的分辨率数值。", "請輸入有效的解析度數值。", "Enter a valid resolution value.")
        case .resolutionOutOfRange(let unit, let maximum):
            let label = unit == .dpi ? "DPI" : unitName(unit)
            return text("\(label) 分辨率应在 1–\(maximum) 之间。", "\(label) 解析度應介於 1–\(maximum) 之間。", "\(label) resolution must be between 1 and \(maximum).")
        case .imageReadFailed(let filename):
            return text("无法读取图片：\(filename)", "無法讀取圖片：\(filename)", "Unable to read image: \(filename)")
        case .contextCreationFailed:
            return text("无法创建 A4 图像画布。", "無法建立 A4 圖像畫布。", "Unable to create the A4 image canvas.")
        case .exportFailed:
            return text("无法保存图片，请检查文件名和保存位置。", "無法儲存圖片，請檢查檔案名稱和儲存位置。", "Unable to save the image. Check the file name and destination.")
        }
    }

    private func text(_ simplified: String, _ traditional: String, _ english: String) -> String {
        switch language {
        case .simplifiedChinese: simplified
        case .traditionalChinese: traditional
        case .english: english
        }
    }
}
