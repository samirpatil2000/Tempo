import SwiftUI

@main
struct TempoApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(width: 480, height: 520)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
