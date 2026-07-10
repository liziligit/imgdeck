import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese
    case traditionalChinese
    case english
    case japanese
    case korean
    case spanish
    case french
    case german
    case portugueseBrazil

    static let storageKey = "appLanguage"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .english: "English"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .portugueseBrazil: "Português (Brasil)"
        }
    }
}

struct AppStrings {
    let language: AppLanguage

    var appTitle: String { text("ImgDeck A4 图片拼接", "ImgDeck A4 圖片拼接", "ImgDeck A4 Image Layout", "ImgDeck A4 画像レイアウト", "ImgDeck A4 이미지 레이아웃") }
    var appSubtitle: String { text("选择 1–9 张图片和版式，可将图片移动到任意格位，\n未使用的位置保留白色。", "選擇 1–9 張圖片和版式，可將圖片移動到任意格位，\n未使用的位置保留白色。", "Choose 1–9 images and a layout. Move images to any available cell;\nunused cells remain white.", "1～9枚の画像とレイアウトを選び、画像を任意の枠へ移動できます。\n未使用の枠は白のままです。", "1~9장의 이미지와 레이아웃을 선택하고 원하는 칸으로 옮길 수 있습니다.\n사용하지 않은 칸은 흰색으로 유지됩니다.") }
    func imagesAndLayout(remaining: Int) -> String {
        switch language {
        case .spanish: return "Imágenes y diseño (se pueden añadir \(remaining) más)"
        case .french: return "Images et disposition (encore \(remaining) disponibles)"
        case .german: return "Bilder und Layout (noch \(remaining) verfügbar)"
        case .portugueseBrazil: return "Imagens e layout (mais \(remaining) disponíveis)"
        default: break
        }
        return text("图片与版式（还可导入\(remaining)张）", "圖片與版式（還可匯入\(remaining)張）", "Images & Layout (\(remaining) more available)", "画像とレイアウト（あと\(remaining)枚追加可能）", "이미지 및 레이아웃(\(remaining)장 더 추가 가능)")
    }
    var selectedImages: String { text("已选图片列表", "已選圖片列表", "Selected images", "選択した画像", "선택한 이미지") }
    var addImages: String { text("添加图片", "加入圖片", "Add Images", "画像を追加", "이미지 추가") }
    var remove: String { text("移除", "移除", "Remove", "削除", "제거") }
    var moveUp: String { text("上移", "上移", "Move Up", "上へ", "위로") }
    var moveDown: String { text("下移", "下移", "Move Down", "下へ", "아래로") }
    var clear: String { text("清空", "清空", "Clear", "すべて消去", "모두 지우기") }
    var layout: String { text("版式（行 × 列）", "版式（列 × 欄）", "Layout (Rows × Columns)", "レイアウト（行 × 列）", "레이아웃(행 × 열)") }
    var resolution: String { text("分辨率：", "解析度：", "Resolution:", "解像度：", "해상도:") }
    var unit: String { text("单位", "單位", "Unit", "単位", "단위") }
    var preview: String { text("预览", "預覽", "Preview", "プレビュー", "미리보기") }
    var saveImage: String { text("保存图片", "儲存圖片", "Save Image", "画像を保存", "이미지 저장") }
    var format: String { text("格式", "格式", "Format", "形式", "형식") }
    var status: String { text("状态", "狀態", "Status", "状態", "상태") }
    var a4Preview: String { text("A4 预览（210 × 297 mm）", "A4 預覽（210 × 297 mm）", "A4 Preview (210 × 297 mm)", "A4 プレビュー（210 × 297 mm）", "A4 미리보기(210 × 297 mm)") }
    var ok: String { text("好", "好", "OK", "OK", "확인") }
    var settingsTitle: String { text("设置", "設定", "Settings", "設定", "설정") }
    var languageLabel: String { text("界面语言", "介面語言", "Interface Language", "表示言語", "인터페이스 언어") }
    var languageHint: String { text("语言切换会立即应用，并在下次启动时保留。", "語言切換會立即套用，並在下次啟動時保留。", "Language changes apply immediately and are remembered for the next launch.", "言語の変更はすぐに適用され、次回起動時にも保持されます。", "언어 변경은 즉시 적용되며 다음 실행 시에도 유지됩니다.") }
    var blankPreview: String { text("空白 A4 版式预览", "空白 A4 版式預覽", "Blank A4 layout preview", "空のA4レイアウトプレビュー", "빈 A4 레이아웃 미리보기") }
    var resultPreview: String { text("A4 拼接结果预览", "A4 拼接結果預覽", "A4 layout result preview", "A4レイアウト結果プレビュー", "A4 레이아웃 결과 미리보기") }
    var layoutAccessibilitySuffix: String { text("版式", "版式", "layout", "レイアウト", "레이아웃") }
    var noSelection: String { text("所选图片：尚未选择", "所選圖片：尚未選擇", "Selected image: None", "選択画像：なし", "선택한 이미지: 없음") }
    var proportionalScaling: String { text("保持长宽比", "保持長寬比", "Keep Aspect Ratio", "縦横比を保持", "가로세로 비율 유지") }
    var freeScaling: String { text("自由拉伸", "自由拉伸", "Free Transform", "自由変形", "자유 변형") }
    var resetImage: String { text("重置当前图片", "重設目前圖片", "Reset Image", "画像をリセット", "이미지 재설정") }
    var undoHint: String { text("撤销上一次调整（⌘Z）", "還原上一次調整（⌘Z）", "Undo the last adjustment (⌘Z)", "直前の調整を取り消す（⌘Z）", "마지막 조정 실행 취소(⌘Z)") }
    var redoHint: String { text("重做上一次调整（⇧⌘Z）", "重做上一次調整（⇧⌘Z）", "Redo the last adjustment (⇧⌘Z)", "直前の調整をやり直す（⇧⌘Z）", "마지막 조정 다시 실행(⇧⌘Z)") }
    var editImageHint: String { text("拖动图片调整位置，拖动控制点调整大小；蓝色虚线外的内容不会导出。", "拖動圖片調整位置，拖動控制點調整大小；藍色虛線外的內容不會匯出。", "Drag an image to reposition it and drag handles to resize. Content outside the blue dashed line is not exported.", "画像をドラッグして位置を、ハンドルをドラッグしてサイズを調整します。青い破線の外側は書き出されません。", "이미지를 드래그해 위치를 조정하고 핸들을 드래그해 크기를 조정합니다. 파란 점선 밖의 내용은 내보내지 않습니다.") }
    var adjustImageAction: String { text("调整图片", "調整圖片", "Adjust Image", "画像を調整", "이미지 조정") }
    var changeScalingModeAction: String { text("更改拉伸方式", "更改拉伸方式", "Change Scaling Mode", "変形方法を変更", "변형 방식 변경") }
    var resetImageAction: String { text("重置图片", "重設圖片", "Reset Image", "画像をリセット", "이미지 재설정") }
    var replaceImageAction: String { text("替换图片", "替換圖片", "Replace Image", "画像を置き換え", "이미지 교체") }
    var rectangleMosaic: String { text("矩形马赛克", "矩形馬賽克", "Rectangle Mosaic", "矩形モザイク", "사각형 모자이크") }
    var applyMosaic: String { text("应用马赛克", "套用馬賽克", "Apply Mosaic", "モザイクを適用", "모자이크 적용") }
    var blockSize: String { text("块大小", "區塊大小", "Block Size", "ブロックサイズ", "블록 크기") }
    var mosaicDrawingHint: String { text("在 A4 预览中拖动以画出矩形区域，然后点击“应用马赛克”。", "在 A4 預覽中拖動以畫出矩形區域，然後點擊「套用馬賽克」。", "Drag on the A4 preview to draw a rectangle, then click Apply Mosaic.", "A4プレビュー上をドラッグして矩形を描き、モザイクを適用します。", "A4 미리보기에서 사각형을 그린 뒤 모자이크 적용을 클릭하세요.") }
    var fitPage: String { text("适应页面", "適應頁面", "Fit Page", "ページに合わせる", "페이지에 맞춤") }
    var zoomIn: String { text("放大 5%", "放大 5%", "Zoom In 5%", "5%拡大", "5% 확대") }
    var zoomOut: String { text("缩小 5%", "縮小 5%", "Zoom Out 5%", "5%縮小", "5% 축소") }
    var addMosaicAction: String { text("添加马赛克", "加入馬賽克", "Add Mosaic", "モザイクを追加", "모자이크 추가") }
    var changeMosaicBlockSizeAction: String { text("更改马赛克块大小", "更改馬賽克區塊大小", "Change Mosaic Block Size", "モザイクのブロックサイズを変更", "모자이크 블록 크기 변경") }
    var imageCell: String { text("图片格", "圖片格", "Image cell", "画像枠", "이미지 칸") }
    var resizeHandle: String { text("缩放控制点", "縮放控制點", "Resize handle", "サイズ変更ハンドル", "크기 조절 핸들") }
    var dropImageHint: String { text("从 Finder 拖入图片以放入或替换此格", "從 Finder 拖入圖片以放入或替換此格", "Drag an image from Finder to place or replace this cell", "Finderから画像をドラッグしてこの枠に追加または置換します", "Finder에서 이미지를 드래그하여 이 칸에 넣거나 교체합니다") }

