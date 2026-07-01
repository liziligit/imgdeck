import Foundation

struct LayoutOption: Identifiable, Hashable {
    let id: String
    let rows: Int
    let columns: Int

    var capacity: Int { rows * columns }
    var label: String { "\(rows)×\(columns)" }

    static let all: [LayoutOption] = [
        .init(id: "1x1", rows: 1, columns: 1),
        .init(id: "2x1", rows: 2, columns: 1),
        .init(id: "1x2", rows: 1, columns: 2),
        .init(id: "3x1", rows: 3, columns: 1),
        .init(id: "1x3", rows: 1, columns: 3),
        .init(id: "2x2", rows: 2, columns: 2),
        .init(id: "3x2", rows: 3, columns: 2),
        .init(id: "3x3", rows: 3, columns: 3),
    ]
}

enum ResolutionUnit: String, CaseIterable, Identifiable {
    case dpi = "每英寸点数"
    case dpcm = "每厘米点数"

    var id: Self { self }
    var maximum: Double { self == .dpi ? 600 : 240 }
    var errorLabel: String { self == .dpi ? "DPI" : rawValue }
}

enum OutputFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPG"

    var id: Self { self }
    var fileExtension: String { self == .png ? "png" : "jpg" }
}

struct ImageItem: Identifiable, Equatable {
    let id: UUID
    let url: URL

    init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
    }

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum A4Size {
    static func pixels(resolution: Double, unit: ResolutionUnit) throws -> (width: Int, height: Int) {
        guard resolution >= 1, resolution <= unit.maximum else {
            throw ImgDeckError.invalidResolution(
                "\(unit.errorLabel) 分辨率应在 1–\(Int(unit.maximum)) 之间。"
            )
        }

        if unit == .dpi {
            return (Int((210 / 25.4 * resolution).rounded()), Int((297 / 25.4 * resolution).rounded()))
        }
        return (Int((21 * resolution).rounded()), Int((29.7 * resolution).rounded()))
    }
}

enum ImgDeckError: LocalizedError {
    case invalidResolution(String)
    case imageReadFailed(String)
    case contextCreationFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .invalidResolution(let message), .imageReadFailed(let message):
            return message
        case .contextCreationFailed:
            return "无法创建 A4 图像画布。"
        case .exportFailed:
            return "无法保存图片，请检查文件名和保存位置。"
        }
    }
}
