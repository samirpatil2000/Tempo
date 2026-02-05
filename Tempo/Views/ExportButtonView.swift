import SwiftUI

struct ExportButtonView: View {
    @EnvironmentObject var appState: AppState
    @State private var processor: VideoProcessor?
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            content
            
            // Microcopy
            if appState.exportState == .idle, appState.videoInfo != nil {
                estimatedInfo
            }
        }
        .frame(maxWidth: .infinity)
        .animation(AppAnimations.smooth, value: appState.exportState)
    }
    
    @ViewBuilder
    private var content: some View {
        switch appState.exportState {
        case .idle:
            exportButton
            
        case .processing:
            progressView
            
        case .complete(let url):
            completionView(url: url)
            
        case .error(let message):
            errorView(message: message)
        }
    }
    
    // MARK: - Estimated Info
    
    private var estimatedInfo: some View {
        HStack(spacing: 6) {
            if let duration = estimatedDuration {
                Text("Duration: \(duration)")
            }
            if let size = estimatedSize {
                Text("•")
                Text("~\(size)")
            }
        }
        .font(.system(size: 11, weight: .regular))
        .foregroundStyle(AppColors.textTertiary)
    }
    
    private var estimatedDuration: String? {
        guard let originalDuration = appState.videoInfo?.duration else { return nil }
        let newDuration = originalDuration / appState.speedMultiplier
        let minutes = Int(newDuration) / 60
        let seconds = Int(newDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var estimatedSize: String? {
        guard let duration = appState.videoInfo?.duration else { return nil }
        let adjustedDuration = duration / appState.speedMultiplier
        let bitrate = appState.targetResolution.bitrate
        let sizeBytes = Double(bitrate) * adjustedDuration / 8
        let sizeMB = sizeBytes / 1_000_000
        
        if sizeMB < 1 {
            return String(format: "%.0f KB", sizeBytes / 1000)
        } else if sizeMB >= 1000 {
            return String(format: "%.1f GB", sizeMB / 1000)
        }
        return String(format: "%.0f MB", sizeMB)
    }
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Button(action: startExport) {
            HStack(spacing: 8) {
                Text("Export Video")
                    .font(.system(size: 15, weight: .semibold))
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(appState.canExport ? AppColors.accent : AppColors.textTertiary)
            )
            .shadow(color: appState.canExport ? AppColors.accentGlow : .clear, radius: isPressed ? 4 : 12, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!appState.canExport)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(AppAnimations.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        VStack(spacing: 16) {
            // Circular progress
            ZStack {
                Circle()
                .stroke(AppColors.segmentBackground, lineWidth: 4)
                .frame(width: 56, height: 56)
                
                Circle()
                .trim(from: 0, to: appState.exportProgress)
                .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: appState.exportProgress)
                
                Text("\(Int(appState.exportProgress * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
            }
            
            Text("Exporting...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            
            Button("Cancel") {
                cancelExport()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppColors.textTertiary)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Completion View
    
    private func completionView(url: URL) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.success)
            }
            
            Text("Export Complete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            HStack(spacing: 20) {
                Button {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                } label: {
                    Text("Show in Finder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.accent)
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.exportState = .idle
                    appState.exportProgress = 0
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.error.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.error)
            }
            
            Text("Export Failed")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                appState.exportState = .idle
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppColors.accent)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    
    private func startExport() {
        guard let videoInfo = appState.videoInfo else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = generateOutputFilename(from: videoInfo.fileName)
        
        guard panel.runModal() == .OK, let outputURL = panel.url else { return }
        
        appState.exportState = .processing
        appState.exportProgress = 0
        
        let newProcessor = VideoProcessor(
            inputURL: videoInfo.url,
            outputURL: outputURL,
            speed: appState.speedMultiplier,
            targetResolution: appState.targetResolution
        )
        processor = newProcessor
        
        Task {
            do {
                for try await progress in newProcessor.process() {
                    appState.exportProgress = progress
                }
                appState.exportState = .complete(outputURL)
            } catch {
                if !Task.isCancelled {
                    appState.exportState = .error(error.localizedDescription)
                }
            }
            processor = nil
        }
    }
    
    private func cancelExport() {
        processor?.cancel()
        processor = nil
        appState.exportState = .idle
        appState.exportProgress = 0
    }
    
    private func generateOutputFilename(from original: String) -> String {
        let baseName = (original as NSString).deletingPathExtension
        
        // Format speed string clean: "1x", "1.5x", etc
        let speed = appState.speedMultiplier
        let speedString: String
        if floor(speed) == speed {
            speedString = String(format: "%.0fx", speed)
        } else {
            speedString = String(format: "%.2fx", speed)
        }
        
        let resolution = appState.targetResolution.rawValue
        return "\(baseName)_\(speedString)_\(resolution).mp4"
    }
}
