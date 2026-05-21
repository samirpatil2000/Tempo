import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Draggable header area (since title bar is hidden)
            header
                .padding(.bottom, 20)
            
            // Mode toggle
            OutlineSegmentedControl(
                items: AppMode.allCases,
                selection: $appState.mode,
                label: \.rawValue
            )
            .padding(.bottom, 20)
            
            // Main content — fills available space, no scrolling
            VStack(spacing: 28) {
                switch appState.mode {
                case .video:
                    videoContent
                    
                case .image:
                    imageContent
                }
                
                Spacer(minLength: 0)
                
                switch appState.mode {
                case .video:
                    ExportButtonView()
                    
                case .image:
                    ImageExportButtonView()
                }
            }
            .transition(.opacity)
        }
        .padding(.top, 44)       // Clear the traffic-light buttons on hidden title bar
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .frame(minWidth: 420, idealWidth: 480, minHeight: 580, idealHeight: 680)
        .background(AppColors.windowBackground)
        .animation(AppAnimations.smooth, value: appState.mode)
        .handlesExternalEvents(preferring: Set(arrayLiteral: "*"), allowing: Set(arrayLiteral: "*"))
    }
    
    // MARK: - Video Content
    
    private var videoContent: some View {
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
        }
    }
    
    // MARK: - Image Content
    
    private var imageContent: some View {
        VStack(spacing: 20) {
            ImageDropZoneView()
            
            if !appState.imageFiles.isEmpty {
                // Hairline separator
                Rectangle()
                    .fill(AppColors.hairline)
                    .frame(height: 0.5)
                    .padding(.horizontal, 4)
                
                ImageControlsView()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                let headerTitle = appState.mode == .video ? "Export Video" : "Compress Images"
                Text(headerTitle)
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundStyle(AppColors.textPrimary)
                
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                Text("Tempo v\(version)")
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

#Preview {
    ContentView()
        .environmentObject(AppState())
}
