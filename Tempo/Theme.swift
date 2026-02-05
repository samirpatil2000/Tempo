import SwiftUI
import AppKit

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Colors (Apple 2026 Glassmorphic)

enum AppColors {
    // Primary accent
    static let accent = Color(hex: "007AFF") // Apple blue
    
    // Adaptive backgrounds
    static let background = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0) // #121214
        } else {
            return NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0) // #F5F5F7
        }
    })
    
    // Glass panel background
    static let glassBackground = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.85) // Dark glass
        } else {
            return NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7) // Light glass
        }
    })
    
    // Elevated surface (cards, controls)
    static let surfaceElevated = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0) // #292930
        } else {
            return NSColor.white
        }
    })
    
    // Glass stroke/border
    static let glassStroke = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 1.0, alpha: 0.08)
        } else {
            return NSColor(white: 0.0, alpha: 0.06)
        }
    })
    
    // Segmented control background
    static let segmentBackground = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0) // #1A1A1F
        } else {
            return NSColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1.0) // #F0F0F2
        }
    })
    
    // Accent glow for selected states
    static let accentGlow = Color(hex: "007AFF").opacity(0.25)
    
    // Status colors
    static let success = Color(hex: "30D158") // Apple green
    static let error = Color(hex: "FF453A") // Apple red
    
    // Text colors
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.primary.opacity(0.4)
}

// MARK: - Glass Material Modifier

struct GlassMaterial: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.glassStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
    }
}

extension View {
    func glassMaterial(cornerRadius: CGFloat = 20, padding: CGFloat = 0) -> some View {
        modifier(GlassMaterial(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Spring Animation Presets

enum AppAnimations {
    static let smooth = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.75)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.65)
}
