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
                        await handleOpenURL(url)
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 680)
    }
    
    // MARK: - URL Handling
    
    private func handleOpenURL(_ url: URL) async {
        let pathExtension = url.pathExtension.lowercased()
        
        // Check if image
        if ["jpg", "jpeg", "png", "heic"].contains(pathExtension) {
            await appState.loadImage(from: url)
        } else {
            // Treat as video
            await appState.loadVideo(from: url)
        }
    }
}