    func selectedPath(_ path: String) -> String {
        switch language {
        case .spanish: return "Imagen seleccionada: \(path)"
        case .french: return "Image sélectionnée : \(path)"
        case .german: return "Ausgewähltes Bild: \(path)"
        case .portugueseBrazil: return "Imagem selecionada: \(path)"
        default: break
        }
        return text("所选图片：\(path)", "所選圖片：\(path)", "Selected image: \(path)", "選択画像：\(path)", "선택한 이미지: \(path)")
    }

    func outputHint(width: Int, height: Int, fileSize: String) -> String {
        switch language {
        case .spanish: return "Salida aprox. de \(width) × \(height) píxeles (\(fileSize))"
        case .french: return "Sortie d’environ \(width) × \(height) pixels (\(fileSize))"
        case .german: return "Ausgabe ca. \(width) × \(height) Pixel (\(fileSize))"
        case .portugueseBrazil: return "Saída aprox. de \(width) × \(height) pixels (\(fileSize))"
        default: break
        }
        return text("输出约 \(width) × \(height) 像素（\(fileSize)）", "輸出約 \(width) × \(height) 像素（\(fileSize)）", "Output approx. \(width) × \(height) pixels (\(fileSize))", "出力：約\(width) × \(height)ピクセル（\(fileSize)）", "출력 약 \(width) × \(height)픽셀(\(fileSize))")
    }

