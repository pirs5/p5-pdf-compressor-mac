import SwiftUI

struct ResultRowView: View {
    let file: PDFFileModel

    var body: some View {
        HStack(spacing: 10) {
            statusView
                .frame(width: 20)

            Text(file.url.lastPathComponent)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Text(FileSizeFormatter.megabytesString(from: file.originalSize))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Text("→")
                    .foregroundStyle(.secondary)

                Text(compressedSizeText)
                    .monospacedDigit()
                    .foregroundStyle(file.compressedSize == nil ? .secondary : .primary)

                Text(savedText)
                    .monospacedDigit()
                    .foregroundStyle(file.percentSaved > 0 ? .green : .secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            }
            .font(.callout)

            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor)
                .frame(minWidth: 92, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    private var compressedSizeText: String {
        guard let compressedSize = file.compressedSize else { return "--" }
        return FileSizeFormatter.megabytesString(from: compressedSize)
    }

    private var savedText: String {
        switch file.status {
        case .success:
            return String(format: "%.1f%%", file.percentSaved)
        default:
            return "--"
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch file.status {
        case .idle:
            Image(systemName: "circle.fill")
                .foregroundStyle(.gray)
                .font(.caption)
        case .compressing:
            ProgressView()
                .controlSize(.small)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch file.status {
        case .idle: return "Idle"
        case .compressing: return "Compressing"
        case .success: return "Success"
        case .failed: return "Failed"
        }
    }

    private var statusColor: Color {
        switch file.status {
        case .idle: return .secondary
        case .compressing: return .accentColor
        case .success: return .green
        case .failed: return .red
        }
    }

}
