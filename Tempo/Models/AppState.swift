import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
// Support for macos 13+ 
@MainActor
class AppState: ObservableObject {
    // Video properties
    @Published var videoInfo: VideoInfo?
    @Published var speedMultiplier: Double = 1.0
    @Published var targetResolution: Resolution = .original
    @Published var exportProgress: Double = 0
    @Published var exportState: ExportState = .idle
    
    // Image properties
    @Published var mode: AppMode = .video
    @Published var imageFiles: [ImageFile] = []
    @Published var compressionQuality: Double = 0.75
    @Published var stripMetadata: Bool = false
    @Published var imageExportState: ExportState = .idle
    
    var canExport: Bool {
        videoInfo != nil && exportState != .processing
    }
    
    func loadVideo(from url: URL) async {
        let asset = AVAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            
            var resolution = CGSize(width: 1920, height: 1080)
            if let track = tracks.first {
                let size = try await track.load(.naturalSize)
                let transform = try await track.load(.preferredTransform)
                let transformedSize = size.applying(transform)
                resolution = CGSize(
                    width: abs(transformedSize.width),
                    height: abs(transformedSize.height)
                )
            }
            
            self.videoInfo = VideoInfo(
                url: url,
                duration: duration.seconds,
                resolution: resolution
            )
            self.exportState = .idle
            self.exportProgress = 0
        } catch {
            self.exportState = .error("Failed to load video")
        }
    }
    
    func reset() {
        videoInfo = nil
        speedMultiplier = 1.0
        targetResolution = .original
        exportProgress = 0
        exportState = .idle
    }
    
    // MARK: - Image Loading
    
    func loadImage(from url: URL) async {
        let fileName = url.lastPathComponent
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            let imageFile = ImageFile(
                id: UUID(),
                url: url,
                fileName: fileName,
                originalSize: fileSize,
                compressedURL: nil,
                compressedSize: nil,
                exportState: .idle
            )
            
            self.imageFiles.append(imageFile)
            self.mode = .image
        } catch {
            print("Failed to load image: \(error)")
        }
    }
    
    func loadImages(from urls: [URL]) async {
        for url in urls {
            await loadImage(from: url)
        }
    }
    
    func removeImage(id: UUID) {
        imageFiles.removeAll { $0.id == id }
    }
    
    func resetImages() {
        imageFiles = []
        imageExportState = .idle
    }
    
    // MARK: - Image Export
    
    func exportImages(to directory: URL) async {
        imageExportState = .processing
        
        do {
            for i in imageFiles.indices {
                let imageFile = imageFiles[i]
                
                let outputFileName = getOutputFileName(for: imageFile.fileName)
                let outputURL = directory.appendingPathComponent(outputFileName)
                
                let outputFormat: UTType = getOutputFormat(for: imageFile.fileName)
                
                let compressedSize = try ImageProcessor.compress(
                    inputURL: imageFile.url,
                    outputURL: outputURL,
                    quality: compressionQuality,
                    stripMetadata: stripMetadata,
                    outputFormat: outputFormat
                )
                
                imageFiles[i].compressedURL = outputURL
                imageFiles[i].compressedSize = compressedSize
                imageFiles[i].exportState = .complete(outputURL)
            }
            
            imageExportState = .complete(directory)
        } catch {
            imageExportState = .error("Export failed: \(error.localizedDescription)")
        }
    }
    
    private func getOutputFileName(for inputFileName: String) -> String {
        let components = inputFileName.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let nameWithoutExt = components.count > 0 ? String(components[0]) : "image"
        let ext = getOutputExtension(for: inputFileName)
        return "\(nameWithoutExt)_compressed\(ext)"
    }
    
    private func getOutputExtension(for inputFileName: String) -> String {
        let lowercased = inputFileName.lowercased()
        if lowercased.hasSuffix(".heic") {
            return ".heic"
        } else if lowercased.hasSuffix(".png") {
            return ".jpg"
        } else {
            return ".jpg"
        }
    }
    
    private func getOutputFormat(for inputFileName: String) -> UTType {
        let lowercased = inputFileName.lowercased()
        if lowercased.hasSuffix(".heic") {
            return .heic
        } else {
            return .jpeg
        }
    }
}
