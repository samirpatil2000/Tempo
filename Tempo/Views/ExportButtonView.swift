import SwiftUI

struct ExportButtonView: View {
    @EnvironmentObject var appState: AppState
    @State private var processor: VideoProcessor?
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)
                .padding(.bottom, 20)
            
            content
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: appState.exportState)
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
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Button(action: startExport) {
            Text("Export Video")
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(appState.canExport ? AppColors.accent : Color.primary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .disabled(!appState.canExport)
        .scaleEffect(appState.canExport ? 1.0 : 1.0) // No scale on disable
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Exporting...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("\(Int(appState.exportProgress * 100))%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            // Minimalist Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.accent)
                        .frame(width: geometry.size.width * appState.exportProgress, height: 4)
                        .animation(.easeInOut(duration: 0.1), value: appState.exportProgress)
                }
            }
            .frame(height: 4)
            
            Button("Cancel") {
                cancelExport()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.secondary)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Completion View
    
    private func completionView(url: URL) -> some View {
        VStack(spacing: 12) {
            Text("Export Complete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.success)
            
            HStack(spacing: 16) {
                Button {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                } label: {
                    Text("Show in Finder")
                }
                .buttonStyle(LinkButtonStyle())
                
                Button {
                    appState.exportState = .idle
                    appState.exportProgress = 0
                } label: {
                    Text("New Export")
                }
                .buttonStyle(LinkButtonStyle())
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text("Export Failed")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.error)
            
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Button("Try Again") {
                appState.exportState = .idle
            }
            .buttonStyle(LinkButtonStyle())
        }
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
            speed: appState.speedMultiplier.rawValue,
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
        let speed = appState.speedMultiplier.label.replacingOccurrences(of: "×", with: "x")
        let resolution = appState.targetResolution.rawValue
        return "\(baseName)_\(speed)_\(resolution).mp4"
    }
}

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppColors.accent)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
