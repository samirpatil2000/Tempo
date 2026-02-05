import SwiftUI

struct SpeedSelectorView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("SPEED")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundStyle(Color.secondary.opacity(0.8))

                
                if let duration = formattedDuration {
                    Text("— \(duration)")
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                        .transition(.opacity)
                }
            }
            .padding(.leading, 2)
            
            HStack(spacing: 12) {
                ForEach(SpeedMultiplier.allCases) { speed in
                    MinimalistPillButton(
                        title: speed.label,
                        isSelected: appState.speedMultiplier == speed
                    ) {
                        playSound(type: .selection)
                        withAnimation(.easeOut(duration: 0.15)) {
                            appState.speedMultiplier = speed
                        }
                    }
                }
            }
        }
    }
    
    private var formattedDuration: String? {
        guard let originalDuration = appState.videoInfo?.duration else { return nil }
        let newDuration = originalDuration / appState.speedMultiplier.rawValue
        
        let minutes = Int(newDuration) / 60
        let seconds = Int(newDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ResolutionSelectorView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUALITY")
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundStyle(Color.secondary.opacity(0.8))

            
            HStack(spacing: 12) {
                ForEach(Resolution.allCases) { resolution in
                    MinimalistPillButton(
                        title: resolution.rawValue,
                        isSelected: appState.targetResolution == resolution
                    ) {
                        playSound(type: .selection)
                        withAnimation(.easeOut(duration: 0.15)) {
                            appState.targetResolution = resolution
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Minimalist Pill Button

struct MinimalistPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular, design: .default))
                .foregroundStyle(isSelected ? .white : Color.primary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? AppColors.accent : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.clear : Color.primary.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .scaleEffect(isSelected ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Haptic Helper
private enum SoundType {
    case selection
}

private func playSound(type: SoundType) {
    // macOS buttons usually have subtle clicks by default, but we can enforce logic here if needed.
    // NSHapticFeedbackManager is the macOS equivalent for haptics.
    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
}

#Preview {
    VStack(spacing: 32) {
        SpeedSelectorView()
        ResolutionSelectorView()
    }
    .padding(40)
    .background(AppColors.background)
    .environmentObject(AppState())
}
