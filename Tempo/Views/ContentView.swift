import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tempo")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.bottom, 24)
            
            // Drop Zone
            DropZoneView()
            
            Spacer().frame(height: 32)
            
            // Controls - Only show when video is loaded
            if appState.videoInfo != nil {
                VStack(spacing: 28) {
                    SpeedSelectorView()
                    ResolutionSelectorView()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                
                Spacer().frame(height: 32)
            }
            
            Spacer()
            
            // Export Button
            ExportButtonView()
        }
        .padding(32)
        .frame(width: 440, height: 500)
        .background(AppColors.background)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.videoInfo != nil)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
