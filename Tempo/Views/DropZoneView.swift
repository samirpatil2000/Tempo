import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false
    @State private var isHovering = false
    
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isTargeted ? AppColors.accent : AppColors.glassStroke,
                    lineWidth: isTargeted ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(isTargeted ? 0.1 : 0.05), radius: isTargeted ? 12 : 8, y: 4)
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
                    .fill(AppColors.accent.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(AppColors.accent)
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
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            selectVideo()
        }
    }
    
    // MARK: - Loaded Video View
    
    private func loadedVideoView(_ videoInfo: VideoInfo) -> some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.accent.opacity(0.1))
                
                Image(systemName: "film")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColors.accent)
            }
            .frame(width: 52, height: 52)
            
            // File info
            VStack(alignment: .leading, spacing: 3) {
                Text(videoInfo.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 6) {
                    Text(videoInfo.durationFormatted)
                    Text("•")
                    Text("\(Int(videoInfo.resolution.width))×\(Int(videoInfo.resolution.height))")
                }
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Change button
            Button {
                selectVideo()
            } label: {
                Text("Change")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppColors.accent.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
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
