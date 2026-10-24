import Foundation

struct VolumeSet {
    let first: URL        // the file we hand to 7zz
    let parts: [URL]      // every part found in the folder
    let missing: [String] // gaps in the numbering
    let baseName: String  // "big.7z.003" -> "big"

    var totalSize: Int64 {
        parts.reduce(Int64(0)) { sum, url in
            sum + Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }

    var summary: String {
        let size = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        if parts.count == 1 && missing.isEmpty { return size }
        return "\(parts.count) \(parts.count == 1 ? "part" : "parts") · \(size)"
    }

    static func resolve(_ url: URL) -> VolumeSet {
        let dir = url.deletingLastPathComponent()
        let siblings = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        let ext = url.pathExtension
        let stem = url.deletingPathExtension().lastPathComponent

        // Style 1: big.7z.001, big.7z.002, ...
        if ext.count >= 3, ext.allSatisfy(\.isNumber) {
            return build(dir: dir, siblings: siblings, head: stem + ".", tail: "",
                         width: ext.count,
                         baseName: (stem as NSString).deletingPathExtension,
                         original: url)
        }

        // Style 2: big.part1.rar, big.part2.rar, ...
        if ext.lowercased() == "rar",
           let range = stem.range(of: ".part", options: [.caseInsensitive, .backwards]) {
            let digits = stem[range.upperBound...]
            if !digits.isEmpty, digits.allSatisfy(\.isNumber) {
                let prefix = String(stem[..<range.lowerBound])
                return build(dir: dir, siblings: siblings, head: prefix + ".part", tail: ".rar",
                             width: digits.count, baseName: prefix, original: url)
            }
        }

        // Anything else is a normal single archive.
        return VolumeSet(first: url, parts: [url], missing: [],
                         baseName: stem)
    }

    private static func build(dir: URL, siblings: [String], head: String, tail: String,
                              width: Int, baseName: String, original: URL) -> VolumeSet {
        var found: [Int: String] = [:]
        for file in siblings {
            let lower = file.lowercased()
            guard lower.hasPrefix(head.lowercased()),
                  lower.hasSuffix(tail.lowercased()),
                  file.count > head.count + tail.count else { continue }
            let middle = file.dropFirst(head.count).dropLast(tail.count)
            if middle.count == width, middle.allSatisfy(\.isNumber), let n = Int(middle) {
                found[n] = file
            }
        }

        guard let last = found.keys.max() else {
            return VolumeSet(first: original, parts: [original], missing: [], baseName: baseName)
        }

        func name(_ n: Int) -> String { head + String(format: "%0\(width)ld", n) + tail }

        let missing = (1...last).filter { found[$0] == nil }.map(name)
        let parts = found.keys.sorted().map { dir.appendingPathComponent(found[$0]!) }
        let first = dir.appendingPathComponent(found[1] ?? name(1))
        return VolumeSet(first: first, parts: parts, missing: missing, baseName: baseName)
    }
}