import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum Phase: Equatable {
    case idle, running, success, wrongPassword, cancelled
    case failed(String)
}

@main
struct PurbleApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("Purble") { ContentView() }
            .windowResizability(.contentSize)
        Settings { SettingsView() }
    }
}

struct ContentView: View {
    @State private var archive: URL?
    @State private var volumes: VolumeSet?
    @State private var outputFolder: URL?
    @State private var password = ""
    @State private var needsPassword = false
    @State private var progress = 0
    @State private var phase: Phase = .idle
    @State private var dropTargeted = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 18) {
            dropZone
            if archive != nil { outputRow }
            if needsPassword { passwordField }
            if phase != .idle { progressSection }
            actionRow
        }
        .padding(28)
        .frame(width: 460)
        .background(Theme.black)
        .foregroundStyle(Theme.white)
        .font(.system(size: 12, design: .monospaced))
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: phase)
        .animation(.easeInOut(duration: 0.2), value: needsPassword)
        .animation(.easeInOut(duration: 0.2), value: archive)
    }

    // MARK: - Pieces

    private var dropZone: some View {
        VStack(spacing: 8) {
            Image(systemName: archive == nil ? "arrow.down.doc" : "doc.zipper")
                .font(.system(size: 30, weight: .thin))
                .foregroundStyle(Theme.purple)
            Text(archive?.lastPathComponent ?? "Drop an archive here")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            if let volumes {
                Text(volumes.summary).foregroundStyle(Theme.dim)
            } else {
                Text("or click to choose").foregroundStyle(Theme.dim)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(.horizontal, 12)
        .background(dropTargeted ? Theme.purple.opacity(0.15) : Color.clear)
.selectionFrame(dashed: archive == nil && !dropTargeted)
        .contentShape(Rectangle())
        .onTapGesture { if phase != .running { chooseArchive() } }
        .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in
            guard phase != .running, let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                Task { @MainActor in setArchive(url) }
            }
            return true
        }
    }

    private var outputRow: some View {
        VStack(spacing: 6) {
            SectionLabel(text: "Output")
            HStack(spacing: 8) {
                Image(systemName: "folder").foregroundStyle(Theme.purple)
                Text(outputFolder.map { ($0.path as NSString).abbreviatingWithTildeInPath } ?? "")
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Change") { chooseFolder() }
                    .buttonStyle(WireButton())
                    .disabled(phase == .running)
            }
            .padding(10)
.selectionFrame(color: Theme.line)        }
    }

    private var passwordField: some View {
        VStack(spacing: 6) {
            SectionLabel(text: "Password")
            HStack(spacing: 8) {
                Image(systemName: "lock").foregroundStyle(Theme.purple)
                SecureField("Required to open this archive", text: $password)
                    .textFieldStyle(.plain)
                    .onSubmit { start() }
            }
            .padding(10)
.selectionFrame(color: Theme.line)        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Status")
            if phase == .running || phase == .success {
                WireProgress(value: Double(progress) / 100)
            }
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: statusIcon).foregroundStyle(statusColor)
                Text(statusText)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                Spacer()
                if phase == .running {
                    Text("\(progress)%").monospacedDigit().foregroundStyle(Theme.dim)
                }
            }
        }
    }

    @ViewBuilder private var actionRow: some View {
        HStack(spacing: 10) {
            switch phase {
            case .running:
                Button("Cancel") { task?.cancel() }
                    .buttonStyle(WireButton())
            case .success:
                Button("Show in Finder") { revealOutput() }
                    .buttonStyle(WireButton(prominent: true))
                Button("Extract another") { reset() }
                    .buttonStyle(WireButton())
            default:
                Button("Extract") { start() }
                    .buttonStyle(WireButton(prominent: true))
                    .keyboardShortcut(.defaultAction)
                    .disabled(archive == nil || outputFolder == nil)
            }
        }
    }

    // MARK: - Status text

    private var statusText: String {
        switch phase {
        case .idle: return ""
        case .running: return "Extracting…"
        case .success: return "Extracted successfully"
        case .wrongPassword: return "Password needed or incorrect"
        case .cancelled: return "Cancelled"
        case .failed(let message): return "Failed: \(message)"
        }
    }

    private var statusIcon: String {
        switch phase {
        case .idle, .running: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.square.fill"
        case .wrongPassword: return "lock.square.fill"
        case .cancelled: return "xmark.square"
        case .failed: return "exclamationmark.square.fill"
        }
    }

    private var statusColor: Color {
        switch phase {
        case .success, .running: return Theme.purple
        case .idle, .cancelled: return Theme.dim
        case .wrongPassword, .failed: return Theme.white
        }
    }

    // MARK: - Actions

    @MainActor private func setArchive(_ url: URL) {
        let set = VolumeSet.resolve(url)
        volumes = set
        archive = set.first
        // Default output: a folder next to the archive, named after it.
        outputFolder = set.first.deletingLastPathComponent()
            .appendingPathComponent(set.baseName)
        password = ""
        needsPassword = false
        progress = 0
        phase = set.missing.isEmpty ? .idle : .failed(missingText(set))
    }

    private func missingText(_ set: VolumeSet) -> String {
        let names = set.missing.prefix(3).joined(separator: ", ")
        let more = set.missing.count > 3 ? " and \(set.missing.count - 3) more" : ""
        return "missing \(names)\(more). Put them in the same folder, then click Extract."
    }

    @MainActor private func chooseArchive() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { setArchive(url) }
    }

    @MainActor private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        if panel.runModal() == .OK { outputFolder = panel.url }
    }

    @MainActor private func start() {
        guard let archive, let outputFolder, phase != .running else { return }

        // Re-scan so a part added since the drop gets picked up.
        let set = VolumeSet.resolve(archive)
        volumes = set
        if !set.missing.isEmpty {
            phase = .failed(missingText(set))
            return
        }

        guard let binary = SevenZipLocator.find() else {
            phase = .failed("7zz not found. Open Settings (⌘,) to choose it, or run: brew install sevenzip")
            return
        }
        let engine = SevenZipEngine(binary: binary)

        phase = .running
        progress = 0
        let pwd = password.isEmpty ? nil : password

        task = Task {
            let events = engine.extract(archive: archive.path, to: outputFolder.path, password: pwd)
            for await event in events {
                switch event {
                case .progress(let percent):
                    progress = percent
                case .finished(let outcome):
                    switch outcome {
                    case .success:
                        phase = .success
                    case .wrongPassword:
                        phase = .wrongPassword
                        needsPassword = true
                        progress = 0
                    case .failed(let log):
                        phase = .failed(String(log.suffix(200)))
                        progress = 0
                    }
                }
            }
            if Task.isCancelled {
                phase = .cancelled
                progress = 0
            }
        }
    }

    @MainActor private func revealOutput() {
        if let outputFolder { NSWorkspace.shared.open(outputFolder) }
    }

    @MainActor private func reset() {
        archive = nil
        volumes = nil
        outputFolder = nil
        password = ""
        needsPassword = false
        progress = 0
        phase = .idle
    }
}