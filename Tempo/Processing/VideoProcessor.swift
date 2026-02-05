import AVFoundation
import CoreImage

final class VideoProcessor: @unchecked Sendable {
    private let inputURL: URL
    private let outputURL: URL
    private let speed: Double
    private let targetResolution: Resolution
    private var isCancelled = false
    private var exportSession: AVAssetExportSession?
    private let lock = NSLock()
    
    init(inputURL: URL, outputURL: URL, speed: Double, targetResolution: Resolution) {
        self.inputURL = inputURL
        self.outputURL = outputURL
        self.speed = speed
        self.targetResolution = targetResolution
    }
    
    func cancel() {
        lock.lock()
        isCancelled = true
        lock.unlock()
        exportSession?.cancelExport()
    }
    
    private var cancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }
    
    func process() -> AsyncThrowingStream<Double, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.performExport(progress: { progress in
                        continuation.yield(progress)
                    })
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func performExport(progress: @escaping (Double) -> Void) async throws {
        let asset = AVAsset(url: inputURL)
        
        guard !cancelled else { throw CancellationError() }
        
        let composition = AVMutableComposition()
        
        // Load tracks
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let duration = try await asset.load(.duration)
        
        guard let sourceVideoTrack = videoTracks.first else {
            throw ProcessingError.noVideoTrack
        }
        
        // Add video track
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw ProcessingError.compositionFailed
        }
        
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        try compositionVideoTrack.insertTimeRange(timeRange, of: sourceVideoTrack, at: .zero)
        
        // Apply speed adjustment to video
        let scaledDuration = CMTimeMultiplyByFloat64(duration, multiplier: 1.0 / speed)
        compositionVideoTrack.scaleTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            toDuration: scaledDuration
        )
        
        // Copy transform
        let transform = try await sourceVideoTrack.load(.preferredTransform)
        compositionVideoTrack.preferredTransform = transform
        
        // Add audio track with pitch-preserved speed adjustment
        if let sourceAudioTrack = audioTracks.first {
            guard let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw ProcessingError.compositionFailed
            }
            
            try compositionAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: .zero)
            compositionAudioTrack.scaleTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                toDuration: scaledDuration
            )
        }
        
        guard !cancelled else { throw CancellationError() }
        
        // Configure video composition for resolution scaling
        let videoComposition = try await createVideoComposition(
            composition: composition,
            sourceTrack: sourceVideoTrack
        )
        
        // Export
        try await export(
            composition: composition,
            videoComposition: videoComposition,
            progress: progress
        )
    }
    
    private func createVideoComposition(
        composition: AVMutableComposition,
        sourceTrack: AVAssetTrack
    ) async throws -> AVMutableVideoComposition {
        let naturalSize = try await sourceTrack.load(.naturalSize)
        let transform = try await sourceTrack.load(.preferredTransform)
        
        // Calculate actual size considering transform (rotation)
        let transformedSize = naturalSize.applying(transform)
        let actualWidth = abs(transformedSize.width)
        let actualHeight = abs(transformedSize.height)
        
        // Calculate target size
        let targetSize: CGSize
        if let targetHeight = targetResolution.height {
            let aspectRatio = actualWidth / actualHeight
            let newHeight = CGFloat(targetHeight)
            let newWidth = round(newHeight * aspectRatio / 2) * 2 // Ensure even width
            targetSize = CGSize(width: newWidth, height: newHeight)
        } else {
            // Original resolution - ensure even dimensions
            targetSize = CGSize(
                width: round(actualWidth / 2) * 2,
                height: round(actualHeight / 2) * 2
            )
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        // Create instruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        
        guard let compositionTrack = try await composition.loadTracks(withMediaType: .video).first else {
            throw ProcessingError.noVideoTrack
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        
        // Apply scaling and transform
        let scaleX = targetSize.width / actualWidth
        let scaleY = targetSize.height / actualHeight
        
        var finalTransform = transform
        finalTransform = finalTransform.concatenating(CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Handle rotation - translate to keep video in frame
        if transform.b == 1.0 && transform.c == -1.0 {
            // 90 degrees rotation
            finalTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                .concatenating(CGAffineTransform(rotationAngle: .pi / 2))
                .concatenating(CGAffineTransform(translationX: targetSize.width, y: 0))
        } else if transform.b == -1.0 && transform.c == 1.0 {
            // -90 degrees rotation
            finalTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                .concatenating(CGAffineTransform(rotationAngle: -.pi / 2))
                .concatenating(CGAffineTransform(translationX: 0, y: targetSize.height))
        } else if transform.a == -1.0 && transform.d == -1.0 {
            // 180 degrees rotation
            finalTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                .concatenating(CGAffineTransform(rotationAngle: .pi))
                .concatenating(CGAffineTransform(translationX: targetSize.width, y: targetSize.height))
        } else {
            // No rotation - just scale
            finalTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        }
        
        layerInstruction.setTransform(finalTransform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        return videoComposition
    }
    
    private func export(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        progress: @escaping (Double) -> Void
    ) async throws {
        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw ProcessingError.exportFailed
        }
        
        self.exportSession = exportSession
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Progress monitoring
        let progressTask = Task {
            while !Task.isCancelled && exportSession.status == .exporting {
                progress(Double(exportSession.progress))
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
        
        await exportSession.export()
        progressTask.cancel()
        
        guard !cancelled else { throw CancellationError() }
        
        switch exportSession.status {
        case .completed:
            progress(1.0)
        case .failed:
            throw exportSession.error ?? ProcessingError.exportFailed
        case .cancelled:
            throw CancellationError()
        default:
            throw ProcessingError.exportFailed
        }
    }
}

enum ProcessingError: LocalizedError {
    case noVideoTrack
    case compositionFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "No video track found in the input file"
        case .compositionFailed:
            return "Failed to create video composition"
        case .exportFailed:
            return "Export failed"
        }
    }
}
