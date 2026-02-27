import Foundation

enum FileSizeFormatter {
    static func megabytesString(from bytes: Int64) -> String {
        let mbValue = Double(bytes) / 1_048_576
        return String(format: "%.2f MB", mbValue)
    }
}
