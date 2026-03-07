import SwiftUI

@main
struct TempoApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    Task {
                        await appState.loadVideo(from: url)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 680)
    }
}
