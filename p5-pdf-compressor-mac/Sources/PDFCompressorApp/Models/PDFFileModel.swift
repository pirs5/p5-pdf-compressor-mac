import Foundation

enum CompressionPreset: String, CaseIterable, Identifiable {
    case strong = "Strong"
    case middle = "Middle"
    case low = "Low"

    var id: String { rawValue }

    var ghostscriptValue: String {
        switch self {
        case .strong: return "/screen"
        case .middle: return "/ebook"
        case .low: return "/printer"
        }
    }
}

enum CompressionStatus: Equatable {
    case idle
    case compressing
    case success
    case failed(String)
}

struct PDFFileModel: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let originalSize: Int64
    var compressedSize: Int64?
    var status: CompressionStatus

    init(
        id: UUID = UUID(),
        url: URL,
        originalSize: Int64,
        compressedSize: Int64? = nil,
        status: CompressionStatus = .idle
    ) {
        self.id = id
        self.url = url
        self.originalSize = originalSize
        self.compressedSize = compressedSize
        self.status = status
    }

    var percentSaved: Double {
        guard let compressedSize, originalSize > 0 else { return 0 }
        let saved = Double(originalSize - compressedSize)
        return max(0, (saved / Double(originalSize)) * 100)
    }
}
