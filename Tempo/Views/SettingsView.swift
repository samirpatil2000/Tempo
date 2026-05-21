import SwiftUI

struct SettingsView: View {
    @AppStorage("tempoAutoCheckForUpdates") private var autoCheck = true

    var body: some View {
        VStack(spacing: 20) {
            // App Info Section
            HStack(spacing: 16) {
                if let appIcon = NSApp.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "clock.fill")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tempo")
                        .font(.system(size: 16, weight: .bold))
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "2"
                    Text("Version \(version) (Build \(build))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 8)

            Divider()

            // Update Settings Section
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Check for updates automatically", isOn: $autoCheck)
                    .font(.system(size: 13))

                HStack {
                    Button("Check for Updates...") {
                        UpdateService.shared.checkForUpdates(silent: false)
                    }
                    Spacer()
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 380, height: 200)
    }
}

#Preview {
    SettingsView()
}
