import Foundation

enum SevenZipLocator {
    static let overrideKey = "sevenZipPath"

    private static let homebrewPaths = ["/opt/homebrew/bin/7zz", "/usr/local/bin/7zz"]

    static var homebrewPath: String? {
        homebrewPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// The first 7zz that actually exists, checked in priority order.
    static func find() -> URL? {
        candidates().first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    private static func candidates() -> [URL] {
        var list: [URL] = []

        // 1. A path the user chose in Settings.
        if let custom = UserDefaults.standard.string(forKey: overrideKey), !custom.isEmpty {
            list.append(URL(fileURLWithPath: custom))
        }

        // 2. The copy bundled inside the app: Archiver.app/Contents/Resources/7zz
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("7zz") {
            list.append(bundled)
        }

        #if DEBUG
        // 3. Dev only: <project>/bin/7zz, worked out from this source file's location.
        let project = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // .../Sources/Engine
            .deletingLastPathComponent()   // .../Sources
            .deletingLastPathComponent()   // project root
        list.append(project.appendingPathComponent("bin/7zz"))
        #endif

        // 4. Last resort: Homebrew.
        list.append(contentsOf: homebrewPaths.map { URL(fileURLWithPath: $0) })

        return list
    }
}