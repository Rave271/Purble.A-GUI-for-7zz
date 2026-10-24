import Foundation

enum ExtractOutcome: Sendable {
    case success
    case wrongPassword
    case failed(String)
}

enum ExtractEvent: Sendable {
    case progress(Int)
    case finished(ExtractOutcome)
}
final class OutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""
    private var lastPercent = -1

    // Returns a percentage only when it changed.
    func feed(_ chunk: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }

        buffer += chunk.replacingOccurrences(of: "\u{08}", with: "")
        if buffer.count > 4000 { buffer = String(buffer.suffix(4000)) }

        guard let pct = buffer.lastIndex(of: "%") else { return nil }
        let digits = buffer[..<pct].reversed().prefix(while: { $0.isNumber }).reversed()
        guard let value = Int(String(digits)), value != lastPercent else { return nil }

        lastPercent = value
        return value
    }

    var log: String {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
}

struct SevenZipEngine: Sendable {
    let binary: URL

    func extract(archive: String, to outDir: String, password: String? = nil) -> AsyncStream<ExtractEvent> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = binary

            var args = ["x", archive, "-o\(outDir)", "-y", "-aou", "-bsp1"]
            if let password { args.append("-p\(password)") }
            process.arguments = args

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            process.standardInput = FileHandle.nullDevice

            let collector = OutputCollector()

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let percent = collector.feed(String(decoding: data, as: UTF8.self)) {
                    continuation.yield(.progress(percent))
                }
            }

            process.terminationHandler = { finished in
                pipe.fileHandleForReading.readabilityHandler = nil
                let rest = pipe.fileHandleForReading.readDataToEndOfFile()
                if !rest.isEmpty { _ = collector.feed(String(decoding: rest, as: UTF8.self)) }

              let log = collector.log
let outcome: ExtractOutcome
if finished.terminationStatus == 0 {
    continuation.yield(.progress(100))
    outcome = .success
} else if log.localizedCaseInsensitiveContains("wrong password")
            || log.localizedCaseInsensitiveContains("enter password") {
    outcome = .wrongPassword
} else {
    outcome = .failed(log)
}
continuation.yield(.finished(outcome))
continuation.finish()
            }

            continuation.onTermination = { _ in
                if process.isRunning { process.terminate() }
            }

            do {
                try process.run()
            } catch {
               continuation.yield(.finished(.failed("Could not start 7zz: \(error)")))
                continuation.finish()
            }
        }
    }
}
