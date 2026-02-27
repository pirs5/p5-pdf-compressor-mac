Place a macOS Ghostscript executable here:

  Sources/PDFCompressorApp/Resources/Ghostscript/bin/gs

Requirements:
- File name must be exactly: gs
- Must be executable: chmod +x gs
- Must be compatible with your target architecture (arm64 for Apple Silicon, x86_64 for Intel)
- If your gs build needs runtime resources, include:
  - Sources/PDFCompressorApp/Resources/Ghostscript/lib
  - Sources/PDFCompressorApp/Resources/Ghostscript/fonts

The app searches this bundled binary first, then system locations.
