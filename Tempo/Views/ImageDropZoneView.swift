import SwiftUI
import UniformTypeIdentifiers

struct ImageDropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false
    
    private let supportedTypes: [UTType] = [.jpeg, .png, .heic]
    
    var body: some View {
        VStack(spacing: 14) {
            Group {
                if appState.imageFiles.isEmpty {
                    emptyDropZone
                } else {
                    loadedImagesView
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
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
            
            // Image list below the drop zone (with scrolling)
            if !appState.imageFiles.isEmpty {
                VStack {
                    ImageListView()
                }
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 14)
            }
        }
    }
    
    // MARK: - Empty Drop Zone
    
    private var emptyDropZone: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.hairline)
                    .frame(width: 52, height: 52)
                
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            VStack(spacing: 4) {
                Text("Drop images here")
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
            selectImages()
        }
    }
    
    // MARK: - Loaded Images View
    
    private var loadedImagesView: some View {
        HStack(spacing: 14) {
            // Minimal icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppColors.hairline, lineWidth: 0.5)
                    )
                
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(width: 48, height: 48)
            
            // File count info
            VStack(alignment: .leading, spacing: 3) {
                let count = appState.imageFiles.count
                Text("\(count) \(count == 1 ? "image" : "images")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text(fileSizeInfo)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Change button
            Button {
                selectImages()
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
    
    private var fileSizeInfo: String {
        let totalSize = appState.imageFiles.reduce(0) { $0 + $1.originalSize }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
    
    // MARK: - Actions
    
    private func selectImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = supportedTypes
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            Task {
                await appState.loadImages(from: panel.urls)
            }
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            for type in supportedTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: type.identifier) { item, _ in
                        defer { group.leave() }
                        if let url = item as? URL {
                            urls.append(url)
                        } else if let data = item as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            urls.append(url)
                        }
                    }
                    break
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                Task {
                    await appState.loadImages(from: urls)
                }
            }
        }
        
        return true
    }
}

#Preview {
    ZStack {
        AppColors.windowBackground
            .ignoresSafeArea()
        
        VStack {
            ImageDropZoneView()
                .environmentObject(AppState())
        }
        .padding(32)
    }
}
