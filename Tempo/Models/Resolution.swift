import Foundation

enum Resolution: String, CaseIterable, Identifiable {
    case original = "Original"
    case p480 = "480p"
    case p720 = "720p"
    case p1080 = "1080p"
    
    var id: String { rawValue }
    
    var height: Int? {
        switch self {
        case .original: return nil
        case .p480: return 480
        case .p720: return 720
        case .p1080: return 1080
        }
    }
    
    var bitrate: Int {
        switch self {
        case .original: return 8_000_000
        case .p480: return 1_000_000
        case .p720: return 2_500_000
        case .p1080: return 5_000_000
        }
    }
}

enum SpeedMultiplier: Double, CaseIterable, Identifiable {
    case x1 = 1.0
    case x2 = 2.0
    case x3 = 3.0
    case x4 = 4.0
    
    var id: Double { rawValue }
    
    var label: String {
        switch self {
        case .x1: return "1×"
        case .x2: return "2×"
        case .x3: return "3×"
        case .x4: return "4×"
        }
    }
}

enum ExportState: Equatable {
    case idle
    case processing
    case complete(URL)
    case error(String)
}

struct VideoInfo {
    let url: URL
    let duration: TimeInterval
    let resolution: CGSize
    
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var fileName: String {
        url.lastPathComponent
    }
}
