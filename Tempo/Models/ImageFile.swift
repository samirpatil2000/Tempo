import Foundation

enum ImageExportState: Equatable {
    case idle
    case processing
    case complete(URL)
    case error(String)
}

struct ImageFile: Identifiable {
    let id: UUID
    let url: URL
    let fileName: String
    let originalSize: Int64        // bytes on disk
    var compressedURL: URL?
    var compressedSize: Int64?
    var exportState: ImageExportState
    
    var originalSizeFormatted: String {
        formatFileSize(originalSize)
    }
    
    var compressedSizeFormatted: String? {
        guard let size = compressedSize else { return nil }
        return formatFileSize(size)
    }
    
    var savingsPercent: Int? {
        guard let compressedSize = compressedSize else { return nil }
        let savings = Double(originalSize - compressedSize) / Double(originalSize)
        return Int(savings * 100)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
