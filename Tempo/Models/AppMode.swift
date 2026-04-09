import Foundation

enum AppMode: String, CaseIterable, Identifiable {
    case video = "Video"
    case image = "Image"
    
    var id: String { rawValue }
}
