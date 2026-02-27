import AppKit
import SwiftUI

@main
struct Pirs5PDFCompressorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Pirs 5 PDF Compressor") {
            ContentView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .windowResizability(.automatic)
        .defaultSize(width: 820, height: 620)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.applicationIconImage = loadExactAppIcon() ?? makeAppIcon()
        NSApplication.shared.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApplication.shared.windows.forEach { window in
                window.minSize = NSSize(width: 600, height: 500)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func loadExactAppIcon() -> NSImage? {
        let bundleCandidates: [URL?] = [
            Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
            Bundle.main.url(forResource: "AppIcon", withExtension: "png", subdirectory: "Resources")
        ]

        for candidate in bundleCandidates {
            if let candidate, let image = NSImage(contentsOf: candidate) {
                return image
            }
        }

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let diskCandidates = [
            cwd.appendingPathComponent("Sources/PDFCompressorApp/Resources/AppIcon.png"),
            URL(fileURLWithPath: "/Users/volobuevg/Downloads/logo.png")
        ]

        for path in diskCandidates where FileManager.default.fileExists(atPath: path.path) {
            if let image = NSImage(contentsOf: path) {
                return image
            }
        }

        return nil
    }

    private func makeAppIcon() -> NSImage {
        let imageSize = NSSize(width: 512, height: 512)
        let image = NSImage(size: imageSize)
        image.lockFocus()

        let bounds = NSRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)

        let tile = NSBezierPath(roundedRect: bounds, xRadius: 92, yRadius: 92)
        NSColor(calibratedRed: 0.98, green: 0.83, blue: 0.0, alpha: 1.0).setFill()
        tile.fill()

        let p5Attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 360, weight: .black),
            .foregroundColor: NSColor(calibratedWhite: 0.1, alpha: 1)
        ]
        let p5Text = "P5" as NSString
        p5Text.draw(in: NSRect(x: 245, y: -16, width: 320, height: 520), withAttributes: p5Attributes)

        let docRect = NSRect(x: 120, y: 96, width: 230, height: 285)
        let docBody = NSBezierPath(roundedRect: docRect, xRadius: 22, yRadius: 22)
        NSColor(calibratedWhite: 0.83, alpha: 1).setFill()
        docBody.fill()

        let foldSize: CGFloat = 72
        let foldPath = NSBezierPath()
        foldPath.move(to: NSPoint(x: docRect.maxX - foldSize, y: docRect.maxY))
        foldPath.line(to: NSPoint(x: docRect.maxX, y: docRect.maxY))
        foldPath.line(to: NSPoint(x: docRect.maxX, y: docRect.maxY - foldSize))
        foldPath.close()
        NSColor(calibratedWhite: 0.70, alpha: 1).setFill()
        foldPath.fill()

        let badgeRect = NSRect(x: 84, y: 140, width: 196, height: 102)
        let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 12, yRadius: 12)
        NSColor(calibratedRed: 0.95, green: 0.27, blue: 0.29, alpha: 1).setFill()
        badge.fill()

        let pdfAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 66, weight: .bold),
            .foregroundColor: NSColor(calibratedWhite: 0.97, alpha: 1)
        ]
        ("PDF" as NSString).draw(in: NSRect(x: 104, y: 151, width: 170, height: 80), withAttributes: pdfAttributes)

        image.unlockFocus()
        return image
    }
}
