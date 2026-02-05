import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            header
                .padding(.bottom, 16)
                .background(AppColors.surfaceElevated) // Ensure background opacity for scroll behind
                .zIndex(1)
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    // Media Info Card / Drop Zone
                    DropZoneView()
                    
                    // Controls - Only show when video is loaded
                    if appState.videoInfo != nil {
                        VStack(spacing: 32) {
                            SpeedSelectorView()
                            ResolutionSelectorView()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.vertical, 4) // Slight top padding inside scroll
                .padding(.bottom, 24) // Bottom breathing room
            }
            .scrollIndicators(.hidden) // "No visible scrollbars"
            
            // Fixed Footer
            ExportButtonView()
                .padding(.top, 20)
                .background(AppColors.surfaceElevated)
                .zIndex(1)
        }
        .padding(24)
        .frame(width: 420, height: 520)
        .background(AppColors.surfaceElevated)
        .animation(AppAnimations.smooth, value: appState.videoInfo != nil)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Export Video")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Tempo")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(AppColors.textTertiary)
            }
            
            Spacer()
            
            // App icon placeholder
            Image(systemName: "film.stack")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.accent.opacity(0.8))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.segmentBackground)
                )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
