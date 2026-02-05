import SwiftUI

// MARK: - Speed Selector

struct SpeedSelectorView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Segmented Control
            SegmentedControl(
                items: SpeedMultiplier.allCases,
                selection: $appState.speedMultiplier,
                label: \.label
            )
            
            // Helper text with duration
            HStack(spacing: 4) {
                Text("Playback speed")
                    .foregroundStyle(AppColors.textTertiary)
                
                if let duration = formattedDuration {
                    Text("•")
                        .foregroundStyle(AppColors.textTertiary)
                    Text(duration)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .font(.system(size: 11, weight: .regular))
            .padding(.leading, 4)
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

// MARK: - Resolution Selector

struct ResolutionSelectorView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Segmented Control
            SegmentedControl(
                items: Resolution.allCases,
                selection: $appState.targetResolution,
                label: \.rawValue,
                recommendedItem: .p1080
            )
            
            // Helper text
            Text("Export quality")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.leading, 4)
        }
    }
}

// MARK: - Apple-Style Segmented Control

struct SegmentedControl<T: Hashable & Identifiable>: View {
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String
    var recommendedItem: T? = nil
    
    @Namespace private var namespace
    @State private var pressedItem: T? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                segmentButton(for: item)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.segmentBackground)
        )
    }
    
    private func segmentButton(for item: T) -> some View {
        let isSelected = selection.id == item.id
        let isPressed = pressedItem?.id == item.id
        let isRecommended = recommendedItem?.id == item.id && !isSelected
        
        return Button {
            withAnimation(AppAnimations.quick) {
                selection = item
            }
            playHaptic()
        } label: {
            HStack(spacing: 4) {
                Text(label(item))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                
                if isRecommended {
                    Text("★")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppColors.accent.opacity(0.7))
                }
            }
            .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AppColors.accent)
                        .shadow(color: AppColors.accentGlow, radius: 8, y: 2)
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(AppAnimations.quick) {
                pressedItem = pressing ? item : nil
            }
        }, perform: {})
    }
    
    private func playHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
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
