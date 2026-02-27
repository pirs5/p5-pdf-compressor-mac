import SwiftUI

struct DropZoneView: View {
    let isTargeted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                style: StrokeStyle(lineWidth: 3, dash: [10, 8])
            )
            .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08))
            )
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                    Text("Drag PDF files here")
                        .font(.title3.weight(.semibold))
                    Text("Drop one or more files to compress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 220)
    }
}
