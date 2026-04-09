import Foundation
import ImageIO
import UniformTypeIdentifiers

final class ImageProcessor: @unchecked Sendable {
    static func compress(
        inputURL: URL,
        outputURL: URL,
        quality: Double,
        stripMetadata: Bool,
        outputFormat: UTType
    ) throws -> Int64 {
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "ImageProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
        }
        
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, outputFormat.identifier as CFString, 1, nil) else {
            throw NSError(domain: "ImageProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
        }
        
        var options: [NSString: Any] = [:]
        
        // Set compression quality
        options[kCGImageDestinationLossyCompressionQuality] = NSNumber(value: quality)
        
        // Handle metadata
        if stripMetadata {
            // Empty metadata dict = no metadata
            options[kCGImageDestinationMetadata] = [:]
        } else {
            // Copy source metadata
            let sourceMetadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil)
            if let metadata = sourceMetadata {
                options[kCGImageDestinationMetadata] = metadata
            }
        }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ImageProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize image"])
        }
        
        // Get output file size
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        return fileSize
    }
}
