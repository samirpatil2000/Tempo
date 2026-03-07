import SwiftUI

// MARK: - Speed Selector

struct SpeedSelectorView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with current value
            HStack {
                Text("Speed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                
                Spacer()
                
                // Current value badge — outline only
                HStack(spacing: 4) {
                    Text(String(format: "%.2f×", appState.speedMultiplier))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppColors.textPrimary)
                        .contentTransition(.numericText(countsDown: false))
                    
                    if let duration = formattedDuration {
                        Text("·")
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
                        .stroke(AppColors.hairline, lineWidth: 0.5)
                )
            }
            
            VStack(spacing: 18) {
                // Slider
                CustomSlider(value: $appState.speedMultiplier, range: 0.1...4.0)
                    .padding(.top, 4)
                
                // Preset pills — outline only
                HStack(spacing: 10) {
                    ForEach([0.5, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        OutlinePill(
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
                .frame(maxWidth: .infinity)
                
                // Speed description
                Text(speedDescription)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }
    
    private var speedDescription: String {
        let speed = appState.speedMultiplier
        if speed < 1.0 { return "Slow Motion" }
        if speed == 1.0 { return "Normal Speed" }
        if speed <= 1.5 { return "Cinematic Fast" }
        return "Timelapse"
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

// MARK: - Custom Minimal Slider

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
                // Track — thin, subtle
                Capsule()
                    .fill(AppColors.hairline)
                    .frame(height: 3)
                
                // Active track — just slightly brighter, no color
                Capsule()
                    .fill(AppColors.textTertiary)
                    .frame(width: max(3, width * clampedProgress), height: 3)
                
                // Thumb — clean white circle with subtle border
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                    .overlay(
                        Circle()
                            .stroke(AppColors.hairline, lineWidth: 0.5)
                    )
                    .offset(x: (width - 16) * clampedProgress)
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
            .frame(height: 16)
        }
        .frame(height: 16)
        .padding(.horizontal, 4)
    }
}

// MARK: - Outline Pill (No fill, border only)

struct OutlinePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.controlBackground : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? AppColors.selectedBorder : AppColors.hairline,
                            lineWidth: isSelected ? 1 : 0.5
                        )
                )
                .animation(AppAnimations.quick, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Resolution Selector

struct ResolutionSelectorView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            Text("Quality")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            
            // Outline segmented control
            OutlineSegmentedControl(
                items: Resolution.allCases,
                selection: $appState.targetResolution,
                label: \.rawValue
            )
            
            // Helper text
            Text("Higher resolution may increase export time and file size.")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}

// MARK: - Outline Segmented Control (Border only, no fill)

struct OutlineSegmentedControl<T: Hashable & Identifiable>: View {
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String
    
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                segmentButton(for: item)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.segmentTrack)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppColors.hairline, lineWidth: 0.5)
        )
    }
    
    private func segmentButton(for item: T) -> some View {
        let isSelected = selection.id == item.id
        
        return Button {
            withAnimation(AppAnimations.quick) {
                selection = item
            }
            playHaptic()
        } label: {
            Text(label(item))
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.controlBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppColors.selectedBorder, lineWidth: 0.75)
                            )
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    }
                }
        }
        .buttonStyle(.plain)
    }
    
    private func playHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
}

// MARK: - Legacy PresetButton (kept for compatibility)

struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        OutlinePill(title: title, isSelected: isSelected, action: action)
    }
}

// MARK: - Legacy SegmentedControl (kept for compatibility)

struct SegmentedControl<T: Hashable & Identifiable>: View {
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String
    var recommendedItem: T? = nil
    
    var body: some View {
        OutlineSegmentedControl(items: items, selection: $selection, label: label)
    }
}

#Preview {
    VStack(spacing: 32) {
        SpeedSelectorView()
        ResolutionSelectorView()
    }
    .padding(40)
    .background(AppColors.windowBackground)
    .environmentObject(AppState())
}
