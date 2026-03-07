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

// MARK: - App Colors (Jony Ive — Restraint, Clarity, Depth)

enum AppColors {
    // The single accent — used sparingly (Export button only)
    static let accent = Color(hex: "0A84FF") // Apple system blue
    
    // Window background — deep, calm
    static let windowBackground = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
        } else {
            return NSColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        }
    })
    
    // Card surface — solid, elevated
    static let cardSurface = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        } else {
            return NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        }
    })
    
    // Hairline borders — the faintest structure
    static let hairline = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 1.0, alpha: 0.08)
        } else {
            return NSColor(white: 0.0, alpha: 0.06)
        }
    })
    
    // Selected border — slightly brighter, the only visual difference
    static let selectedBorder = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 1.0, alpha: 0.35)
        } else {
            return NSColor(white: 0.0, alpha: 0.25)
        }
    })
    
    // Control background — pill/segment inactive
    static let controlBackground = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 1.0, alpha: 0.03)
        } else {
            return NSColor(white: 0.0, alpha: 0.03)
        }
    })
    
    // Segmented control track
    static let segmentTrack = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(white: 1.0, alpha: 0.05)
        } else {
            return NSColor(white: 0.0, alpha: 0.04)
        }
    })
    
    // Accent glow — for the export button shadow only
    static let accentGlow = Color(hex: "0A84FF").opacity(0.2)
    
    // Status
    static let success = Color(hex: "30D158")
    static let error = Color(hex: "FF453A")
    
    // Typography — hierarchy through opacity
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color.primary.opacity(0.35)
    
    // Keep backward compatibility aliases
    static let background = windowBackground
    static let surfaceElevated = cardSurface
    static let glassStroke = hairline
    static let segmentBackground = segmentTrack
}

// MARK: - Glass Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 14
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.hairline, lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 14) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Legacy Glass Material (kept for compatibility)

struct GlassMaterial: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .glassCard(cornerRadius: cornerRadius)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
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
