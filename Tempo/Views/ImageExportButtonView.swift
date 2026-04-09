import SwiftUI

struct ImageExportButtonView: View {
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 10) {
            content
            
            // Microcopy
            if appState.imageExportState == .idle, !appState.imageFiles.isEmpty {
                estimatedInfo
            }
        }
        .frame(maxWidth: .infinity)
        .animation(AppAnimations.smooth, value: appState.imageExportState)
    }
    
    @ViewBuilder
    private var content: some View {
        switch appState.imageExportState {
        case .idle:
            compressButton
            
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
        let totalSize = appState.imageFiles.reduce(0) { $0 + $1.originalSize }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        
        return Text("~\(formatter.string(fromByteCount: totalSize)) total")
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(AppColors.textTertiary)
    }
    
    // MARK: - Compress Button (The ONE accent element)
    
    private var compressButton: some View {
        Button(action: startExport) {
            HStack(spacing: 8) {
                let count = appState.imageFiles.count
                Text(count == 1 ? "Compress Image" : "Compress Images")
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
                        !appState.imageFiles.isEmpty
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
                color: !appState.imageFiles.isEmpty ? AppColors.accentGlow : .clear,
                radius: isPressed ? 4 : 10,
                y: isPressed ? 1 : 3
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(appState.imageFiles.isEmpty)
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
                
                let progress: Double = appState.imageFiles.isEmpty ? 0 :
                    Double(appState.imageFiles.filter { if case .complete = $0.exportState { return true } else { return false } }.count) / Double(appState.imageFiles.count)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.textSecondary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
            }
            
            let completed = appState.imageFiles.filter { if case .complete = $0.exportState { return true } else { return false } }.count
            let total = appState.imageFiles.count
            Text("Compressing \(completed) of \(total)…")
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
            
            Text("All Done")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            HStack(spacing: 20) {
                Button {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.path)
                } label: {
                    Text("Reveal in Finder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.resetImages()
                } label: {
                    Text("Compress More")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    appState.resetImages()
                } label: {
                    Text("Start Over")
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
            
            Text("Compression Failed")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                appState.imageExportState = .idle
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    
    private func startExport() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Choose Output Folder"
        
        guard panel.runModal() == .OK, let outputURL = panel.url else { return }
        
        Task {
            await appState.exportImages(to: outputURL)
        }
    }
    
    private func cancelExport() {
        appState.imageExportState = .idle
    }
}

#Preview {
    ZStack {
        AppColors.windowBackground
            .ignoresSafeArea()
        
        VStack {
            ImageExportButtonView()
                .environmentObject(AppState())
        }
        .padding(32)
    }
}
