import SwiftUI

struct ExportButtonView: View {
    @EnvironmentObject var appState: AppState
    @State private var processor: VideoProcessor?
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 10) {
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
                Text(duration)
            }
            if let size = estimatedSize {
                Text("·")
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
    
    // MARK: - Export Button (The ONE accent element)
    
    private var exportButton: some View {
        Button(action: startExport) {
            HStack(spacing: 8) {
                Text("Export Video")
                    .font(.system(size: 15, weight: .semibold))
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        appState.canExport
                            ? LinearGradient(
                                colors: [
                                    AppColors.accent,
                                    AppColors.accent.opacity(0.85)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [AppColors.textTertiary],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                    )
            )
            .shadow(
                color: appState.canExport ? AppColors.accentGlow : .clear,
                radius: isPressed ? 4 : 10,
                y: isPressed ? 1 : 3
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
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
        VStack(spacing: 14) {
            // Circular progress — minimal
            ZStack {
                Circle()
                    .stroke(AppColors.hairline, lineWidth: 3)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: appState.exportProgress)
                    .stroke(AppColors.textSecondary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: appState.exportProgress)
                
                Text("\(Int(appState.exportProgress * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            Text("Exporting…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            
            Button("Cancel") {
                cancelExport()
            }
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(AppColors.textTertiary)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Completion View
    
    private func completionView(url: URL) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.success)
            
            Text("Export Complete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            HStack(spacing: 20) {
                Button {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                } label: {
                    Text("Reveal in Finder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.exportState = .idle
                    appState.exportProgress = 0
                } label: {
                    Text("Done")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.error)
            
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
            .foregroundStyle(AppColors.textSecondary)
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
