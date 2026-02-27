# Pirs 5 PDF Compressor

Native macOS PDF compression app built with SwiftUI (Swift 5.9+).

## Features

- Drag and drop one or more PDF files
- Local compression using Ghostscript
- Presets: `Strong`, `Middle`, `Low`
- Per-file status and size savings
- Output naming: `Compressed_<OriginalName>.pdf`
- Bundled icon support via `AppIcon.png`

## Project Structure

- `p5-pdf-compressor-mac/` — Swift package source for the app
- `docs/` — GitHub Pages site

## Run Locally

1. Open `p5-pdf-compressor-mac/Package.swift` in Xcode.
2. Build and run the `Pirs5PDFCompressor` scheme.
3. Drop PDFs into the app window.

## Ghostscript

The app first looks for bundled Ghostscript binary at:

`p5-pdf-compressor-mac/Sources/PDFCompressorApp/Resources/Ghostscript/bin/gs`

If missing, it tries common system paths.

## GitHub Pages

A simple landing page is in `docs/index.html`.
