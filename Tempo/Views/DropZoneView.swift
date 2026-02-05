import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false
    
    private let supportedTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
    
    var body: some View {
        VStack(spacing: 0) {
            if let videoInfo = appState.videoInfo {
                loadedVideoView(videoInfo)
            } else {
                emptyDropZone
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isTargeted ? AppColors.accent : Color.primary.opacity(0.08),
                    lineWidth: isTargeted ? 2 : 1
                )
        )
        .scaleEffect(isTargeted ? 0.99 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isTargeted)
        .onDrop(of: supportedTypes, isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }
    
    // MARK: - Empty Drop Zone
    
    private var emptyDropZone: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppColors.accent.opacity(0.8))
            
            VStack(spacing: 6) {
                Text("Drag & Drop Video")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Text("or click to browse")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 100)
        .contentShape(Rectangle())
        .onTapGesture {
            selectVideo()
        }
    }
    
    // MARK: - Loaded Video View
    
    private var changeButton: some View {
         Button {
             selectVideo()
         } label: {
             Text("Change")
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundStyle(AppColors.accent)
         }
         .buttonStyle(.plain)
    }

    private func loadedVideoView(_ videoInfo: VideoInfo) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            Image(systemName: "film")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(AppColors.accent)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColors.accent.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(videoInfo.fileName)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 8) {
                    Text(videoInfo.durationFormatted)
                    Text("·")
                    Text("\(Int(videoInfo.resolution.width))×\(Int(videoInfo.resolution.height))")
                }
                .font(.system(size: 11, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            changeButton
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
