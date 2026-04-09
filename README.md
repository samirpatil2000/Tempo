<p align="center">
  <img src="Tempo/Assets/Tempo-Logo.png" alt="Tempo Logo" width="128" height="128">
</p>

<h1 align="center">Tempo</h1>

<p align="center">
  <strong>A sleek video speed & export utility + image compressor for macOS</strong>
</p>

<p align="center">
  <a href="https://github.com/samirpatil2000/Tempo/releases/latest">
    <img src="https://img.shields.io/badge/Download-v1.2-blue?style=for-the-badge&logo=apple" alt="Download">
  </a>
  <img src="https://img.shields.io/badge/macOS-13.0+-black?style=for-the-badge&logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift" alt="Swift 5.9">
  <a href="https://deepwiki.com/samirpatil2000/Tempo"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki"></a>
</p>

---

## ✨ Features

**Video Export**
- **🚀 Speed Control** — Export videos at 1×, 2×, 3×, or 4× playback speed
- **📺 Quality Options** — Choose Original, 480p, 720p, or 1080p output
- **📊 Real-time Progress** — Circular progress indicator with estimated file size

**Image Compression**
- **📷 Smart Compression** — Adjust quality from low to near-lossless
- **🧹 Metadata Stripping** — Optional EXIF/metadata removal for smaller files
- **📂 Batch Processing** — Compress multiple images at once
- **👁️ Live Preview** — Thumbnail previews with before/after file sizes
- **🎨 Format Support** — JPEG, PNG, HEIC with automatic PNG→JPEG conversion

**General**
- **📂 Drag & Drop** — Simply drop files onto the app
- **🌙 Dark Mode** — Deep, calming dark surfaces that let your content shine
- **🎨 Minimalist Design** — Refined, typography-driven interface with subtle interactions
- **🔗 Open With Support** — Right-click any video or image and select Open With → Tempo
- **⚡ Lightweight** — Focused utility that does one thing exceptionally well

---

## 📥 Download

<p align="center">
  <a href="https://github.com/samirpatil2000/Tempo/releases/download/v1.2/Tempo.dmg">
    <img src="https://img.shields.io/badge/⬇️_Download_Tempo.dmg-1.2-2ea44f?style=for-the-badge" alt="Download Tempo.dmg">
  </a>
</p>

> **Note:** Tempo is not notarized with Apple Developer ID. On first launch:
> 1. Right-click on **Tempo.app**
> 2. Click **Open**
> 3. Click **Open** in the security dialog

---

## 🚀 Getting Started

1. **Download** the `.dmg` file from above
2. **Open** the downloaded `Tempo.dmg`
3. **Drag** `Tempo.app` into the adjacent Applications folder shortcut
4. **Launch** Tempo from `/Applications`
5. **Choose Mode** — Switch between "Export Video" or "Compress Images" at the top
6. **Drop Files** — Drag video or image files onto the app
7. **Configure** — Set speed/quality (video) or compression level/options (images)
8. **Export** — Click the export button and choose your output location!

---

## 🖥️ Screenshots

<p align="center">
  <!-- Add your screenshot here -->
  <img width="600" height="900" alt="Screenshot 2026-03-08 at 01 32 35" src="https://github.com/user-attachments/assets/c470b19c-6c49-4f4d-9088-f5dec2b35f50" />

<img width="600" height="900" alt="Screenshot 2026-03-08 at 01 33 09" src="https://github.com/user-attachments/assets/55642a5a-198e-4718-ac19-132f6d1ba9e3" />

</p>

---

## 🎬 Supported Formats

**Video**
| Input | Output |
|-------|--------|
| `.mov` | `.mp4` |
| `.mp4` | `.mp4` |
| `.avi` | `.mp4` |
| QuickTime | H.264 |

**Images**
| Input | Output | Notes |
|-------|--------|-------|
| `.jpg` / `.jpeg` | `.jpg` | Adjustable quality (0-100%) |
| `.png` | `.jpg` | Auto-converts to JPEG for compression |
| `.heic` | `.heic` | Apple's modern format, adjustable quality |

---

## 🛠️ Building from Source

```bash
# Clone the repository
git clone https://github.com/samirpatil2000/Tempo.git
cd Tempo

# Build the app and create a DMG
./build_dmg.sh
```
Or open `Tempo.xcodeproj` in Xcode and build normally.

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9

---

## 📁 Project Structure

```
Tempo/
├── TempoApp.swift           # App entry point with URL routing
├── Theme.swift              # Colors, materials & animations
├── Models/
│   ├── AppState.swift       # Unified state management (video + image)
│   ├── AppMode.swift        # Video/Image mode enum
│   ├── ImageFile.swift      # Image data model with compression metadata
│   └── Resolution.swift     # Speed & resolution enums
├── Processing/
│   ├── VideoProcessor.swift # Video export engine
│   └── ImageProcessor.swift # Image compression engine (ImageIO)
└── Views/
    ├── ContentView.swift        # Main layout with mode toggle
    ├── DropZoneView.swift       # Video drag & drop zone
    ├── ImageDropZoneView.swift  # Image drag & drop zone
    ├── SelectorViews.swift      # Segmented controls
    ├── ExportButtonView.swift   # Video export button & progress
    ├── ImageExportButtonView.swift  # Image export button & progress
    ├── ImageListView.swift      # Image file list with thumbnails
    ├── ImageControlsView.swift  # Quality slider & metadata options
    └── ImageDropZoneView.swift  # Multi-file image drop zone
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

---

## 📄 License

MIT License — feel free to use this project however you like.

---

<p align="center">
  Made with ❤️ for macOS
</p>
