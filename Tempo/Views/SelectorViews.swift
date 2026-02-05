import SwiftUI

// MARK: - Speed Selector

struct SpeedSelectorView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEditingSlider = false
    
    // Available presets
    let presets: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with current value
            HStack {
                Label("Playback Speed", systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                
                Spacer()
                
                // Current Value Display
                HStack(spacing: 4) {
                    if #available(macOS 13.0, *) {
                        Text(String(format: "%.2f×", appState.speedMultiplier))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppColors.textPrimary)
                            .contentTransition(.numericText(countsDown: false))
                    } else {
                        Text(String(format: "%.2f×", appState.speedMultiplier))
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    
                    if let duration = formattedDuration {
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)
                        Text(duration)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .font(.system(size: 12))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppColors.segmentBackground)
                )
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 20) {
                // Custom Slider
                CustomSlider(value: $appState.speedMultiplier, range: 0.1...4.0)
                
                // Presets Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { speed in
                            PresetButton(
                                title: String(format: "%g×", speed),
                                isSelected: abs(appState.speedMultiplier - speed) < 0.01
                            ) {
                                withAnimation(AppAnimations.quick) {
                                    appState.speedMultiplier = speed
                                }
                                playHaptic()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private var formattedDuration: String? {
        guard let originalDuration = appState.videoInfo?.duration else { return nil }
        let newDuration = originalDuration / appState.speedMultiplier
        let minutes = Int(newDuration) / 60
        let seconds = Int(newDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func playHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }
}

// MARK: - Custom Glass Slider

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let clampedProgress = max(0, min(1, progress))
            
            ZStack(alignment: .leading) {
                // Track Background
                Capsule()
                    .fill(AppColors.segmentBackground)
                    .frame(height: 6)
                
                // Active Track
                Capsule()
                    .fill(LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(6, width * clampedProgress), height: 6)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.glassStroke, lineWidth: 0.5)
                    )
                    .offset(x: (width - 20) * clampedProgress)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let dragValue = value.location.x / width
                                let newValue = range.lowerBound + (dragValue * (range.upperBound - range.lowerBound))
                                self.value = max(range.lowerBound, min(range.upperBound, newValue))
                            }
                            .onEnded { _ in
                                isDragging = false
                                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                            }
                    )
            }
            .frame(height: 20)
        }
        .frame(height: 20)
        .padding(.horizontal, 4)
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.accent : AppColors.segmentBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(AppColors.glassStroke, lineWidth: 0.5)
                )
                .scaleEffect(isSelected ? 1.0 : 0.95)
                .animation(AppAnimations.quick, value: isSelected)
        }
        .buttonStyle(.plain)
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
