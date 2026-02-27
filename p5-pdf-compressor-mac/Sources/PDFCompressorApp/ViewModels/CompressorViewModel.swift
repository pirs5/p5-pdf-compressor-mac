import Foundation
import SwiftUI

@MainActor
final class CompressorViewModel: ObservableObject {
    @Published private(set) var files: [PDFFileModel] = []
    @Published var selectedPreset: CompressionPreset = .middle
    @Published private(set) var totalSaved: Int64 = 0

    @Published var showGhostscriptAlert = false
    @Published var ghostscriptMissingMessage = "Ghostscript is missing.\nBundle Resources/Ghostscript/bin/gs or install with: brew install ghostscript"

    private var knownURLs = Set<URL>()
    private var isCompressing = false
    private var ghostscriptPath: String?

    func checkGhostscriptAvailability() {
        Task {
            if let path = await discoverGhostscriptPath() {
                ghostscriptPath = path
            } else {
                showGhostscriptAlert = true
            }
        }
    }

    func addDroppedFiles(urls: [URL]) {
        compress(files: urls)
    }

    func compress(files urls: [URL]) {
        let pdfURLs = urls
            .map { $0.standardizedFileURL }
            .filter { $0.pathExtension.lowercased() == "pdf" }

        let newItems: [PDFFileModel] = pdfURLs.compactMap { url in
            guard !knownURLs.contains(url) else { return nil }
            do {
                let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                guard values.isRegularFile == true, let size = values.fileSize else { return nil }
                knownURLs.insert(url)
                return PDFFileModel(url: url, originalSize: Int64(size))
            } catch {
                return nil
            }
        }

        guard !newItems.isEmpty else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            files.append(contentsOf: newItems)
        }

        compressPendingFilesIfNeeded()
    }

    func compressPendingFilesIfNeeded() {
        guard !isCompressing else { return }

        Task {
            isCompressing = true
            defer { isCompressing = false }

            while let index = files.firstIndex(where: { $0.status == .idle }) {
                await compressFile(at: index)
            }
        }
    }

    private func compressFile(at index: Int) async {
        guard files.indices.contains(index) else { return }

        files[index].status = .compressing
        let item = files[index]

        do {
            let (result, outputURL) = try await runGhostscript(for: item)

            guard result.exitCode == 0 else {
                let message = result.stderr.isEmpty ? result.stdout : result.stderr
                files[index].status = .failed(message.nonEmptyOrFallback("Ghostscript returned non-zero exit code."))
                return
            }

            let compressedValues = try outputURL.resourceValues(forKeys: [.fileSizeKey])
            guard let compressedRawSize = compressedValues.fileSize else {
                files[index].status = .failed("Unable to read compressed file size.")
                return
            }

            files[index].compressedSize = Int64(compressedRawSize)
            files[index].status = .success
            recalculateTotalSaved()
        } catch {
            files[index].status = .failed(error.localizedDescription)
        }
    }

    private func recalculateTotalSaved() {
        totalSaved = files.reduce(0) { partial, file in
            guard let compressed = file.compressedSize else { return partial }
            return partial + max(0, file.originalSize - compressed)
        }
    }

    private func makeOutputURL(for inputURL: URL) -> URL {
        let base = inputURL.deletingPathExtension().lastPathComponent
        let sanitizedBase = base.hasPrefix("Compressed_") ? String(base.dropFirst("Compressed_".count)) : base
        let directory = inputURL.deletingLastPathComponent()

        var outputName = "Compressed_\(sanitizedBase)"
        var outputURL = directory.appendingPathComponent(outputName).appendingPathExtension("pdf")

        var index = 1
        while FileManager.default.fileExists(atPath: outputURL.path) && outputURL != inputURL {
            outputName = "Compressed_\(sanitizedBase)_\(index)"
            outputURL = directory.appendingPathComponent(outputName).appendingPathExtension("pdf")
            index += 1
        }

        return outputURL
    }

    private func discoverGhostscriptPath() async -> String? {
        if let bundledPath = bundledGhostscriptPath() {
            return bundledPath
        }

        let commonPaths = [
            "/opt/homebrew/bin/gs",
            "/usr/local/bin/gs"
        ]

        if let existing = commonPaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return existing
        }

        do {
            let result = try await runProcess(executable: "/usr/bin/which", arguments: ["gs"])
            guard result.exitCode == 0 else { return nil }
            let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            return path.isEmpty ? nil : path
        } catch {
            return nil
        }
    }

    private func runGhostscript(for file: PDFFileModel) async throws -> (ProcessResult, URL) {
        guard let gsPath = await resolveGhostscriptPath() else {
            throw NSError(
                domain: "PDFCompressor",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Ghostscript not found. Bundle Resources/Ghostscript/bin/gs or install with: brew install ghostscript"]
            )
        }

        let outputURL = makeOutputURL(for: file.url)
        let args: [String] = [
            "-sDEVICE=pdfwrite",
            "-dCompatibilityLevel=1.6",
            "-dPDFSETTINGS=\(selectedPreset.ghostscriptValue)",
            "-dNOPAUSE",
            "-dQUIET",
            "-dBATCH",
            "-sOutputFile=\(outputURL.path)",
            file.url.path
        ]

        let processResult = try await runProcess(
            executable: gsPath,
            arguments: args,
            environment: ghostscriptEnvironment(forExecutablePath: gsPath)
        )
        return (processResult, outputURL)
    }

    private func resolveGhostscriptPath() async -> String? {
        if let ghostscriptPath, FileManager.default.isExecutableFile(atPath: ghostscriptPath) {
            return ghostscriptPath
        }

        let discovered = await discoverGhostscriptPath()
        ghostscriptPath = discovered
        return discovered
    }

    private func bundledGhostscriptPath() -> String? {
        guard let bundledURL = Bundle.main.url(forResource: "gs", withExtension: nil, subdirectory: "Ghostscript/bin") else {
            return nil
        }

        let path = bundledURL.path
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    private func ghostscriptEnvironment(forExecutablePath executablePath: String) -> [String: String]? {
        guard executablePath.hasPrefix(Bundle.main.bundlePath) else { return nil }

        var env = ProcessInfo.processInfo.environment
        let bundleResourcePath = Bundle.main.resourcePath ?? ""
        let ghostscriptLibPath = bundleResourcePath + "/Ghostscript/lib"
        let fontPath = bundleResourcePath + "/Ghostscript/fonts"

        var libParts: [String] = []
        if FileManager.default.fileExists(atPath: ghostscriptLibPath) { libParts.append(ghostscriptLibPath) }
        if FileManager.default.fileExists(atPath: fontPath) { libParts.append(fontPath) }

        if !libParts.isEmpty {
            env["GS_LIB"] = libParts.joined(separator: ":")
        }

        return env
    }

    private func runProcess(executable: String, arguments: [String], environment: [String: String]? = nil) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.environment = environment ?? ProcessInfo.processInfo.environment
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(returning: ProcessResult(
                    exitCode: process.terminationStatus,
                    stdout: stdout,
                    stderr: stderr
                ))
            }
        }
    }
}

private struct ProcessResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

private extension String {
    func nonEmptyOrFallback(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
