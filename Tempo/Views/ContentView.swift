import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Draggable header area (since title bar is hidden)
            header
                .padding(.bottom, 20)
            
            // Main content — fills available space, no scrolling
            VStack(spacing: 28) {
                DropZoneView()
                
                if appState.videoInfo != nil {
                    // Hairline separator
                    Rectangle()
                        .fill(AppColors.hairline)
                        .frame(height: 0.5)
                        .padding(.horizontal, 4)
                    
                    SpeedSelectorView()
                    
                    // Hairline separator
                    Rectangle()
                        .fill(AppColors.hairline)
                        .frame(height: 0.5)
                        .padding(.horizontal, 4)
                    
                    ResolutionSelectorView()
                }
                
                Spacer(minLength: 0)
                
                ExportButtonView()
            }
            .transition(.opacity)
        }
        .padding(32)
        .frame(minWidth: 420, idealWidth: 480, minHeight: 580, idealHeight: 680)
        .background(AppColors.windowBackground)
        .animation(AppAnimations.smooth, value: appState.videoInfo != nil)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Export Video")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Tempo")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(AppColors.textTertiary)
            }
            
            Spacer()
        }
        // Make the header area draggable for window movement
        .background(Color.clear)
        .onTapGesture(count: 2) {
            // Double-click to zoom (standard macOS behavior)
            if let window = NSApplication.shared.mainWindow {
                window.zoom(nil)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
