import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false
    
    private let supportedTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
    
    var body: some View {
        Group {
            if let videoInfo = appState.videoInfo {
                loadedVideoView(videoInfo)
            } else {
                emptyDropZone
            }
        }
        .frame(maxWidth: .infinity)
        .padding(appState.videoInfo != nil ? 14 : 20)
        .glassCard(cornerRadius: 14)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isTargeted ? AppColors.accent.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isTargeted ? 0.985 : 1.0)
        .animation(AppAnimations.quick, value: isTargeted)
        .onDrop(of: supportedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }
    
    // MARK: - Empty Drop Zone
    
    private var emptyDropZone: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.hairline)
                    .frame(width: 52, height: 52)
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            VStack(spacing: 4) {
                Text("Drop video here")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("or click to browse")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            selectVideo()
        }
    }
    
    // MARK: - Loaded Video View
    
    private func loadedVideoView(_ videoInfo: VideoInfo) -> some View {
        HStack(spacing: 14) {
            // Minimal icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppColors.hairline, lineWidth: 0.5)
                    )
                
                Image(systemName: "film")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(width: 48, height: 48)
            
            // File info
            VStack(alignment: .leading, spacing: 3) {
                Text(videoInfo.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 6) {
                    Text(videoInfo.durationFormatted)
                    Text("·")
                    Text("\(Int(videoInfo.resolution.width))×\(Int(videoInfo.resolution.height))")
                }
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Change — just text, no button chrome
            Button {
                selectVideo()
            } label: {
                Text("Change")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = supportedTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await appState.loadVideo(from: url)
            }
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        for type in supportedTypes {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                provider.loadItem(forTypeIdentifier: type.identifier) { item, _ in
                    if let url = item as? URL {
                        Task { @MainActor in
                            await appState.loadVideo(from: url)
                        }
                    } else if let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) {
                        Task { @MainActor in
                            await appState.loadVideo(from: url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
