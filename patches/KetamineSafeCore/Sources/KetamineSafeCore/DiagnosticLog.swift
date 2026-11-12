import Foundation

public enum DiagnosticLevel: String, Sendable, Codable {
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
}

public struct DiagnosticEvent: Sendable, Equatable, Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let level: DiagnosticLevel
    public let code: String
    public let message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: DiagnosticLevel,
        code: String,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.code = code
        self.message = message
    }

    public var line: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return "[\(level.rawValue)] \(formatter.string(from: timestamp)) \(code): \(message)"
    }
}

public final class DiagnosticLog: @unchecked Sendable {
    public static let shared = DiagnosticLog()

    private let lock = NSLock()
    private var events: [DiagnosticEvent] = []
    private let limit = 500

    public init() {}

    public func record(level: DiagnosticLevel, code: String, message: String) {
        let event = DiagnosticEvent(level: level, code: code, message: message)
        lock.lock()
        events.append(event)
        if events.count > limit {
            events.removeFirst(events.count - limit)
        }
        lock.unlock()
    }

    public func info(_ code: String, _ message: String) {
        record(level: .info, code: code, message: message)
    }

    public func warn(_ code: String, _ message: String) {
        record(level: .warn, code: code, message: message)
    }

    public func error(_ code: String, _ message: String) {
        record(level: .error, code: code, message: message)
    }

    public func snapshot() -> [DiagnosticEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }

    public func exportText(redactPaths: Bool = true) -> String {
        snapshot().map { event in
            redactPaths ? Self.redactSensitive(event.line) : event.line
        }.joined(separator: "\n")
    }

    public func clear() {
        lock.lock()
        events.removeAll()
        lock.unlock()
    }

    public static func redactSensitive(_ line: String) -> String {
        var result = line
        // UUID-looking tokens
        if let regex = try? NSRegularExpression(
            pattern: #"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"#
        ) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(
                in: result, options: [], range: range, withTemplate: "********-****-****-****-************"
            )
        }
        // Absolute container paths
        if let regex = try? NSRegularExpression(
            pattern: #"/var/mobile/Containers[^ ]*"#
        ) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(
                in: result, options: [], range: range, withTemplate: "/var/mobile/Containers/[redacted]"
            )
        }
        return result
    }
}

public struct DiagnosticsSnapshot: Sendable, Equatable {
    public var deviceModel: String
    public var iosVersion: String
    public var iosBuild: String
    public var appVersion: String
    public var phoneContainerCache: String
    public var posterBoardContainerCache: String
    public var dialerThemeState: String
    public var posterBoardState: String
    public var lastEvents: [String]

    public var textualReport: String {
        """
        Device model: \(deviceModel)
        iOS version: \(iosVersion)
        iOS build: \(iosBuild)
        App version: \(appVersion)
        Phone container cache: \(phoneContainerCache)
        PosterBoard container cache: \(posterBoardContainerCache)
        Dialer theme: \(dialerThemeState)
        PosterBoard: \(posterBoardState)

        Recent events:
        \(lastEvents.joined(separator: "\n"))
        """
    }
}
