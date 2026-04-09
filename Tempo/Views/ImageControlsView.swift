import SwiftUI

struct ImageControlsView: View {
    @EnvironmentObject var appState: AppState
    
    var hasPNGFiles: Bool {
        appState.imageFiles.contains { $0.fileName.lowercased().hasSuffix(".png") }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section 1 — Quality
            VStack(alignment: .leading, spacing: 14) {
                // Header with current value
                HStack {
                    Text("Quality")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Spacer()
                    
                    // Current value badge
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f%%", appState.compressionQuality * 100))
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppColors.textPrimary)
                            .contentTransition(.numericText(countsDown: false))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .stroke(AppColors.hairline, lineWidth: 0.5)
                    )
                }
                
                VStack(spacing: 18) {
                    // Slider
                    CustomSlider(value: $appState.compressionQuality, range: 0.01...1.0)
                        .padding(.top, 4)
                    
                    // Preset pills
                    HStack(spacing: 10) {
                        OutlinePill(
                            title: "Low",
                            isSelected: abs(appState.compressionQuality - 0.4) < 0.05
                        ) {
                            withAnimation(AppAnimations.quick) {
                                appState.compressionQuality = 0.4
                            }
                            playHaptic()
                        }
                        
                        OutlinePill(
                            title: "Balanced",
                            isSelected: abs(appState.compressionQuality - 0.75) < 0.05
                        ) {
                            withAnimation(AppAnimations.quick) {
                                appState.compressionQuality = 0.75
                            }
                            playHaptic()
                        }
                        
                        OutlinePill(
                            title: "High",
                            isSelected: abs(appState.compressionQuality - 0.9) < 0.05
                        ) {
                            withAnimation(AppAnimations.quick) {
                                appState.compressionQuality = 0.9
                            }
                            playHaptic()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Quality description
                    Text(qualityDescription)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            
            // Divider
            Divider()
                .background(AppColors.hairline)
                .frame(height: 0.5)
                .padding(.vertical, 14)
            
            // Section 2 — Options
            VStack(alignment: .leading, spacing: 12) {
                // Strip metadata toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strip Metadata")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("Removes GPS, camera info, and EXIF data")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $appState.stripMetadata)
                        .labelsHidden()
                }
                
                // PNG note
                if hasPNGFiles {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Text("PNG files will be converted to JPEG for compression")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(AppColors.textTertiary)
                            .italic()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private var qualityDescription: String {
        let quality = appState.compressionQuality
        if quality < 0.5 {
            return "Smaller file, visible compression"
        } else if quality < 0.8 {
            return "Good balance of quality and size"
        } else {
            return "Near-lossless, larger file"
        }
    }
    
    private func playHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }
}

#Preview {
    ZStack {
        AppColors.windowBackground
            .ignoresSafeArea()
        
        VStack {
            ImageControlsView()
                .environmentObject(AppState())
        }
        .padding(32)
    }
}
