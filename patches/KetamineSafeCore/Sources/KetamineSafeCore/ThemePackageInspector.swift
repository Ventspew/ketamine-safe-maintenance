import Foundation

/// Read-only inspection of dialer/passcode theme packages (.passthm / .zip).
/// Does not write into any other application's container.
public struct ThemePackageInspection: Sendable, Equatable {
    public let imageCount: Int
    public let distinctKeys: [String]
    public let sampleFilenames: [String]
    public let isZip: Bool

    public init(imageCount: Int, distinctKeys: [String], sampleFilenames: [String], isZip: Bool) {
        self.imageCount = imageCount
        self.distinctKeys = distinctKeys
        self.sampleFilenames = sampleFilenames
        self.isZip = isZip
    }

    public var summary: String {
        "\(imageCount) image\(imageCount == 1 ? "" : "s") · \(distinctKeys.count) key\(distinctKeys.count == 1 ? "" : "s") styled"
    }
}

public enum ThemePackageInspectorError: Error, LocalizedError, Equatable {
    case unreadable
    case notZip
    case noPNGs

    public var errorDescription: String? {
        switch self {
        case .unreadable: return "The theme package could not be read."
        case .notZip: return "That file isn't a zip or .passthm package."
        case .noPNGs: return "No PNG images were found in that package."
        }
    }
}

public enum ThemePackageInspector {
    /// Groups a filename by everything after its first hyphen (locale strip).
    public static func matchKey(for filename: String) -> String {
        let lowercased = filename.lowercased()
        guard let dash = lowercased.firstIndex(of: "-") else { return lowercased }
        return String(lowercased[lowercased.index(after: dash)...])
    }

    public static func isZipMagic(_ data: Data) -> Bool {
        data.count >= 2 && data[0] == 0x50 && data[1] == 0x4B
    }

    /// Inspects package bytes without requiring ZIPFoundation (tests/macOS).
    /// Uses a lightweight local-file header walk for PNG entry names only.
    public static func inspect(data: Data) throws -> ThemePackageInspection {
        guard isZipMagic(data) else { throw ThemePackageInspectorError.notZip }
        let names = zipEntryFilenames(in: data)
            .map { ($0 as NSString).lastPathComponent }
            .filter { $0.lowercased().hasSuffix(".png") && !$0.hasPrefix(".") }
        guard !names.isEmpty else { throw ThemePackageInspectorError.noPNGs }

        var keys = Set<String>()
        for name in names { keys.insert(matchKey(for: name)) }
        return ThemePackageInspection(
            imageCount: names.count,
            distinctKeys: keys.sorted(),
            sampleFilenames: Array(names.sorted().prefix(12)),
            isZip: true
        )
    }

    public static func inspect(fileURL: URL) throws -> ThemePackageInspection {
        let accessing = fileURL.startAccessingSecurityScopedResource()
        defer { if accessing { fileURL.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: fileURL) else {
            throw ThemePackageInspectorError.unreadable
        }
        return try inspect(data: data)
    }

    /// Minimal ZIP central/local header filename extractor.
    /// Sufficient for theme packages; not a general-purpose unzipper.
    static func zipEntryFilenames(in data: Data) -> [String] {
        var names: [String] = []
        var offset = 0
        let count = data.count
        while offset + 30 <= count {
            // local file header signature 0x04034b50
            let sig = data.subdata(in: offset..<(offset + 4))
            guard sig[0] == 0x50, sig[1] == 0x4B, sig[2] == 0x03, sig[3] == 0x04 else {
                break
            }
            let nameLen = Int(data[offset + 26]) | (Int(data[offset + 27]) << 8)
            let extraLen = Int(data[offset + 28]) | (Int(data[offset + 29]) << 8)
            let compSize = Int(data[offset + 18])
                | (Int(data[offset + 19]) << 8)
                | (Int(data[offset + 20]) << 16)
                | (Int(data[offset + 21]) << 24)
            let nameStart = offset + 30
            let nameEnd = nameStart + nameLen
            guard nameEnd <= count else { break }
            if let name = String(data: data.subdata(in: nameStart..<nameEnd), encoding: .utf8) {
                names.append(name)
            }
            offset = nameEnd + extraLen + compSize
            // Data descriptor may follow when bit 3 of general purpose flag is set;
            // if sizes were zero, stop to avoid an unbounded scan.
            if compSize == 0 && offset + 30 < count {
                // Try to resync on next local header within a small window.
                if let next = findNextLocalHeader(in: data, from: offset) {
                    offset = next
                } else {
                    break
                }
            }
        }
        return names
    }

    private static func findNextLocalHeader(in data: Data, from start: Int) -> Int? {
        guard start < data.count - 4 else { return nil }
        let limit = min(data.count - 4, start + 4096)
        var i = start
        while i < limit {
            if data[i] == 0x50, data[i + 1] == 0x4B, data[i + 2] == 0x03, data[i + 3] == 0x04 {
                return i
            }
            i += 1
        }
        return nil
    }
}
