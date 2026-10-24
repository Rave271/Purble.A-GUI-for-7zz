import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage(SevenZipLocator.overrideKey) private var customPath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7zz engine").font(.headline)

            Text("Using: \(SevenZipLocator.find()?.path ?? "not found")")
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            HStack {
                TextField("Custom path (empty = built-in copy)", text: $customPath)
                    .textFieldStyle(.roundedBorder)
                Button("Choose…") { choose() }
                Button("Reset") { customPath = "" }
            }

            if !customPath.isEmpty && !FileManager.default.isExecutableFile(atPath: customPath) {
                Text("That file isn't executable, so the default is used instead.")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            if let brew = SevenZipLocator.homebrewPath {
                Button("Use Homebrew's 7zz") { customPath = brew }
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    @MainActor private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { customPath = url.path }
    }
}