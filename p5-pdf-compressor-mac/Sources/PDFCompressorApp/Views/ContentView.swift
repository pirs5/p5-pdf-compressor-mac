import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = CompressorViewModel()
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Pirs 5 PDF Compressor")
                .font(.largeTitle.weight(.bold))

            DropZoneView(isTargeted: isDropTargeted)
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop(providers:))

            Picker("Compression preset", selection: $viewModel.selectedPreset) {
                ForEach(CompressionPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)

            List(viewModel.files) { file in
                ResultRowView(file: file)
            }
            .listStyle(.inset)

            HStack {
                Spacer()
                Text("Saved \(FileSizeFormatter.megabytesString(from: viewModel.totalSaved)) total")
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .padding(20)
        .animation(.easeInOut(duration: 0.2), value: viewModel.files)
        .animation(.easeInOut(duration: 0.2), value: viewModel.totalSaved)
        .onAppear {
            viewModel.checkGhostscriptAvailability()
        }
        .alert("Ghostscript is not installed.", isPresented: $viewModel.showGhostscriptAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.ghostscriptMissingMessage)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            let urls = await providers.loadFileURLs()
            await MainActor.run {
                viewModel.addDroppedFiles(urls: urls)
            }
        }
        return true
    }
}

private extension Array where Element == NSItemProvider {
    func loadFileURLs() async -> [URL] {
        await withTaskGroup(of: URL?.self) { group in
            for provider in self {
                group.addTask {
                    await provider.loadFileURL()
                }
            }

            var urls: [URL] = []
            for await url in group {
                if let url {
                    urls.append(url)
                }
            }
            return urls
        }
    }
}

private extension NSItemProvider {
    func loadFileURL() async -> URL? {
        await withCheckedContinuation { continuation in
            if canLoadObject(ofClass: NSURL.self) {
                _ = loadObject(ofClass: NSURL.self) { object, _ in
                    let nsURL = object as? NSURL
                    continuation.resume(returning: nsURL as URL?)
                }
                return
            }

            loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard
                    let data,
                    let rawString = String(data: data, encoding: .utf8),
                    let url = URL(string: rawString)
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: url)
            }
        }
    }
}