    func unitName(_ unit: ResolutionUnit) -> String {
        switch unit {
        case .dpi: text("每英寸点数", "每英吋點數", "Dots per inch", "1インチあたりのドット数", "인치당 도트 수")
        case .dpcm: text("每厘米点数", "每公分點數", "Dots per centimeter", "1センチメートルあたりのドット数", "센티미터당 도트 수")
        }
    }

    var initialStatus: String { text("请选择图片和版式", "請選擇圖片和版式", "Choose images and a layout", "画像とレイアウトを選択してください", "이미지와 레이아웃을 선택하세요") }
    var maximumReachedTitle: String { text("数量已满", "數量已滿", "Image Limit Reached", "画像数の上限", "이미지 수 한도 도달") }
    var maximumReachedMessage: String { text("最多只能选择 9 张图片。", "最多只能選擇 9 張圖片。", "You can select up to 9 images.", "選択できる画像は最大9枚です。", "이미지는 최대 9장까지 선택할 수 있습니다.") }
    var chooseImagesPanelTitle: String { text("选择要拼接的图片", "選擇要拼接的圖片", "Choose Images", "レイアウトする画像を選択", "배치할 이미지 선택") }
    var tooManyImagesTitle: String { text("图片过多", "圖片過多", "Too Many Images", "画像が多すぎます", "이미지가 너무 많습니다") }
    func remainingImagesMessage(_ count: Int) -> String {
        switch language {
        case .spanish: return "Puedes añadir hasta \(count) imágenes más."
        case .french: return "Vous pouvez encore ajouter jusqu’à \(count) images."
        case .german: return "Du kannst noch bis zu \(count) Bilder hinzufügen."
        case .portugueseBrazil: return "Você pode adicionar mais \(count) imagens."
        default: return text("最多还能添加 \(count) 张图片。", "最多還能加入 \(count) 張圖片。", "You can add up to \(count) more images.", "あと\(count)枚まで画像を追加できます。", "이미지를 최대 \(count)장 더 추가할 수 있습니다.")
        }
    }
    var resolutionChanged: String { text("分辨率已调整；当前预览保持不变，点击“预览”后应用新尺寸。", "解析度已調整；目前預覽保持不變，按一下「預覽」後套用新尺寸。", "Resolution changed. The current preview is unchanged; click Preview to apply the new size.", "解像度を変更しました。現在のプレビューは変わりません。「プレビュー」をクリックすると新しいサイズが適用されます。", "해상도가 변경되었습니다. 현재 미리보기는 유지되며 ‘미리보기’를 클릭하면 새 크기가 적용됩니다.") }
    var noImagesTitle: String { text("尚未选择图片", "尚未選擇圖片", "No Images Selected", "画像が選択されていません", "선택한 이미지 없음") }
    var noImagesMessage: String { text("请至少添加 1 张图片。", "請至少加入 1 張圖片。", "Add at least one image.", "画像を1枚以上追加してください。", "이미지를 1장 이상 추가하세요.") }
    var renderFailedTitle: String { text("拼接失败", "拼接失敗", "Layout Failed", "レイアウトに失敗しました", "레이아웃 실패") }
    var savePanelTitle: String { text("保存 A4 拼接图片", "儲存 A4 拼接圖片", "Save A4 Image", "A4レイアウト画像を保存", "A4 레이아웃 이미지 저장") }
    var saveSuccessTitle: String { text("保存成功", "儲存成功", "Saved", "保存しました", "저장 완료") }
    var saveSuccessMessage: String { text("A4 拼接图片已保存。", "A4 拼接圖片已儲存。", "The A4 image has been saved.", "A4レイアウト画像を保存しました。", "A4 레이아웃 이미지를 저장했습니다.") }
    var saveFailedTitle: String { text("保存失败", "儲存失敗", "Save Failed", "保存に失敗しました", "저장 실패") }

