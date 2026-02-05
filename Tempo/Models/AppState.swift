import SwiftUI
import AVFoundation
// Support for macos 13+ 
@MainActor
class AppState: ObservableObject {
    @Published var videoInfo: VideoInfo?
    @Published var speedMultiplier: Double = 1.0
    @Published var targetResolution: Resolution = .original
    @Published var exportProgress: Double = 0
    @Published var exportState: ExportState = .idle
    
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
}
