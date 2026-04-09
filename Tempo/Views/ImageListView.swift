import SwiftUI

struct ImageListView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                ForEach(appState.imageFiles) { file in
                    ImageFileRow(imageFile: file)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    if file.id != appState.imageFiles.last?.id {
                        Divider()
                            .background(AppColors.hairline)
                            .frame(height: 0.5)
                            .padding(.horizontal, 0)
                    }
                }
            }
        }
        .frame(maxHeight: 200)
    }
}

struct ImageFileRow: View {
    @EnvironmentObject var appState: AppState
    let imageFile: ImageFile
    @State private var isHovering = false
    @State private var thumbnail: NSImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: thumbnail preview
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppColors.hairline, lineWidth: 0.5)
                    )
                
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(5)
                } else {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .frame(width: 56, height: 56)
            
            // Middle: filename and sizes
            VStack(alignment: .leading, spacing: 4) {
                Text(imageFile.fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Before")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundStyle(AppColors.textTertiary)
                        Text(imageFile.originalSizeFormatted)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    
                    if let compressedFormatted = imageFile.compressedSizeFormatted {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("After")
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(AppColors.textTertiary)
                            Text(compressedFormatted)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Right: status or savings pill
            switch imageFile.exportState {
            case .idle:
                EmptyView()
                
            case .processing:
                ProgressView()
                    .scaleEffect(0.75, anchor: .center)
                
            case .complete:
                if let savingsPercent = imageFile.savingsPercent {
                    VStack(alignment: .center, spacing: 2) {
                        Text("−\(savingsPercent)%")
                            .font(.system(size: 11, weight: .semibold))
                        Text("saved")
                            .font(.system(size: 8, weight: .regular))
                    }
                    .foregroundStyle(savingsPercent > 40 ? AppColors.success : AppColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(savingsPercent > 40 ? AppColors.success.opacity(0.12) : Color.clear)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                savingsPercent > 40 ? AppColors.success.opacity(0.3) : AppColors.hairline,
                                lineWidth: 0.5
                            )
                    )
                }
                
            case .error:
                VStack(alignment: .center, spacing: 2) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                    Text("Failed")
                        .font(.system(size: 8, weight: .regular))
                }
                .foregroundStyle(AppColors.error)
            }
            
            // Far right: remove button (only on hover)
            if isHovering {
                Button(action: {
                    withAnimation(AppAnimations.quick) {
                        appState.removeImage(id: imageFile.id)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Remove image")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOf: imageFile.url) {
                DispatchQueue.main.async {
                    self.thumbnail = image
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.windowBackground
            .ignoresSafeArea()
        
        VStack {
            ImageListView()
                .environmentObject(AppState())
        }
        .padding(32)
    }
}