    func previewStatus(width: Int, height: Int, shown: Int, blanks: Int, hidden: Int) -> String {
        switch language {
        case .spanish: return "Vista previa A4 \(width) × \(height): \(shown) visibles, \(blanks) vacías, \(hidden) ocultas"
        case .french: return "Aperçu A4 \(width) × \(height) : \(shown) affichées, \(blanks) vides, \(hidden) masquées"
        case .german: return "A4-Vorschau \(width) × \(height): \(shown) sichtbar, \(blanks) leer, \(hidden) ausgeblendet"
        case .portugueseBrazil: return "Prévia A4 \(width) × \(height): \(shown) exibidas, \(blanks) vazias, \(hidden) ocultas"
        default: break
        }
        return text(
            "A4 预览 \(width) × \(height)：显示 \(shown) 张，空白 \(blanks) 个，未显示 \(hidden) 张",
            "A4 預覽 \(width) × \(height)：顯示 \(shown) 張，空白 \(blanks) 個，未顯示 \(hidden) 張",
            "A4 preview \(width) × \(height): \(shown) shown, \(blanks) blank, \(hidden) hidden",
            "A4プレビュー \(width) × \(height)：表示\(shown)枚、空き\(blanks)枠、非表示\(hidden)枚",
            "A4 미리보기 \(width) × \(height): 표시 \(shown)장, 빈 칸 \(blanks)개, 숨김 \(hidden)장"
        )
    }

    func savedPath(_ path: String) -> String {
        switch language {
        case .spanish: return "Guardado en: \(path)"
        case .french: return "Enregistré dans : \(path)"
        case .german: return "Gespeichert unter: \(path)"
        case .portugueseBrazil: return "Salvo em: \(path)"
        default: return text("已保存到：\(path)", "已儲存至：\(path)", "Saved to: \(path)", "保存先：\(path)", "저장 위치: \(path)")
        }
    }
    func selectionStatus(count: Int, layout: String, capacity: Int) -> String {
        switch language {
        case .spanish: return "\(count) imágenes seleccionadas; el diseño \(layout) admite \(capacity)"
        case .french: return "\(count) images sélectionnées ; la disposition \(layout) en contient \(capacity)"
        case .german: return "\(count) Bilder ausgewählt; das Layout \(layout) fasst \(capacity)"
        case .portugueseBrazil: return "\(count) imagens selecionadas; o layout \(layout) comporta \(capacity)"
        default: break
        }
        return text("已选择 \(count) 张图片；当前 \(layout) 版式可放 \(capacity) 张", "已選擇 \(count) 張圖片；目前 \(layout) 版式可放 \(capacity) 張", "\(count) image(s) selected; the \(layout) layout holds \(capacity)", "\(count)枚の画像を選択中。\(layout)レイアウトには\(capacity)枚配置できます", "이미지 \(count)장 선택됨; \(layout) 레이아웃에는 \(capacity)장을 배치할 수 있습니다")
    }

    func errorMessage(_ error: Error) -> String {
        guard let error = error as? ImgDeckError else { return error.localizedDescription }
        switch error {
        case .invalidResolutionNumber:
            return text("请输入有效的分辨率数值。", "請輸入有效的解析度數值。", "Enter a valid resolution value.", "有効な解像度を入力してください。", "올바른 해상도 값을 입력하세요.")
        case .resolutionOutOfRange(let unit, let maximum):
            let label = unit == .dpi ? "DPI" : unitName(unit)
            switch language {
            case .spanish: return "La resolución \(label) debe estar entre 1 y \(maximum)."
            case .french: return "La résolution \(label) doit être comprise entre 1 et \(maximum)."
            case .german: return "Die \(label)-Auflösung muss zwischen 1 und \(maximum) liegen."
            case .portugueseBrazil: return "A resolução \(label) deve estar entre 1 e \(maximum)."
            default: break
            }
            return text("\(label) 分辨率应在 1–\(maximum) 之间。", "\(label) 解析度應介於 1–\(maximum) 之間。", "\(label) resolution must be between 1 and \(maximum).", "\(label)の解像度は1～\(maximum)の範囲にしてください。", "\(label) 해상도는 1~\(maximum) 사이여야 합니다.")
        case .imageReadFailed(let filename):
            switch language {
            case .spanish: return "No se puede leer la imagen: \(filename)"
            case .french: return "Impossible de lire l’image : \(filename)"
            case .german: return "Bild kann nicht gelesen werden: \(filename)"
            case .portugueseBrazil: return "Não foi possível ler a imagem: \(filename)"
            default: break
            }
            return text("无法读取图片：\(filename)", "無法讀取圖片：\(filename)", "Unable to read image: \(filename)", "画像を読み込めません：\(filename)", "이미지를 읽을 수 없습니다: \(filename)")
        case .contextCreationFailed:
            return text("无法创建 A4 图像画布。", "無法建立 A4 圖像畫布。", "Unable to create the A4 image canvas.", "A4画像キャンバスを作成できません。", "A4 이미지 캔버스를 만들 수 없습니다.")
        case .exportFailed:
            return text("无法保存图片，请检查文件名和保存位置。", "無法儲存圖片，請檢查檔案名稱和儲存位置。", "Unable to save the image. Check the file name and destination.", "画像を保存できません。ファイル名と保存先を確認してください。", "이미지를 저장할 수 없습니다. 파일 이름과 저장 위치를 확인하세요.")
        }
    }

    private func text(_ simplified: String, _ traditional: String, _ english: String, _ japanese: String, _ korean: String) -> String {
        switch language {
        case .simplifiedChinese: simplified
        case .traditionalChinese: traditional
        case .english: english
        case .japanese: japanese
        case .korean: korean
        case .spanish, .french, .german, .portugueseBrazil:
            additionalTranslations[language]?[english] ?? english
        }
    }

    private var additionalTranslations: [AppLanguage: [String: String]] {
        [
            .spanish: [
                "ImgDeck A4 Image Layout": "ImgDeck Diseño de imágenes A4",
                "Choose 1–9 images and a layout. Move images to any available cell;\nunused cells remain white.": "Elige de 1 a 9 imágenes y un diseño; muévelas a cualquier celda.\nLas celdas sin usar permanecen blancas.",
                "Selected images": "Imágenes seleccionadas", "Add Images": "Añadir imágenes", "Remove": "Eliminar",
                "Move Up": "Subir", "Move Down": "Bajar", "Clear": "Borrar todo",
                "Layout (Rows × Columns)": "Diseño (filas × columnas)", "Resolution:": "Resolución:",
                "Unit": "Unidad", "Preview": "Vista previa", "Save Image": "Guardar imagen", "Format": "Formato", "Status": "Estado",
                "A4 Preview (210 × 297 mm)": "Vista previa A4 (210 × 297 mm)", "OK": "Aceptar", "Settings": "Ajustes",
                "Interface Language": "Idioma de la interfaz", "Language changes apply immediately and are remembered for the next launch.": "Los cambios de idioma se aplican de inmediato y se conservan para el próximo inicio.",
                "Blank A4 layout preview": "Vista previa del diseño A4 vacío", "A4 layout result preview": "Vista previa del resultado A4", "layout": "diseño",
                "Selected image: None": "Imagen seleccionada: ninguna", "Keep Aspect Ratio": "Mantener proporción", "Free Transform": "Transformación libre",
                "Reset Image": "Restablecer imagen", "Undo the last adjustment (⌘Z)": "Deshacer el último ajuste (⌘Z)", "Redo the last adjustment (⇧⌘Z)": "Rehacer el último ajuste (⇧⌘Z)",
                "Drag an image to reposition it and drag handles to resize. Content outside the blue dashed line is not exported.": "Arrastra una imagen para cambiar su posición y los controladores para redimensionarla. El contenido fuera de la línea azul discontinua no se exporta.",
                "Adjust Image": "Ajustar imagen", "Change Scaling Mode": "Cambiar modo de escala", "Replace Image": "Reemplazar imagen", "Image cell": "Celda de imagen", "Resize handle": "Controlador de tamaño",
                "Drag an image from Finder to place or replace this cell": "Arrastra una imagen desde Finder para colocarla o reemplazar esta celda",
                "Rectangle Mosaic": "Mosaico rectangular", "Block Size": "Tamaño del bloque", "Drag on the A4 preview to add a rectangular mosaic.": "Arrastra sobre la vista previa A4 para añadir un mosaico rectangular.",
                "Apply Mosaic": "Aplicar mosaico", "Drag on the A4 preview to draw a rectangle, then click Apply Mosaic.": "Arrastra sobre la vista previa A4 para dibujar un rectángulo y luego pulsa Aplicar mosaico.",
                "Fit Page": "Ajustar a la página", "Zoom In 5%": "Ampliar 5%", "Zoom Out 5%": "Reducir 5%", "Add Mosaic": "Añadir mosaico", "Change Mosaic Block Size": "Cambiar tamaño del bloque de mosaico",
                "Dots per inch": "Puntos por pulgada", "Dots per centimeter": "Puntos por centímetro", "Choose images and a layout": "Elige imágenes y un diseño",
                "Image Limit Reached": "Límite de imágenes alcanzado", "You can select up to 9 images.": "Puedes seleccionar hasta 9 imágenes.", "Choose Images": "Elegir imágenes",
                "Too Many Images": "Demasiadas imágenes", "Resolution changed. The current preview is unchanged; click Preview to apply the new size.": "La resolución ha cambiado. La vista previa actual no cambia; haz clic en Vista previa para aplicar el nuevo tamaño.",
                "No Images Selected": "No hay imágenes seleccionadas", "Add at least one image.": "Añade al menos una imagen.", "Layout Failed": "Error de diseño",
                "Save A4 Image": "Guardar imagen A4", "Saved": "Guardado", "The A4 image has been saved.": "La imagen A4 se ha guardado.", "Save Failed": "Error al guardar",
                "Enter a valid resolution value.": "Introduce un valor de resolución válido.", "Unable to create the A4 image canvas.": "No se puede crear el lienzo A4.",
                "Unable to save the image. Check the file name and destination.": "No se puede guardar la imagen. Comprueba el nombre del archivo y el destino."
            ],
            .french: [
                "ImgDeck A4 Image Layout": "ImgDeck Mise en page d’images A4",
                "Choose 1–9 images and a layout. Move images to any available cell;\nunused cells remain white.": "Choisissez 1 à 9 images et placez-les dans la case voulue.\nLes cases inutilisées restent blanches.",
                "Selected images": "Images sélectionnées", "Add Images": "Ajouter des images", "Remove": "Supprimer", "Move Up": "Monter", "Move Down": "Descendre", "Clear": "Tout effacer",
                "Layout (Rows × Columns)": "Disposition (lignes × colonnes)", "Resolution:": "Résolution :", "Unit": "Unité", "Preview": "Aperçu", "Save Image": "Enregistrer l’image", "Format": "Format", "Status": "État",
                "A4 Preview (210 × 297 mm)": "Aperçu A4 (210 × 297 mm)", "OK": "OK", "Settings": "Réglages", "Interface Language": "Langue de l’interface",
                "Language changes apply immediately and are remembered for the next launch.": "Les changements de langue s’appliquent immédiatement et sont conservés au prochain lancement.",
                "Blank A4 layout preview": "Aperçu de la disposition A4 vide", "A4 layout result preview": "Aperçu du résultat A4", "layout": "disposition", "Selected image: None": "Image sélectionnée : aucune",
                "Keep Aspect Ratio": "Conserver les proportions", "Free Transform": "Transformation libre", "Reset Image": "Réinitialiser l’image",
                "Undo the last adjustment (⌘Z)": "Annuler le dernier réglage (⌘Z)", "Redo the last adjustment (⇧⌘Z)": "Rétablir le dernier réglage (⇧⌘Z)",
                "Drag an image to reposition it and drag handles to resize. Content outside the blue dashed line is not exported.": "Faites glisser une image pour la repositionner et les poignées pour la redimensionner. Le contenu hors de la ligne bleue en pointillés n’est pas exporté.",
                "Adjust Image": "Ajuster l’image", "Change Scaling Mode": "Changer le mode de mise à l’échelle", "Replace Image": "Remplacer l’image", "Image cell": "Case d’image", "Resize handle": "Poignée de redimensionnement",
                "Drag an image from Finder to place or replace this cell": "Faites glisser une image depuis Finder pour placer ou remplacer cette case",
                "Rectangle Mosaic": "Mosaïque rectangulaire", "Block Size": "Taille du bloc", "Drag on the A4 preview to add a rectangular mosaic.": "Faites glisser sur l’aperçu A4 pour ajouter une mosaïque rectangulaire.",
                "Apply Mosaic": "Appliquer la mosaïque", "Drag on the A4 preview to draw a rectangle, then click Apply Mosaic.": "Faites glisser sur l’aperçu A4 pour dessiner un rectangle, puis cliquez sur Appliquer la mosaïque.",
                "Fit Page": "Ajuster à la page", "Zoom In 5%": "Agrandir de 5%", "Zoom Out 5%": "Réduire de 5%", "Add Mosaic": "Ajouter une mosaïque", "Change Mosaic Block Size": "Modifier la taille du bloc de mosaïque",
                "Dots per inch": "Points par pouce", "Dots per centimeter": "Points par centimètre", "Choose images and a layout": "Choisissez des images et une disposition",
                "Image Limit Reached": "Limite d’images atteinte", "You can select up to 9 images.": "Vous pouvez sélectionner jusqu’à 9 images.", "Choose Images": "Choisir des images", "Too Many Images": "Trop d’images",
                "Resolution changed. The current preview is unchanged; click Preview to apply the new size.": "La résolution a changé. L’aperçu actuel reste inchangé ; cliquez sur Aperçu pour appliquer la nouvelle taille.",
                "No Images Selected": "Aucune image sélectionnée", "Add at least one image.": "Ajoutez au moins une image.", "Layout Failed": "Échec de la disposition", "Save A4 Image": "Enregistrer l’image A4",
                "Saved": "Enregistré", "The A4 image has been saved.": "L’image A4 a été enregistrée.", "Save Failed": "Échec de l’enregistrement", "Enter a valid resolution value.": "Saisissez une résolution valide.",
                "Unable to create the A4 image canvas.": "Impossible de créer le canevas A4.", "Unable to save the image. Check the file name and destination.": "Impossible d’enregistrer l’image. Vérifiez le nom du fichier et l’emplacement."
            ],
            .german: [
                "ImgDeck A4 Image Layout": "ImgDeck A4-Bildlayout",
                "Choose 1–9 images and a layout. Move images to any available cell;\nunused cells remain white.": "Wähle 1–9 Bilder und verschiebe sie in beliebige freie Felder.\nUngenutzte Felder bleiben weiß.",
                "Selected images": "Ausgewählte Bilder", "Add Images": "Bilder hinzufügen", "Remove": "Entfernen", "Move Up": "Nach oben", "Move Down": "Nach unten", "Clear": "Alles löschen",
                "Layout (Rows × Columns)": "Layout (Zeilen × Spalten)", "Resolution:": "Auflösung:", "Unit": "Einheit", "Preview": "Vorschau", "Save Image": "Bild speichern", "Format": "Format", "Status": "Status",
                "A4 Preview (210 × 297 mm)": "A4-Vorschau (210 × 297 mm)", "OK": "OK", "Settings": "Einstellungen", "Interface Language": "Oberflächensprache",
                "Language changes apply immediately and are remembered for the next launch.": "Sprachänderungen werden sofort angewendet und beim nächsten Start beibehalten.",
                "Blank A4 layout preview": "Leere A4-Layoutvorschau", "A4 layout result preview": "A4-Ergebnisvorschau", "layout": "Layout", "Selected image: None": "Ausgewähltes Bild: keines",
                "Keep Aspect Ratio": "Seitenverhältnis beibehalten", "Free Transform": "Frei transformieren", "Reset Image": "Bild zurücksetzen",
                "Undo the last adjustment (⌘Z)": "Letzte Anpassung rückgängig machen (⌘Z)", "Redo the last adjustment (⇧⌘Z)": "Letzte Anpassung wiederholen (⇧⌘Z)",
                "Drag an image to reposition it and drag handles to resize. Content outside the blue dashed line is not exported.": "Ziehe ein Bild zum Verschieben und die Griffe zum Ändern der Größe. Inhalte außerhalb der blauen gestrichelten Linie werden nicht exportiert.",
                "Adjust Image": "Bild anpassen", "Change Scaling Mode": "Skalierungsmodus ändern", "Replace Image": "Bild ersetzen", "Image cell": "Bildfeld", "Resize handle": "Größenänderungsgriff",
                "Drag an image from Finder to place or replace this cell": "Ziehe ein Bild aus dem Finder hierher, um dieses Feld zu füllen oder zu ersetzen",
                "Rectangle Mosaic": "Rechteckmosaik", "Block Size": "Blockgröße", "Drag on the A4 preview to add a rectangular mosaic.": "Ziehe im A4-Vorschaubereich, um ein rechteckiges Mosaik hinzuzufügen.",
                "Apply Mosaic": "Mosaik anwenden", "Drag on the A4 preview to draw a rectangle, then click Apply Mosaic.": "Ziehe in der A4-Vorschau ein Rechteck und klicke dann auf Mosaik anwenden.",
                "Fit Page": "An Seite anpassen", "Zoom In 5%": "Um 5% vergrößern", "Zoom Out 5%": "Um 5% verkleinern", "Add Mosaic": "Mosaik hinzufügen", "Change Mosaic Block Size": "Mosaikblockgröße ändern",
                "Dots per inch": "Punkte pro Zoll", "Dots per centimeter": "Punkte pro Zentimeter", "Choose images and a layout": "Bilder und Layout auswählen",
                "Image Limit Reached": "Bildlimit erreicht", "You can select up to 9 images.": "Du kannst bis zu 9 Bilder auswählen.", "Choose Images": "Bilder auswählen", "Too Many Images": "Zu viele Bilder",
                "Resolution changed. The current preview is unchanged; click Preview to apply the new size.": "Die Auflösung wurde geändert. Die aktuelle Vorschau bleibt unverändert; klicke auf Vorschau, um die neue Größe anzuwenden.",
                "No Images Selected": "Keine Bilder ausgewählt", "Add at least one image.": "Füge mindestens ein Bild hinzu.", "Layout Failed": "Layout fehlgeschlagen", "Save A4 Image": "A4-Bild speichern",
                "Saved": "Gespeichert", "The A4 image has been saved.": "Das A4-Bild wurde gespeichert.", "Save Failed": "Speichern fehlgeschlagen", "Enter a valid resolution value.": "Gib einen gültigen Auflösungswert ein.",
                "Unable to create the A4 image canvas.": "Die A4-Bildfläche kann nicht erstellt werden.", "Unable to save the image. Check the file name and destination.": "Das Bild kann nicht gespeichert werden. Prüfe Dateiname und Speicherort."
            ],
            .portugueseBrazil: [
                "ImgDeck A4 Image Layout": "ImgDeck Layout de imagens A4",
                "Choose 1–9 images and a layout. Move images to any available cell;\nunused cells remain white.": "Escolha de 1 a 9 imagens e mova-as para qualquer espaço.\nOs espaços não usados permanecem brancos.",
                "Selected images": "Imagens selecionadas", "Add Images": "Adicionar imagens", "Remove": "Remover", "Move Up": "Mover para cima", "Move Down": "Mover para baixo", "Clear": "Limpar tudo",
                "Layout (Rows × Columns)": "Layout (linhas × colunas)", "Resolution:": "Resolução:", "Unit": "Unidade", "Preview": "Prévia", "Save Image": "Salvar imagem", "Format": "Formato", "Status": "Status",
                "A4 Preview (210 × 297 mm)": "Prévia A4 (210 × 297 mm)", "OK": "OK", "Settings": "Ajustes", "Interface Language": "Idioma da interface",
                "Language changes apply immediately and are remembered for the next launch.": "As alterações de idioma são aplicadas imediatamente e mantidas na próxima inicialização.",
                "Blank A4 layout preview": "Prévia do layout A4 vazio", "A4 layout result preview": "Prévia do resultado A4", "layout": "layout", "Selected image: None": "Imagem selecionada: nenhuma",
                "Keep Aspect Ratio": "Manter proporção", "Free Transform": "Transformação livre", "Reset Image": "Redefinir imagem",
                "Undo the last adjustment (⌘Z)": "Desfazer o último ajuste (⌘Z)", "Redo the last adjustment (⇧⌘Z)": "Refazer o último ajuste (⇧⌘Z)",
                "Drag an image to reposition it and drag handles to resize. Content outside the blue dashed line is not exported.": "Arraste uma imagem para reposicioná-la e as alças para redimensioná-la. O conteúdo fora da linha azul tracejada não será exportado.",
                "Adjust Image": "Ajustar imagem", "Change Scaling Mode": "Alterar modo de escala", "Replace Image": "Substituir imagem", "Image cell": "Espaço da imagem", "Resize handle": "Alça de redimensionamento",
                "Drag an image from Finder to place or replace this cell": "Arraste uma imagem do Finder para inserir ou substituir este espaço",
                "Rectangle Mosaic": "Mosaico retangular", "Block Size": "Tamanho do bloco", "Drag on the A4 preview to add a rectangular mosaic.": "Arraste na prévia A4 para adicionar um mosaico retangular.",
                "Apply Mosaic": "Aplicar mosaico", "Drag on the A4 preview to draw a rectangle, then click Apply Mosaic.": "Arraste na prévia A4 para desenhar um retângulo e clique em Aplicar mosaico.",
                "Fit Page": "Ajustar à página", "Zoom In 5%": "Ampliar 5%", "Zoom Out 5%": "Reduzir 5%", "Add Mosaic": "Adicionar mosaico", "Change Mosaic Block Size": "Alterar tamanho do bloco de mosaico",
                "Dots per inch": "Pontos por polegada", "Dots per centimeter": "Pontos por centímetro", "Choose images and a layout": "Escolha imagens e um layout",
                "Image Limit Reached": "Limite de imagens atingido", "You can select up to 9 images.": "Você pode selecionar até 9 imagens.", "Choose Images": "Escolher imagens", "Too Many Images": "Imagens demais",
                "Resolution changed. The current preview is unchanged; click Preview to apply the new size.": "A resolução foi alterada. A prévia atual permanece igual; clique em Prévia para aplicar o novo tamanho.",
                "No Images Selected": "Nenhuma imagem selecionada", "Add at least one image.": "Adicione pelo menos uma imagem.", "Layout Failed": "Falha no layout", "Save A4 Image": "Salvar imagem A4",
                "Saved": "Salvo", "The A4 image has been saved.": "A imagem A4 foi salva.", "Save Failed": "Falha ao salvar", "Enter a valid resolution value.": "Insira um valor de resolução válido.",
                "Unable to create the A4 image canvas.": "Não foi possível criar a tela de imagem A4.", "Unable to save the image. Check the file name and destination.": "Não foi possível salvar a imagem. Verifique o nome do arquivo e o destino."
            ]
        ]
    }
}
